const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const zig_logfmt = b.dependency("zig_logfmt", .{});
    const zig_logfile = b.dependency("zig_logfile", .{});

    const mod = b.addModule("zig_logger", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    mod.addImport("zig_logfmt", zig_logfmt.module("zig_logfmt"));
    mod.addImport("zig_logfile", zig_logfile.module("zig_logfile"));

    const example = b.addExecutable(.{
        .name = "basic",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/basic.zig"),
            .target = target,
            .imports = &.{
                .{ .name = "zig_logger", .module = mod },
            },
        }),
    });

    const example_step = b.step("example", "Build the basic example");
    example_step.dependOn(&example.step);

    const run_step = b.step("run", "Run the basic example");
    const run_cmd = b.addRunArtifact(example);
    run_step.dependOn(&run_cmd.step);
    run_cmd.addPassthruArgs();

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}
