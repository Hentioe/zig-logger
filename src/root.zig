const std = @import("std");
const Io = std.Io;
const logfmt = @import("zig_logfmt");

pub const Options = @import("Options.zig");
pub const WriteOptions = logfmt.WriteOptions;

var global_io: Io = undefined;
var terminal_options: logfmt.WriteOptions = undefined;
var initialized: bool = false;

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    std.debug.assert(initialized);

    const now = std.Io.Timestamp.now(global_io, .real);
    var buffer: [64]u8 = undefined;
    const stderr = std.debug.lockStderr(&buffer).terminal();
    defer std.debug.unlockStderr();

    var formatted = logfmt.format(level, scope, format, args);
    formatted.timestamp = now;

    formatted.write(.{ .terminal = stderr }, terminal_options) catch return;
}

pub fn init(io: Io, options: Options) void {
    std.debug.assert(!initialized);

    global_io = io;
    terminal_options = options.terminal;
    initialized = true;
}

pub fn deinit() void {
    std.debug.assert(initialized);

    initialized = false;
}
