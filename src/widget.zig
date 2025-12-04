const std = @import("std");
const style_mod = @import("style.zig");
const Buffer = @import("buffer.zig").Buffer;
const Color = @import("color.zig").Color;

pub const Rect = struct {
    x: u16,
    y: u16,
    width: u16,
    height: u16,
};

pub const Box = struct {
    rect: Rect,
    title: []const u8,
    style: style_mod.BorderStyle,

    pub fn init(rect: Rect, title: []const u8, border_style: style_mod.BorderStyle) Box {
        return Box{
            .rect = rect,
            .title = title,
            .style = border_style,
        };
    }

    pub fn draw(self: Box, buffer: *Buffer) !void {
        const x = self.rect.x;
        const y = self.rect.y;
        const w = self.rect.width;
        const h = self.rect.height;

        try buffer.writeFmt("\x1b[{};{}H", .{ y, x });
        var col: u16 = 0;
        while (col < w) : (col += 1) {
            const color = self.getColorForPosition(col, 0, h, w);
            try color.toFgEscape(buffer);

            if (col == 0) {
                try buffer.write("┌");
            } else if (col == w - 1) {
                try buffer.write("┐");
            } else if (self.title.len > 0 and col >= 1 and col < self.title.len + 3 and col < w - 2) {
                if (col == 1) {
                    try buffer.write(" ");
                } else if (col == self.title.len + 2) {
                    try buffer.write(" ");
                } else {
                    try buffer.writeFmt("{c}", .{self.title[col - 2]});
                }
            } else {
                try buffer.write("─");
            }
        }

        var row: u16 = 1;
        while (row < h - 1) : (row += 1) {
            const left_color = self.getColorForPosition(0, row, h, w);
            try left_color.toFgEscape(buffer);
            try buffer.writeFmt("\x1b[{};{}H│", .{ y + row, x });

            const right_color = self.getColorForPosition(w - 1, row, h, w);
            try right_color.toFgEscape(buffer);
            try buffer.writeFmt("\x1b[{};{}H│", .{ y + row, x + w - 1 });
        }

        const inner_width = w - 2;
        const inner_height = h - 2;
        if (inner_width > 0 and inner_height > 0) {
            row = 0;
            while (row < inner_height) : (row += 1) {
                col = 0;
                while (col < inner_width) : (col += 1) {
                    if (self.getFillColorForPosition(col, row, inner_height, inner_width)) |fill_color| {
                        try fill_color.toBgEscape(buffer);
                        try buffer.writeFmt("\x1b[{};{}H ", .{ y + 1 + row, x + 1 + col });
                    }
                }
            }
            try buffer.write("\x1b[0m");
        }

        try buffer.writeFmt("\x1b[{};{}H", .{ y + h - 1, x });
        col = 0;
        while (col < w) : (col += 1) {
            const color = self.getColorForPosition(col, h - 1, h, w);
            try color.toFgEscape(buffer);

            if (col == 0) {
                try buffer.write("└");
            } else if (col == w - 1) {
                try buffer.write("┘");
            } else {
                try buffer.write("─");
            }
        }
    }

    fn getColorForPosition(self: Box, col: u16, row: u16, total_height: u16, total_width: u16) Color {
        return switch (self.style.color) {
            .Solid => |color| color,
            .VerticalGradient => |grad| {
                const t: f32 = @as(f32, @floatFromInt(row)) / @as(f32, @floatFromInt(total_height - 1));
                return grad.top.lerp(grad.bottom, t);
            },
            .HorizontalGradient => |grad| {
                const t: f32 = @as(f32, @floatFromInt(col)) / @as(f32, @floatFromInt(total_width - 1));
                return grad.left.lerp(grad.right, t);
            },
            .DiagonalGradient => |grad| {
                const t_x: f32 = @as(f32, @floatFromInt(col)) / @as(f32, @floatFromInt(total_width - 1));
                const t_y: f32 = @as(f32, @floatFromInt(row)) / @as(f32, @floatFromInt(total_height - 1));
                const t: f32 = (t_x + t_y) / 2.0;
                return grad.top_left.lerp(grad.bottom_right, t);
            },
        };
    }

    fn getFillColorForPosition(self: Box, col: u16, row: u16, inner_height: u16, inner_width: u16) ?Color {
        return switch (self.style.fill) {
            .None => null,
            .Solid => |color| color,
            .VerticalGradient => |grad| {
                const t: f32 = @as(f32, @floatFromInt(row)) / @as(f32, @floatFromInt(inner_height - 1));
                return grad.top.lerp(grad.bottom, t);
            },
            .HorizontalGradient => |grad| {
                const t: f32 = @as(f32, @floatFromInt(col)) / @as(f32, @floatFromInt(inner_width - 1));
                return grad.left.lerp(grad.right, t);
            },
            .DiagonalGradient => |grad| {
                const t_x: f32 = @as(f32, @floatFromInt(col)) / @as(f32, @floatFromInt(inner_width - 1));
                const t_y: f32 = @as(f32, @floatFromInt(row)) / @as(f32, @floatFromInt(inner_height - 1));
                const t: f32 = (t_x + t_y) / 2.0;
                return grad.top_left.lerp(grad.bottom_right, t);
            },
        };
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
