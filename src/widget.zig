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

        var row: u16 = 1;
        while (row < h - 1) : (row += 1) {
            try buffer.writeFmt("\x1b[{};{}H│", .{ y + row, x });
            try buffer.writeFmt("\x1b[{};{}H│", .{ y + row, x + w - 1 });
        }

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

pub const List = struct {
    rect: Rect,
    items: []const []const u8,
    selected: usize,

    pub fn init(rect: Rect, items: []const []const u8) List {
        return List{
            .rect = rect,
            .items = items,
            .selected = 0,
        };
    }

    pub fn draw(self: List, buffer: *Buffer) !void {
        const x = self.rect.x;
        const y = self.rect.y;

        var i: usize = 0;
        while (i < self.items.len) : (i += 1) {
            if (i >= self.rect.height) break;

            if (i == self.selected) {
                try buffer.write("\x1b[7m");
            }

            try buffer.writeFmt("\x1b[{};{}H {s}", .{ y + i, x, self.items[i] });

            if (i == self.selected) {
                try buffer.write("\x1b[0m");
            }
        }
    }

    pub fn moveUp(self: *List) void {
        if (self.selected > 0) {
            self.selected -= 1;
        }
    }

    pub fn moveDown(self: *List) void {
        if (self.selected < self.items.len - 1) {
            self.selected += 1;
        }
    }
};

pub const TextInput = struct {
    rect: Rect,
    content: std.ArrayList(u8),
    cursor_pos: usize,

    pub fn init(allocator: std.mem.Allocator, rect: Rect) TextInput {
        return TextInput{
            .rect = rect,
            .content = std.ArrayList(u8).init(allocator),
            .cursor_pos = 0,
        };
    }

    pub fn deinit(self: *TextInput) void {
        self.content.deinit();
    }

    pub fn draw(self: TextInput, buffer: *Buffer) !void {
        const x = self.rect.x;
        const y = self.rect.y;

        try buffer.writeFmt("\x1b[{};{}H", .{ y, x });
        if (self.content.items.len > 0) {
            try buffer.writeFmt("{s}", .{self.content.items});
        }

        try buffer.writeFmt("\x1b[{};{}H", .{ y, x + self.cursor_pos });
    }

    pub fn insertChar(self: *TextInput, c: u8) !void {
        try self.content.insert(self.cursor_pos, c);
        self.cursor_pos += 1;
    }

    pub fn deleteChar(self: *TextInput) void {
        if (self.cursor_pos > 0 and self.content.items.len > 0) {
            _ = self.content.orderedRemove(self.cursor_pos - 1);
            self.cursor_pos -= 1;
        }
    }

    pub fn moveCursorLeft(self: *TextInput) void {
        if (self.cursor_pos > 0) {
            self.cursor_pos -= 1;
        }
    }

    pub fn moveCursorRight(self: *TextInput) void {
        if (self.cursor_pos < self.content.items.len) {
            self.cursor_pos += 1;
        }
    }

    pub fn clear(self: *TextInput) void {
        self.content.clearRetainingCapacity();
        self.cursor_pos = 0;
    }
};
