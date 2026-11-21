const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const Timestamp = Io.Timestamp;
const Level = std.log.Level;
const logfmt = @import("zig_logfmt");
const logfile = @import("zig_logfile");

pub const Options = @import("Options.zig");
pub const SetupOptions = @import("SetupOptions.zig");
pub const WriteOptions = logfmt.WriteOptions;

const log = std.log.scoped(.logger); // 注意：此 log 不用于输出错误（否则可能陷入循环）

var global_io: Io = undefined;
var global_gpa: Allocator = undefined;
var terminal_logfmt_options: logfmt.WriteOptions = .{ // 后备选项，即使初始化失败也能完成格式化
    .hide_time = true,
    .hide_scope = true,
};
var file_enabled: bool = false;
var file_logfmt_options: logfmt.WriteOptions = undefined;
var logfile_bus: logfile.Message.Bus = undefined;
var logfile_sink: logfile.Sink = undefined;
var max_level: u2 = @backingInt(Level.debug);
var initialized: bool = false;

pub fn logFn(
    comptime level: Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    if (@backingInt(level) > max_level or !isAllowedScope(scope)) return;
    var now: ?Timestamp = null;
    if (initialized) now = Timestamp.now(global_io, .real); // 未初始化时，不获取时间
    var formatter = logfmt.format(level, scope, format, args);
    formatter.timestamp = now;

    { // 写入到 stderr，收窄作用域快速释放锁
        var buffer: [64]u8 = undefined;
        const stderr = std.debug.lockStderr(&buffer).terminal();
        defer std.debug.unlockStderr();

        formatter.write(.{ .terminal = stderr }, terminal_logfmt_options) catch return;
    }

    if (file_enabled and // 若未初始化，此选项始终是 false（调用 publish 是安全的）
        scope != logfile.ignored_scope // 跳过 logfile 内部的日志 scope（包含错误日志，避免死循环）
    ) {
        var log_data = logfile.LogData.create(global_gpa) catch return;
        formatter.write(.{ .raw = log_data.writer() }, file_logfmt_options) catch {
            log_data.destroy(global_gpa);
            return;
        };

        const shared_log_data = logfile.LogData.Shared.fromOwned(global_gpa, log_data) catch {
            log_data.destroy(global_gpa);
            return;
        };
        defer shared_log_data.release(global_gpa); // 发送前会增加一次引用，所以此处需要释放一次
        _ = logfile_bus.publish(global_io, .{ .data = shared_log_data }) catch return;
    }
}

fn isAllowedScope(comptime scope: @EnumLiteral()) bool {
    const root = @import("root");

    if (comptime @hasDecl(root, "log_options") and
        root.log_options.allowed_scopes != null)
    {
        return comptime std.meta.stringToEnum(root.log_options.allowed_scopes.?, @tagName(scope)) != null;
    }

    return true;
}

pub fn setup(io: Io, options: SetupOptions) !void {
    std.debug.assert(!initialized);

    global_io = io;
    terminal_logfmt_options = options.terminal.logfmt;
    max_level = @backingInt(options.runtime_level orelse .debug);
    if (options.file) |file_opts| {
        global_gpa = file_opts.gpa;
        logfile_bus = logfile.Message.Bus.init(global_gpa);
        logfile_sink = try logfile.Sink.init(
            global_io,
            global_gpa,
            &logfile_bus,
            file_opts.logfile,
        );
        file_logfmt_options = file_opts.logfmt;
        file_enabled = true;
    }
    initialized = true;
}

pub fn deinit() void {
    if (file_enabled) {
        logfile_sink.deinit();
        logfile_bus.deinit(global_io);
    }
    file_enabled = false;
}

pub fn updateTz(new_offset: i32) void {
    terminal_logfmt_options.timezone_offset = new_offset;
    if (file_enabled) file_logfmt_options.timezone_offset = new_offset;
}

pub fn updateRuntimeLevel(new_level: Level) void {
    max_level = @backingInt(new_level);
}
