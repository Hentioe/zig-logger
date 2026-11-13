const std = @import("std");
const logfmt = @import("zig_logfmt");
const logfile = @import("zig_logfile");

pub const FileOptions = struct {
    gpa: std.mem.Allocator,
    logfile: logfile.Options,
    logfmt: logfmt.WriteOptions = .{},
};

pub const TerminalOptions = struct {
    logfmt: logfmt.WriteOptions,
};

terminal: TerminalOptions = .{ .logfmt = .{} },
file: ?FileOptions = null,
