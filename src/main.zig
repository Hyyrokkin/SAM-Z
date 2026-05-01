const std = @import("std");
const Io = std.Io;

const oldSAM = @import("oldSAM");

const runOld = @import("runOld.zig").runOld;

pub fn main(init: std.process.Init) !void {
    try runOld(init);

    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    defer arena.free(args);

    // var phonetic: i32 = 0;

    // var wavfilename: []u8 = undefined;
    // var input: [256]u8 = .{};

    // if (args.len <= 1)
    // {
    // PrintUsage();
    // return;
    // }

    // var i: i32 = 0;
    // while(i < args.len){
    // if (argv[i][0] != '-')
    // {
    // strcat_s((char*)input, 256, argv[i]);
    // strcat_s((char*)input, 256, " ");
    // } else
    // {
    // if (strcmp(&argv[i][1], "wav")==0)
    // {
    // wavfilename = argv[i+1];
    // i++;
    // } else
    // if (strcmp(&argv[i][1], "sing")==0)
    // {
    // EnableSingmode();
    // } else
    // if (strcmp(&argv[i][1], "phonetic")==0)
    // {
    // phonetic = 1;
    // } else
    // if (strcmp(&argv[i][1], "debug")==0)
    // {
    // debug = 1;
    // } else
    // if (strcmp(&argv[i][1], "pitch")==0)
    // {
    // SetPitch((unsigned char)min(atoi(argv[i+1]),255));
    // i++;
    // } else
    // if (strcmp(&argv[i][1], "speed")==0)
    // {
    // SetSpeed((unsigned char)min(atoi(argv[i+1]),255));
    // i++;
    // } else
    // if (strcmp(&argv[i][1], "mouth")==0)
    // {
    // SetMouth((unsigned char)min(atoi(argv[i+1]),255));
    // i++;
    // } else
    // if (strcmp(&argv[i][1], "throat")==0)
    // {
    // SetThroat((unsigned char)min(atoi(argv[i+1]),255));
    // i++;
    // } else
    // {
    // PrintUsage();
    // return 1;
    // }
    // }

    // i += 1;
    // }

    // for (input, 0..) |char, i| {
    // input[i] = std.ascii.toUpper(char);
    // }

    // if (debug){
    // if (phonetic) {
    // printf("phonetic input: %s\n", input);
    // } else {
    // printf("text input: %s\n", input);
    // }
    // }

    // if (!phonetic){
    // strcat_s((char*)input, 256, "[");
    // input.

    // if(!TextToPhonemes(input)){
    // return;
    // }
    // if (debug){
    // printf("phonetic input: %s\n", input);
    // }
    // } else {
    // strcat_s((char*)input, 256, "\x9b");
    // }

    // if ( SDL_Init(SDL_INIT_AUDIO) < 0 ){
    // printf("Unable to init SDL: %s\n", SDL_GetError());
    // exit(1);
    // }
    // defer SDL_Quit();

    // SetInput(input);
    // if (!SAMMain()){
    // PrintUsage();
    // return;
    // }

    // if (wavfilename != NULL){
    // WriteWav(wavfilename, GetBuffer(), GetBufferLength()/50);
    // OutputSound();
    // } else {
    // OutputSound();
    // }
}
