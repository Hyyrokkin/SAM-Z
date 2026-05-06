const std = @import("std");

const oldSAM = @cImport({
    @cInclude("sam.h");
});

pub fn setInput(_input: [*:0]u8) void {
    // const c_string_input: [*:0]const u8 = _input;
    oldSAM.SetInput(_input);
}
pub fn setSpeed(_speed: u8) void {
    oldSAM.SetSpeed(_speed);
}
pub fn setPitch(_pitch: u8) void {
    oldSAM.SetPitch(_pitch);
}
pub fn setMouth(_mouth: u8) void {
    oldSAM.SetMouth(_mouth);
}
pub fn setThroat(_throat: u8) void {
    oldSAM.SetThroat(_throat);
}
pub fn enableSingmode() void {
    oldSAM.EnableSingmode();
}

pub fn SAMMain() bool {
    return oldSAM.SAMMain() == 1;
}

pub fn getBuffer() []u8 {
    return std.mem.span(oldSAM.GetBuffer());
}
