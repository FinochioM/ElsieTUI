const std = @import("std");
const os = std.os;
const linux = os.linux;
const Color = @import("color.zig").Color;

var original_termios: linux.termios = undefined;

pub fn setFgColor(color: Color) void {
    std.debug.print("\x1b[{}m", .{@intFromEnum(color)});
}

pub fn setBgColor(color: Color) void {
    std.debug.print("\x1b[{}m", .{@intFromEnum(color) + 10});
}

pub fn resetColor() void {
    std.debug.print("\x1b[0m", .{});
}

pub fn enableRawMode() !void {
    const stdin_fd = std.io.getStdIn().handle;
    _ = linux.tcgetattr(stdin_fd, &original_termios);
    var raw = original_termios;
    raw.lflag &= ~@as(linux.tcflag_t, linux.ECHO | linux.ICANON);
    raw.cc[linux.V.MIN] = 0;
    raw.cc[linux.V.TIME] = 1;
    _ = linux.tcsetattr(stdin_fd, .FLUSH, &raw);
}

pub fn disableRawMode() void {
    const stdin_fd = std.io.getStdIn().handle;
    _ = linux.tcsetattr(stdin_fd, .FLUSH, &original_termios);
}

pub fn clearScreen() void {
    std.debug.print("\x1b[2J", .{});
}

pub fn moveCursor(row: u16, col: u16) void {
    std.debug.print("\x1b[{};{}H", .{ row, col });
}

pub fn hideCursor() void {
    std.debug.print("\x1b[?25l", .{});
}

pub fn showCursor() void {
    std.debug.print("\x1b[?25h", .{});
}

pub fn getSize() !struct { rows: u16, cols: u16 } {
    var winsize: linux.winsize = undefined;
    const stdout_fd = std.io.getStdOut().handle;
    const result = linux.ioctl(stdout_fd, linux.T.IOCGWINSZ, @intFromPtr(&winsize));
    if (result != 0) return error.IoctlFailed;
    return .{
        .rows = winsize.ws_row,
        .cols = winsize.ws_col,
    };
}
