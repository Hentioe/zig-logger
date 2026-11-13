const std = @import("std");
const logger = @import("zig_logger");

pub const std_options: std.Options = .{ .logFn = logger.logFn };

pub fn main(init: std.process.Init) !void {
    try logger.init(init.io, .{
        .file = .{
            .gpa = init.gpa,
            .logfile = .{ .log_file_name = "dev.log" },
        },
    });
    defer logger.deinit();

    logger.updateTz(8 * 60);

    std.log.info("Hello: {d}", .{42});
}
