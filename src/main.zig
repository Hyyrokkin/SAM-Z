const std = @import("std");
const Mem = std.mem;
const Io = std.Io;

const config = @import("config");
const oldSAM = @import("oldSAM");

const reciter = @import("reciter.zig");
const runOld = @import("runOld.zig").runOld;
const sam = @import("sam.zig");

var stdout: *Io.Writer = undefined;

var debug: bool = false;

fn std_print(allocator: Mem.Allocator, comptime fmt: []const u8, args: anytype) !void {
    const str = try std.fmt.allocPrint(allocator, fmt, args);
    defer allocator.free(str);
    _ = try stdout.write(str);
    try stdout.flush();
}

pub fn main(init: std.process.Init) !void {
    //try runOld(init);

    const arena: Mem.Allocator = init.arena.allocator();
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: Io.File.Writer = .init(.stdout(), init.io, &stdout_buffer);
    stdout = &stdout_file_writer.interface;

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    defer arena.free(args);

    if (args.len <= 1) {
        try printUsage();
        return;
    }

    var inputBuilder = try std.ArrayList(u8).initCapacity(arena, config.INPUT_LENGTH);
    defer inputBuilder.deinit(arena);

    var wavfile: []const u8 = undefined;
    var outputFile: bool = false;

    var phonetic: bool = false;

    var i: u32 = 1;
    while (i < args.len) {
        if (args[i][0] != '-') {
            try inputBuilder.appendSlice(arena, args[i]);
            try inputBuilder.appendSlice(arena, " ");
        } else {
            if (Mem.eql(u8, args[i][1..], "wav")) {
                wavfile = args[i + 1];
                outputFile = true;
                i += 1;
            } else if (Mem.eql(u8, args[i][1..], "sing")) {
                sam.enableSingmode();
            } else if (Mem.eql(u8, args[i][1..], "phonetic")) {
                phonetic = true;
            } else if (Mem.eql(u8, args[i][1..], "debug")) {
                debug = true;
            } else if (Mem.eql(u8, args[i][1..], "pitch")) {
                sam.setPitch(try std.fmt.parseInt(u8, args[i + 1], 10));
                i += 1;
            } else if (Mem.eql(u8, args[i][1..], "speed")) {
                sam.setSpeed(try std.fmt.parseInt(u8, args[i + 1], 10));
                i += 1;
            } else if (Mem.eql(u8, args[i][1..], "mouth")) {
                sam.setMouth(try std.fmt.parseInt(u8, args[i + 1], 10));
                i += 1;
            } else if (Mem.eql(u8, args[i][1..], "throat")) {
                sam.setThroat(try std.fmt.parseInt(u8, args[i + 1], 10));
                i += 1;
            } else {
                try printUsage();
                return;
            }
        }
        i += 1;
    }

    const input: []u8 = try inputBuilder.toOwnedSlice(arena);
    var input_upper: []u8 = try std.ascii.allocUpperString(arena, input);
    arena.free(input);

    if (debug) {
        if (phonetic) {
            try std_print(arena, "phonetic input: {s}\n", .{input_upper});
        } else {
            try std_print(arena, "text input: {s}\n", .{input_upper});
        }
    }

    try inputBuilder.appendSlice(arena, input_upper);
    if (!phonetic) {
        try inputBuilder.append(arena, '[');
        arena.free(input_upper);
        input_upper = try std.ascii.allocUpperString(arena, try inputBuilder.toOwnedSlice(arena));
        input_upper = try reciter.TextToPhonemes(input_upper);
        if (debug) {
            try std_print(arena, "phonetic input: {s}\n", .{input_upper});
        }
    }

    // if ( SDL_Init(SDL_INIT_AUDIO) < 0 ){
    // printf("Unable to init SDL: %s\n", SDL_GetError());
    // exit(1);
    // }
    // defer SDL_Quit();

    const c_str: [:0]u8 = try std.mem.concatWithSentinel(arena, u8, &.{input_upper}, 0);
    defer arena.free(c_str);
    sam.setInput(c_str);
    if (!sam.SAMMain()) {
        // try printUsage();
        return;
    }

    if (outputFile) {
        const buff = sam.getBuffer();
        try writeWav(wavfile, buff, buff.len / 50, init.io);
    } else {
        outputSound();
    }
}

