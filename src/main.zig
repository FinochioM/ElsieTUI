const std = @import("std");
const terminal = @import("terminal.zig");
const buffer_mod = @import("buffer.zig");
const Buffer = buffer_mod.Buffer;
const widget = @import("widget.zig");

const TUI = struct {
    rows: u16,
    cols: u16,
    running: bool,
    frame_count: u32,
    buffer: Buffer,

    fn init(allocator: std.mem.Allocator) !TUI {
        const size = try terminal.getSize();
        return TUI{
            .rows = size.rows,
            .cols = size.cols,
            .running = true,
            .frame_count = 0,
            .buffer = Buffer.init(allocator),
        };
    }

    fn deinit(self: *TUI) void {
        self.buffer.deinit();
    }

    fn render(self: *TUI) !void {
        self.buffer.clear();
        try self.buffer.write("\x1b[2J");

        // main
        try self.buffer.write("\x1b[36m"); // cyan color
        const main_box = widget.Box.init(widget.Rect{ .x = 1, .y = 1, .width = self.cols, .height = self.rows }, "ElsieTUI");
        try main_box.draw(&self.buffer);

        // info
        try self.buffer.write("\x1b[32m");
        const info_box = widget.Box.init(widget.Rect{ .x = 3, .y = 3, .width = 40, .height = 5 }, "Info");
        try info_box.draw(&self.buffer);

        // text
        try self.buffer.write("\x1b[0m");
        const text1 = widget.Text.init(5, 4, "Terminal Size:");
        try text1.draw(&self.buffer);

        try self.buffer.write("\x1b[33m");
        const text2 = widget.Text.init(20, 4, "{}x{}");
        _ = text2;
        try self.buffer.writeFmt("\x1b[20;4H{}x{}", .{ self.rows, self.cols });

        try self.buffer.write("\x1b[0m");
        const text3 = widget.Text.init(5, 5, "Press 'q' to quit");
        try text3.draw(&self.buffer);

        self.buffer.flush();
        self.frame_count += 1;
    }

    fn handleInput(self: *TUI, c: u8) void {
        if (c == 'q') {
            self.running = false;
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

        var buf: [1]u8 = undefined;
        const bytes_read = try stdin.read(&buf);
        if (bytes_read > 0) {
            tui.handleInput(buf[0]);
        }
    }
}
