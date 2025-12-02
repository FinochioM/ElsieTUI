const std = @import("std");
const terminal = @import("terminal.zig");
const buffer_mod = @import("buffer.zig");
const Buffer = buffer_mod.Buffer;
const widget = @import("widget.zig");
const input = @import("input.zig");
const os = std.os;
const linux = os.linux;

const TUI = struct {
    rows: u16,
    cols: u16,
    running: bool,
    buffer: Buffer,
    text_input: widget.TextInput,

    fn init(allocator: std.mem.Allocator) !TUI {
        const size = try terminal.getSize();

        return TUI{
            .rows = size.rows,
            .cols = size.cols,
            .running = true,
            .buffer = Buffer.init(allocator),
            .text_input = widget.TextInput.init(allocator, widget.Rect{ .x = 5, .y = 5, .width = 40, .height = 1 }),
        };
    }

    fn deinit(self: *TUI) void {
        self.buffer.deinit();
        self.text_input.deinit();
    }

    fn updateSize(self: *TUI) !void {
        const size = try terminal.getSize();
        self.rows = size.rows;
        self.cols = size.cols;
    }

    fn render(self: *TUI) !void {
        self.buffer.clear();
        try self.buffer.write("\x1b[2J");

        try self.buffer.write("\x1b[36m");
        const main_box = widget.Box.init(widget.Rect{ .x = 1, .y = 1, .width = self.cols, .height = self.rows }, "ElsieTUI - Text Input Demo");
        try main_box.draw(&self.buffer);

        try self.buffer.write("\x1b[32m");
        const input_box = widget.Box.init(widget.Rect{ .x = 3, .y = 3, .width = 50, .height = 4 }, "Enter Text");
        try input_box.draw(&self.buffer);

        try self.buffer.write("\x1b[0m");
        try self.text_input.draw(&self.buffer);

        try self.buffer.writeFmt("\x1b[{};{}H", .{ 5, 5 + self.text_input.cursor_pos });
        try self.buffer.write("\x1b[?25h");

        try self.buffer.write("\x1b[8;3HType to enter text, Backspace to delete, 'Esc' to quit");
        try self.buffer.writeFmt("\x1b[9;3HTerminal: {}x{}", .{ self.rows, self.cols });

        self.buffer.flush();
    }

    fn handleInput(self: *TUI, key: input.Key) !void {
        switch (key) {
            .Char => |c| {
                try self.text_input.insertChar(c);
            },
            .Backspace => self.text_input.deleteChar(),
            .ArrowLeft => self.text_input.moveCursorLeft(),
            .ArrowRight => self.text_input.moveCursorRight(),
            .Escape => self.running = false,
            else => {},
        }
    }
};

var resize_flag: bool = false;

fn handleSigWinch(_: c_int) callconv(.C) void {
    resize_flag = true;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var sa = linux.Sigaction{
        .handler = .{ .handler = handleSigWinch },
        .mask = linux.empty_sigset,
        .flags = 0,
    };
    _ = linux.sigaction(linux.SIG.WINCH, &sa, null);

    try terminal.enableRawMode();
    defer terminal.disableRawMode();
    defer terminal.showCursor();

    terminal.hideCursor();

    var tui = try TUI.init(allocator);
    defer tui.deinit();

    const stdin = std.io.getStdIn().reader();

    while (tui.running) {
        if (resize_flag) {
            try tui.updateSize();
            resize_flag = false;
        }

        try tui.render();

        var buf: [6]u8 = undefined;
        const bytes_read = try stdin.read(&buf);
        if (bytes_read > 0) {
            const key = input.parseKey(buf[0..bytes_read]);
            try tui.handleInput(key);
        }
    }
}