fn writeWav(filename: []const u8, buffer: []u8, bufferlength: usize, io_obj: Io) !void {
    var output_file = try Io.Dir.createFile(std.Io.Dir.cwd(), io_obj, filename, .{ .truncate = true });
    defer output_file.close(io_obj);
    var output_buffer: [1024]u8 = undefined;
    var output_writer: Io.File.Writer = output_file.writer(io_obj, &output_buffer);
    var out: *Io.Writer = &output_writer.interface;

    const fmtlength: u32 = 16;
    const wFormatTag: u16 = 0x0001; //PCM
    const channels: u16 = 1;
    const samplerate: u32 = 22050;
    const blockalign: u16 = 1;
    const bitspersample: u16 = 8;

    // //RIFF header
    _ = try out.write("RIFF");
    const filesize: u32 = @intCast(bufferlength + 12 + 16 + 8 - 8);
    _ = try out.writeInt(u32, filesize, .little);
    _ = try out.write("WAVE");

    // //format chunk
    _ = try out.write("fmt ");
    _ = try out.writeByte(0);
    _ = try out.writeInt(u16, fmtlength, .little);
    _ = try out.writeInt(u16, wFormatTag, .little);
    _ = try out.writeInt(u16, channels, .little);
    _ = try out.writeInt(u32, samplerate, .little);
    _ = try out.writeInt(u32, samplerate, .little); // bytes/sec
    _ = try out.writeInt(u16, blockalign, .little);
    _ = try out.writeInt(u16, bitspersample, .little);

    // //data chunk
    _ = try out.write("data");
    _ = try out.writeInt(u32, @intCast(bufferlength), .little);
    _ = try out.write(buffer);
    if (buffer.len % 2 == 1) {
        _ = try out.writeByte(0);
    }

    _ = try out.flush();
}

fn outputSound() void {}

fn printUsage() !void {
    _ = try stdout.write("usage: samz [options] Word1 Word2 ....\n");

    _ = try stdout.write("options\n");
    _ = try stdout.write("  -phonetic           enters phonetic mode. (see below)\n");
    _ = try stdout.write("  -pitch number       set pitch value (default=64)\n");
    _ = try stdout.write("  -speed number       set speed value (default=72)\n");
    _ = try stdout.write("  -throat number      set throat value (default=128)\n");
    _ = try stdout.write("  -mouth number       set mouth value (default=128)\n");
    _ = try stdout.write("  -wav filename       output to wav instead of libsdl\n");
    _ = try stdout.write("  -sing               special treatment of pitch\n");
    _ = try stdout.write("  -debug              print additional debug messages\n");
    _ = try stdout.write("\n");

    _ = try stdout.write("      VOWELS                          VOICED CONSONANTS   \n");
    _ = try stdout.write("IY           f(ee)t                    R        red       \n");
    _ = try stdout.write("IH           p(i)n                     L        allow     \n");
    _ = try stdout.write("EH           beg                       W        away      \n");
    _ = try stdout.write("AE           Sam                       W        whale     \n");
    _ = try stdout.write("AA           pot                       Y        you       \n");
    _ = try stdout.write("AH           b(u)dget                  M        Sam       \n");
    _ = try stdout.write("AO           t(al)k                    N        man       \n");
    _ = try stdout.write("OH           cone                      NX       so(ng)    \n");
    _ = try stdout.write("UH           book                      B        bad       \n");
    _ = try stdout.write("UX           l(oo)t                    D        dog       \n");
    _ = try stdout.write("ER           bird                      G        again     \n");
    _ = try stdout.write("AX           gall(o)n                  J        judge     \n");
    _ = try stdout.write("IX           dig(i)t                   Z        zoo       \n");
    _ = try stdout.write("                                       ZH       plea(s)ure\n");
    _ = try stdout.write("   DIPHTHONGS                          V        seven     \n");
    _ = try stdout.write("EY           m(a)de                    DH       (th)en    \n");
    _ = try stdout.write("AY           h(igh)                                       \n");
    _ = try stdout.write("OY           boy                                          \n");
    _ = try stdout.write("AW           h(ow)                     UNVOICED CONSONANTS\n");
    _ = try stdout.write("OW           slow                      S         Sam      \n");
    _ = try stdout.write("UW           crew                      Sh        fish     \n");
    _ = try stdout.write("                                       F         fish     \n");
    _ = try stdout.write("                                       TH        thin     \n");
    _ = try stdout.write(" SPECIAL PHONEMES                      P         poke     \n");
    _ = try stdout.write("UL           sett(le) (=AXL)           T         talk     \n");
    _ = try stdout.write("UM           astron(omy) (=AXM)        K         cake     \n");
    _ = try stdout.write("UN           functi(on) (=AXN)         CH        speech   \n");
    _ = try stdout.write("Q            kitt-en (glottal stop)    /H        a(h)ead  \n");

    try stdout.flush();
}
