const std = @import("std");
const terminal = @import("terminal.zig");

const TUI = struct {
    rows: u16,
    cols: u16,
    running: bool,
    frame_count: u32,

    fn init() !TUI {
        const size = try terminal.getSize();
        return TUI{
            .rows = size.rows,
            .cols = size.cols,
            .running = true,
            .frame_count = 0,
        };
    }

    fn render(self: *TUI) void {
        terminal.clearScreen();
        terminal.moveCursor(1, 1);
        std.debug.print("Terminal Size: {} rows, {} cols\r\n", .{ self.rows, self.cols });
        std.debug.print("Press 'q' to quit\r\n", .{});
        self.frame_count += 1;
    }

    fn handleInput(self: *TUI, c: u8) void {
        if (c == 'q') {
            self.running = false;
        }
    }
};

pub fn main() !void {
    try terminal.enableRawMode();
    defer terminal.disableRawMode();
    defer terminal.showCursor();

    terminal.hideCursor();

    var tui = try TUI.init();
    const stdin = std.io.getStdIn().reader();

    while (tui.running) {
        tui.render();

        var buf: [1]u8 = undefined;
        const bytes_read = try stdin.read(&buf);
        if (bytes_read > 0) {
            tui.handleInput(buf[0]);
        }
    }
}
