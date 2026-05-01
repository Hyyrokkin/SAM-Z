const std = @import("std");
const Io = std.Io;

const c = @cImport({
    @cInclude("main.h");
});

pub fn runOld(init: std.process.Init) !void {
    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    defer arena.free(args);

    var argv = try arena.alloc([*:0]u8, args.len);
    defer arena.free(argv);
    for (args, 0..) |arg, i| {
        std.log.info("arg: {s}", .{arg});

        var buf = try arena.alloc(u8, arg.len + 1);
        std.mem.copyForwards(u8, buf[0..arg.len], arg);
        buf[arg.len] = 0; // null terminator

        argv[i] = @ptrCast(buf.ptr);
    }

    const argc: c_int = @intCast(args.len);

    _ = c.cMain(argc, @ptrCast(argv.ptr));

    for (argv) |arg| {
        arena.free(arg[0..std.mem.len(arg)]);
    }
}
