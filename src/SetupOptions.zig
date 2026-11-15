const std = @import("std");
const logfmt = @import("zig_logfmt");
const logfile = @import("zig_logfile");
const Level = std.log.Level;

pub const FileOptions = struct {
    gpa: std.mem.Allocator,
    logfile: logfile.Options,
    logfmt: logfmt.WriteOptions = .{},
};

pub const TerminalOptions = struct {
    logfmt: logfmt.WriteOptions,
};

runtime_level: ?Level = null,
terminal: TerminalOptions = .{ .logfmt = .{} },
file: ?FileOptions = null,
