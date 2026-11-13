const std = @import("std");
const Io = std.Io;
const Allocator = std.mem.Allocator;
const logfmt = @import("zig_logfmt");
const logfile = @import("zig_logfile");

pub const Options = @import("Options.zig");
pub const SetupOptions = @import("SetupOptions.zig");
pub const WriteOptions = logfmt.WriteOptions;

var global_io: Io = undefined;
var global_gpa: Allocator = undefined;
var terminal_logfmt_options: logfmt.WriteOptions = undefined;
var file_enabled: bool = false;
var file_logfile_options: logfile.Options = undefined;
var file_logfmt_options: logfmt.WriteOptions = undefined;
var initialized: bool = false;

fn isAllowedScope(comptime scope: @EnumLiteral()) bool {
    const root = @import("root");

    if (comptime @hasDecl(root, "log_options") and root.log_options.allowed_scopes != null) {
        return comptime std.meta.stringToEnum(root.log_options.allowed_scopes.?, @tagName(scope)) != null;
    }

    return true;
}

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    std.debug.assert(initialized);

    if (!isAllowedScope(scope)) return;
    const now = std.Io.Timestamp.now(global_io, .real);
    var formatted = logfmt.format(level, scope, format, args);
    formatted.timestamp = now;

    { // 写入到 stderr，收窄作用域快速释放锁
        var buffer: [64]u8 = undefined;
        const stderr = std.debug.lockStderr(&buffer).terminal();
        defer std.debug.unlockStderr();

        formatted.write(.{ .terminal = stderr }, terminal_logfmt_options) catch return;
    }

    if (file_enabled) {
        var allocating: std.Io.Writer.Allocating = .init(global_gpa);
        formatted.write(.{ .raw = &allocating.writer }, file_logfmt_options) catch {};
        logfile.push(allocating);
    }
}

pub fn setup(io: Io, options: SetupOptions) !void {
    std.debug.assert(!initialized);

    global_io = io;
    terminal_logfmt_options = options.terminal.logfmt;
    if (options.file) |file_opts| {
        global_gpa = file_opts.gpa;
        try logfile.init(global_io, global_gpa, file_opts.logfile);
        file_logfile_options = file_opts.logfile;
        file_logfmt_options = file_opts.logfmt;
        file_enabled = true;
    }
    initialized = true;
}

pub fn deinit() void {
    std.debug.assert(initialized);

    if (file_enabled) logfile.deinit();
    initialized = false;
}

pub fn updateTz(new_offset: i32) void {
    terminal_logfmt_options.timezone_offset = new_offset;
    if (file_enabled) file_logfmt_options.timezone_offset = new_offset;
}
