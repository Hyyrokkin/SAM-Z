const std = @import("std");
const mem = std.mem;
const io = std.Io;

const config = @import("config");
const oldSAM = @import("oldSAM");

const reciter = @import("reciter.zig");
const runOld = @import("runOld.zig").runOld;
const sam = @import("sam.zig");

var stdout: *io.Writer = undefined;

var debug: bool = false;

fn std_print(allocator: mem.Allocator, comptime fmt: []const u8, args: anytype) !void {
    const str = try std.fmt.allocPrint(allocator, fmt, args);
    defer allocator.free(str);
    _ = try stdout.write(str);
    try stdout.flush();
}

pub fn main(init: std.process.Init) !void {
    //try runOld(init);

    const arena: mem.Allocator = init.arena.allocator();
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_file_writer: io.File.Writer = .init(.stdout(), init.io, &stdout_buffer);
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
            if (mem.eql(u8, args[i][1..], "wav")) {
                wavfile = args[i + 1];
                outputFile = true;
                i += 1;
            } else if (mem.eql(u8, args[i][1..], "sing")) {
                sam.enableSingmode();
            } else if (mem.eql(u8, args[i][1..], "phonetic")) {
                phonetic = true;
            } else if (mem.eql(u8, args[i][1..], "debug")) {
                debug = true;
            } else if (mem.eql(u8, args[i][1..], "pitch")) {
                sam.setPitch(try std.fmt.parseInt(u8, args[i + 1], 10));
                i += 1;
            } else if (mem.eql(u8, args[i][1..], "speed")) {
                sam.setSpeed(try std.fmt.parseInt(u8, args[i + 1], 10));
                i += 1;
            } else if (mem.eql(u8, args[i][1..], "mouth")) {
                sam.setMouth(try std.fmt.parseInt(u8, args[i + 1], 10));
                i += 1;
            } else if (mem.eql(u8, args[i][1..], "throat")) {
                sam.setThroat(try std.fmt.parseInt(u8, args[i + 1], 10));
                i += 1;
            } else {
                try printUsage();
                return;
            }
        }
        i += 1;
    }

    var input = try std.ascii.allocUpperString(arena, try inputBuilder.toOwnedSlice(arena));

    if (debug) {
        if (phonetic) {
            try std_print(arena, "phonetic input: {s}\n", .{input});
        } else {
            try std_print(arena, "text input: {s}\n", .{input});
        }
    }

    try inputBuilder.appendSlice(arena, input);
    if (!phonetic) {
        try inputBuilder.append(arena, '[');
        inputBuilder = try reciter.TextToPhonemes(inputBuilder);
        if (debug) {
            input = try inputBuilder.toOwnedSlice(arena);
            try std_print(arena, "phonetic input: {s}\n", .{input});
        }
    }

    // if ( SDL_Init(SDL_INIT_AUDIO) < 0 ){
    // printf("Unable to init SDL: %s\n", SDL_GetError());
    // exit(1);
    // }
    // defer SDL_Quit();

    sam.setInput(input);
    if (!sam.SAMMain()) {
        try printUsage();
        return;
    }

    if (outputFile) {
        const buff = sam.getBuffer();
        writeWav(wavfile, buff, buff.len / 50);
    } else {
        outputSound();
    }
}

fn writeWav(filename: []const u8, buffer: []u8, bufferlength: usize) void {
    _ = filename; // autofix
    _ = buffer; // autofix
    _ = bufferlength; // autofix
    // const fmtlength: u32 = 16;
    // const format: u16 = 1; //PCM
    // const channels: u16 = 1;
    // const samplerate: u32 = 22050;
    // const  blockalign: u16 = 1;
    // const bitspersample: u16 = 8;

    // FILE *file;
    // fopen_s(&file, filename, "wb");
    // if (file == NULL) return;
    // //RIFF header
    // fwrite("RIFF", 4, 1,file);
    // const filesize: i32 = filesize=bufferlength + 12 + 16 + 8 - 8;
    // fwrite(&filesize, 4, 1, file);
    // fwrite("WAVE", 4, 1, file);

    // //format chunk
    // fwrite("fmt ", 4, 1, file);
    // fwrite(&fmtlength, 4, 1, file);
    // fwrite(&format, 2, 1, file);
    // fwrite(&channels, 2, 1, file);
    // fwrite(&samplerate, 4, 1, file);
    // fwrite(&samplerate, 4, 1, file); // bytes/second
    // fwrite(&blockalign, 2, 1, file);
    // fwrite(&bitspersample, 2, 1, file);

    // //data chunk
    // fwrite("data", 4, 1, file);
    // fwrite(&bufferlength, 4, 1, file);
    // fwrite(buffer, bufferlength, 1, file);

    // fclose(file);
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
