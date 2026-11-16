const std = @import("std");
const logger = @import("zig_logger");

pub const std_options: std.Options = .{ .logFn = logger.logFn };

pub fn main(_: std.process.Init) !void {
    std.log.debug("Hello: {d} (not_setup)", .{3});
    std.log.info("Hello: {d} (not_setup)", .{2});
    std.log.warn("Hello: {d} (not_setup)", .{1});
    std.log.err("Hello: {d} (not_setup)", .{0});
}
