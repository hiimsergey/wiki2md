const Build = @import("std").Build;

// Current latest Zig version: 0.13.0
pub fn build(b: *Build) void {
    // Options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Main executable
    const exe = b.addExecutable(.{
        .name = "wiki2md",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize
    });

    // Installation
    b.installArtifact(exe);

    // Run command
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the program");
    run_step.dependOn(&run_exe.step);
}
