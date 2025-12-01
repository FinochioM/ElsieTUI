const std = @import("std");
const os = std.os;
const linux = os.linux;

var original_termios: linux.termios = undefined;

fn enableRawMode() !void {
    const stdin_fd = std.io.getStdIn().handle;

    _ = linux.tcgetattr(stdin_fd, &original_termios);

    var raw = original_termios;

    raw.lflag &= ~@as(linux.tcflag_t, linux.ECHO | linux.ICANON);

    raw.cc[linux.V.MIN] = 0;
    raw.cc[linux.V.TIME] = 1;

    _ = linux.tcsetattr(stdin_fd, .FLUSH, &raw);
}

fn disableRawMode() void {
    const stdin_fd = std.io.getStdIn().handle;
    _ = linux.tcsetattr(stdin_fd, .FLUSH, &original_termios);
}

fn clearScreen() void {
    std.debug.print("\x1b[2J", .{});
}

fn moveCursor(row: u16, col: u16) void {
    std.debug.print("\x1b[{};{}H", .{ row, col });
}

fn hideCursor() void {
    std.debug.print("\x1b[?25l", .{});
}

fn showCursor() void {
    std.debug.print("\x1b[?25h", .{});
}

pub fn main() !void {
    try enableRawMode();
    defer disableRawMode();
    defer showCursor();

    clearScreen();
    hideCursor();

    moveCursor(1, 1);
    std.debug.print("Press 'q' to quit\r\n", .{});

    moveCursor(10, 5);
    std.debug.print("Position (10, 5)\r\n", .{});

    const stdin = std.io.getStdIn().reader();
    while (true) {
        var buf: [1]u8 = undefined;
        const bytes_read = try stdin.read(&buf);

        if (bytes_read > 0 and buf[0] == 'q') break;
    }
}
