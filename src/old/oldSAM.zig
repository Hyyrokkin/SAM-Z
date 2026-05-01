pub const oldSAM = @cImport({
    @cInclude("main.h");
    @cInclude("debug.h");
    @cInclude("reciter.h");
    @cInclude("ReciterTabs.h");
    @cInclude("render.h");
    @cInclude("RenderTabs.h");
    @cInclude("sam.h");
    @cInclude("SamTabs.h");
});
