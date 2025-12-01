const std = @import("std");
const terminal = @import("terminal.zig");
const buffer_mod = @import("buffer.zig");
const Buffer = buffer_mod.Buffer;

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

        try self.buffer.write("\x1b[2J\x1b[1;1H");
        try self.buffer.writeFmt("Terminal Size: {} rows, {} cols\r\n", .{ self.rows, self.cols });
        try self.buffer.write("Press 'q' to quit\r\n");

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
