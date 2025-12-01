const std = @import("std");
const Buffer = @import("buffer.zig").Buffer;

pub const Rect = struct {
    x: u16,
    y: u16,
    width: u16,
    height: u16,
};

pub const Box = struct {
    rect: Rect,
    title: []const u8,

    pub fn init(rect: Rect, title: []const u8) Box {
        return Box{
            .rect = rect,
            .title = title,
        };
    }

    pub fn draw(self: Box, buffer: *Buffer) !void {
        const x = self.rect.x;
        const y = self.rect.y;
        const w = self.rect.width;
        const h = self.rect.height;

        // top with title
        try buffer.writeFmt("\x1b[{};{}H┌", .{ y, x });
        if (self.title.len > 0 and self.title.len < w - 4) {
            try buffer.writeFmt(" {s} ", .{self.title});
            var i: u16 = @intCast(self.title.len + 2);
            while (i < w - 1) : (i += 1) {
                try buffer.write("─");
            }
        } else {
            var i: u16 = 1;
            while (i < w - 1) : (i += 1) {
                try buffer.write("─");
            }
        }
        try buffer.write("┐");

        // side
        var row: u16 = 1;
        while (row < h - 1) : (row += 1) {
            try buffer.writeFmt("\x1b[{};{}H│", .{ y + row, x });
            try buffer.writeFmt("\x1b[{};{}H│", .{ y + row, x + w - 1 });
        }

        // bottom
        try buffer.writeFmt("\x1b[{};{}H└", .{ y + h - 1, x });
        var i: u16 = 1;
        while (i < w - 1) : (i += 1) {
            try buffer.write("─");
        }
        try buffer.write("┘");
    }
};

pub const Text = struct {
    x: u16,
    y: u16,
    content: []const u8,

    pub fn init(x: u16, y: u16, content: []const u8) Text {
        return Text{
            .x = x,
            .y = y,
            .content = content,
        };
    }

    pub fn draw(self: Text, buffer: *Buffer) !void {
        try buffer.writeFmt("\x1b[{};{}H{s}", .{ self.y, self.x, self.content });
    }
};
