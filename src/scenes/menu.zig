const std = @import("std");
const widget = @import("../widget.zig");
const input = @import("../input.zig");
const style_mod = @import("../style.zig");
const Buffer = @import("../buffer.zig").Buffer;
const Color = @import("../color.zig").Color;

pub const MenuScene = struct {
    allocator: std.mem.Allocator,
    list: widget.List,
    should_quit: bool,

    pub fn init(allocator: std.mem.Allocator) !*MenuScene {
        const self = try allocator.create(MenuScene);

        const items = [_][]const u8{
            "Start Game",
            "Settings",
            "About",
            "Quit",
        };

        self.* = MenuScene{
            .allocator = allocator,
            .list = widget.List.init(widget.Rect{ .x = 10, .y = 7, .width = 30, .height = 4 }, &items),
            .should_quit = false,
        };

        return self;
    }

    pub fn deinit(self: *MenuScene) void {
        self.allocator.destroy(self);
    }

    pub fn render(self: *MenuScene, buffer: *Buffer, rows: u16, cols: u16) !void {
        try buffer.write("\x1b[2J");

        try Color.Red.toFgEscape(buffer);
        const main_box = widget.Box.init(widget.Rect{ .x = 1, .y = 1, .width = cols, .height = rows }, "ElsieTUI - Main Menu", style_mod.BorderStyle.verticalGradient(Color.Red, Color.Blue));
        try main_box.draw(buffer);

        try Color.BrightWhite.toFgEscape(buffer);
        const menu_box = widget.Box.init(
            widget.Rect{ .x = 8, .y = 6, .width = 34, .height = 6 },
            "Menu",
            style_mod.BorderStyle.diagonalGradient(Color.Magenta, Color.Cyan)
        );
        try menu_box.draw(buffer);

        try buffer.write("\x1b[0m");
        try self.list.draw(buffer);

        const y_test: u16 = rows - 3;
        var i: u16 = 10;
        while (i < 50) : (i += 1) {
            const t: f32 = @as(f32, @floatFromInt(i - 10)) / 40.0;
            const gradient_color = Color.Red.lerp(Color.Blue, t);
            try gradient_color.toFgEscape(buffer);
            try buffer.writeFmt("\x1b[{};{}H█", .{ y_test, i });
        }
        try buffer.write("\x1b[0m");

        try buffer.write("\x1b[");
        try buffer.writeFmt("{}", .{rows - 1});
        try buffer.write(";3HArrows: Navigate | Enter: Select | Esc: Quit");
    }

    pub fn handleInput(self: *MenuScene, key: input.Key) !void {
        switch (key) {
            .ArrowUp => self.list.moveUp(),
            .ArrowDown => self.list.moveDown(),
            .Enter => {
                if (self.list.selected == 3) {
                    self.should_quit = true;
                }
            },
            .Escape => self.should_quit = true,
            else => {},
        }
    }

    pub fn shouldQuit(self: *MenuScene) bool {
        return self.should_quit;
    }
};
