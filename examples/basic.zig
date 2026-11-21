const std = @import("std");
const logger = @import("zig_logger");

pub const std_options: std.Options = .{
    .logFn = logger.logFn,
    .log_level = .debug,
};
pub const log_options: logger.Options = .{ .allowed_scopes = enum { default, logger, logfile } };

pub fn main(init: std.process.Init) !void {
    const runtime_level: std.log.Level = .debug;
    try logger.setup(init.io, .{
        .runtime_level = runtime_level,
        .file = .{
            .gpa = init.gpa,
            .logfile = .{ .log_file_name = "dev.log" },
            .logfmt = .{ .hide_scope = true },
        },
    });
    defer logger.deinit();

    logger.updateTz(8 * 60);

    std.debug.print("runtime level: {t}\n", .{runtime_level});
    std.log.debug("Hello: {d}", .{3});
    std.log.info("Hello: {d}", .{2});
    std.log.warn("Hello: {d}", .{1});
    std.log.err("Hello: {d}", .{0});

    // 故意发出 logfile 的日志
    const logfile_log = std.log.scoped(.logfile);
    logfile_log.info("Hello: {d} (logfile)", .{42}); // 此日志将被忽略写入到文件
}
