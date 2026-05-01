const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const oldSAM = b.addModule("oldSAM", .{
        .root_source_file = b.path("src/old/oldSAM.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    oldSAM.addIncludePath(.{ .cwd_relative = "/usr/include/SDL2/" });
    oldSAM.addCSourceFiles(.{
        .files = &[_][]const u8{
            "src/old/createtransitions.c",
            "src/old/debug.c",
            "src/old/processframes.c",
            "src/old/reciter.c",
            "src/old/render.c",
            "src/old/sam.c",
        },
        .flags = &[_][]const u8{
            "-Wall",
            "-O2",
            //"-DUSESDL",
        },
    });
    oldSAM.addIncludePath(b.path("src/old"));

    const exe = b.addExecutable(.{
        .name = "SAM_Z",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{
                .{ .name = "oldSAM", .module = oldSAM },
            },
        }),
    });

    exe.root_module.addCSourceFile(.{
        .file = b.path("src/old/main.c"),
        .flags = &[_][]const u8{
            "-Wall",
            "-O2",
            //"-DUSESDL",
        },
    });
    exe.root_module.addIncludePath(b.path("src/old"));

    exe.root_module.linkSystemLibrary("SDL2", .{
        .needed = true,
        .use_pkg_config = .force,
        .preferred_link_mode = .dynamic,
    });

    exe.root_module.linkSystemLibrary("pthread", .{});

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
