const std = @import("std");
const terminal = @import("terminal.zig");
const buffer_mod = @import("buffer.zig");
const Buffer = buffer_mod.Buffer;
const widget = @import("widget.zig");
const input = @import("input.zig");

const TUI = struct {
    rows: u16,
    cols: u16,
    running: bool,
    buffer: Buffer,
    list: widget.List,

    fn init(allocator: std.mem.Allocator) !TUI {
        const size = try terminal.getSize();

        const items = [_][]const u8{
            "Option 1",
            "Option 2",
            "Option 3",
            "Option 4",
            "Option 5",
        };

        return TUI{
            .rows = size.rows,
            .cols = size.cols,
            .running = true,
            .buffer = Buffer.init(allocator),
            .list = widget.List.init(widget.Rect{ .x = 5, .y = 4, .width = 30, .height = 5 }, &items),
        };
    }

    fn deinit(self: *TUI) void {
        self.buffer.deinit();
    }

    fn render(self: *TUI) !void {
        self.buffer.clear();
        try self.buffer.write("\x1b[2J");

        try self.buffer.write("\x1b[36m");
        const main_box = widget.Box.init(widget.Rect{ .x = 1, .y = 1, .width = self.cols, .height = self.rows }, "ElsieTUI - List Demo");
        try main_box.draw(&self.buffer);

        try self.buffer.write("\x1b[32m");
        const list_box = widget.Box.init(widget.Rect{ .x = 3, .y = 3, .width = 34, .height = 7 }, "Menu");
        try list_box.draw(&self.buffer);

        try self.buffer.write("\x1b[0m");
        try self.list.draw(&self.buffer);

        try self.buffer.write("\x1b[11;3HUse arrows to navigate, 'q' to quit");

        self.buffer.flush();
    }

    fn handleInput(self: *TUI, key: input.Key) void {
        switch (key) {
            .Char => |c| {
                if (c == 'q') {
                    self.running = false;
                }
            },
            .ArrowUp => self.list.moveUp(),
            .ArrowDown => self.list.moveDown(),
            else => {},
        }
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try terminal.enableRawMode();
    defer terminal.disableRawMode();
    defer terminal.showCursor();

    terminal.hideCursor();

    var tui = try TUI.init(allocator);
    defer tui.deinit();

    const stdin = std.io.getStdIn().reader();

    while (tui.running) {
        try tui.render();

        var buf: [6]u8 = undefined;
        const bytes_read = try stdin.read(&buf);
        if (bytes_read > 0) {
            const key = input.parseKey(buf[0..bytes_read]);
            tui.handleInput(key);
        }
    }
}
