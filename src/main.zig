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

        const main_box = widget.Box.init(widget.Rect{ .x = 1, .y = 1, .width = self.cols, .height = self.rows }, "ElsieTUI");
        try main_box.draw(&self.buffer);

        const info_box = widget.Box.init(widget.Rect{ .x = 3, .y = 3, .width = 40, .height = 5 }, "Info");
        try info_box.draw(&self.buffer);

        try self.buffer.writeFmt("\x1b[4;5HTerminal: {}x{}", .{ self.rows, self.cols });
        try self.buffer.write("\x1b[5;5HPress 'q' to quit");

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
