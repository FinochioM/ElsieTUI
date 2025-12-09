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

fn calculateGradientColor(gradient: anytype, col: u16, row: u16, total_height: u16, total_width: u16) Color {
    return switch (gradient) {
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
        .RadialGradient => |grad| {
            const center_x: f32 = @as(f32, @floatFromInt(total_width)) / 2.0;
            const center_y: f32 = @as(f32, @floatFromInt(total_height)) / 2.0;
            const dx = @as(f32, @floatFromInt(col)) - center_x;
            const dy = @as(f32, @floatFromInt(row)) - center_y;
            const max_dist = @sqrt(center_x * center_x + center_y * center_y);
            const dist = @sqrt(dx * dx + dy * dy);
            const t: f32 = @min(1.0, dist / max_dist);
            return grad.center.lerp(grad.edge, t);
        },
    };
}

pub const Box = struct {
    rect: Rect,
    title: []const u8,
    style: style_mod.Style,

    pub fn init(rect: Rect, title: []const u8, style: style_mod.Style) Box {
        return Box{
            .rect = rect,
            .title = title,
            .style = style,
        };
    }

    pub fn draw(self: Box, buffer: *Buffer) !void {
        const x = self.rect.x;
        const y = self.rect.y;
        const w = self.rect.width;
        const h = self.rect.height;

        if (self.style.border) |border| {
            try buffer.writeFmt("\x1b[{};{}H", .{ y, x });
            var col: u16 = 0;
            while (col < w) : (col += 1) {
                const color = calculateGradientColor(border, col, 0, h, w);
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
                const left_color = calculateGradientColor(border, 0, row, h, w);
                try left_color.toFgEscape(buffer);
                try buffer.writeFmt("\x1b[{};{}H│", .{ y + row, x });

                const right_color = calculateGradientColor(border, w - 1, row, h, w);
                try right_color.toFgEscape(buffer);
                try buffer.writeFmt("\x1b[{};{}H│", .{ y + row, x + w - 1 });
            }

            try buffer.writeFmt("\x1b[{};{}H", .{ y + h - 1, x });
            col = 0;
            while (col < w) : (col += 1) {
                const color = calculateGradientColor(border, col, h - 1, h, w);
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

        if (self.style.fill) |fill| {
            const inner_width = w - 2;
            const inner_height = h - 2;
            if (inner_width > 0 and inner_height > 0) {
                var row: u16 = 0;
                while (row < inner_height) : (row += 1) {
                    var col: u16 = 0;
                    while (col < inner_width) : (col += 1) {
                        const fill_color = calculateGradientColor(fill, col, row, inner_height, inner_width);
                        try fill_color.toBgEscape(buffer);
                        try buffer.writeFmt("\x1b[{};{}H ", .{ y + 1 + row, x + 1 + col });
                    }
                }
                try buffer.write("\x1b[0m");
            }
        }
    }
};

pub const Text = struct {
    x: u16,
    y: u16,
    content: []const u8,
    style: style_mod.Style,

    pub fn init(x: u16, y: u16, content: []const u8, style: style_mod.Style) Text {
        return Text{
            .x = x,
            .y = y,
            .content = content,
            .style = style,
        };
    }

    pub fn draw(self: Text, buffer: *Buffer) !void {
        if (self.style.text_gradient) |gradient| {
            var i: usize = 0;
            while (i < self.content.len) : (i += 1) {
                const color = switch (gradient) {
                    .Solid => |c| c,
                    .Horizontal => |grad| blk: {
                        const t: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(self.content.len - 1));
                        break :blk grad.left.lerp(grad.right, t);
                    },
                    .Vertical => |grad| grad.top.lerp(grad.bottom, 0.5),
                    .Diagonal => |grad| blk: {
                        const t: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(self.content.len - 1));
                        break :blk grad.top_left.lerp(grad.bottom_right, t);
                    },
                    .Radial => |grad| blk: {
                        const center: f32 = @as(f32, @floatFromInt(self.content.len)) / 2.0;
                        const dist = @fabs(@as(f32, @floatFromInt(i)) - center);
                        const max_dist = center;
                        const t: f32 = @min(1.0, dist / max_dist);
                        break :blk grad.center.lerp(grad.edge, t);
                    },
                };
                try color.toFgEscape(buffer);
                try buffer.writeFmt("\x1b[{};{}H{c}", .{ self.y, self.x + i, self.content[i] });
            }
            try buffer.write("\x1b[0m");
        } else {
            try buffer.writeFmt("\x1b[{};{}H{s}", .{ self.y, self.x, self.content });
        }
    }
};

pub const List = struct {
    rect: Rect,
    items: []const []const u8,
    selected: usize,
    style: style_mod.Style,
    parent_rect: ?Rect,

    pub fn init(rect: Rect, items: []const []const u8, style: style_mod.Style) List {
        return List{
            .rect = rect,
            .items = items,
            .selected = 0,
            .style = style,
            .parent_rect = null,
        };
    }

    pub fn withParent(self: List, parent: Rect) List {
        var result = self;
        result.parent_rect = parent;
        return result;
    }

    pub fn draw(self: List, buffer: *Buffer) !void {
        const x = self.rect.x;
        const y = self.rect.y;

        var i: usize = 0;
        while (i < self.items.len) : (i += 1) {
            if (i >= self.rect.height) break;

            if (self.style.fill) |fill| {
                if (self.parent_rect) |parent| {
                    const row_in_parent = (y + i) - (parent.y + 1);
                    const inner_height = parent.height - 2;
                    const inner_width = parent.width - 2;

                    var col: u16 = 0;
                    const item_text = self.items[i];

                    while (col <= item_text.len) : (col += 1) {
                        const col_in_parent = (x - (parent.x + 1)) + col;
                        const bg_color = calculateGradientColor(fill, col_in_parent, @intCast(row_in_parent), inner_height, inner_width);
                        try bg_color.toBgEscape(buffer);

                        if (self.style.text_gradient) |text_gradient| {
                            const text_color = switch (text_gradient) {
                                .Solid => |c| c,
                                .Horizontal => |grad| blk: {
                                    if (item_text.len > 1) {
                                        const t: f32 = @as(f32, @floatFromInt(col - 1)) / @as(f32, @floatFromInt(item_text.len - 1));
                                        break :blk grad.left.lerp(grad.right, t);
                                    } else {
                                        break :blk grad.left;
                                    }
                                },
                                .Vertical => |grad| blk: {
                                    const t: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(self.items.len - 1));
                                    break :blk grad.top.lerp(grad.bottom, t);
                                },
                                .Diagonal => |grad| blk: {
                                    const t_x: f32 = if (item_text.len > 1)
                                        @as(f32, @floatFromInt(col - 1)) / @as(f32, @floatFromInt(item_text.len - 1))
                                    else
                                        0.0;
                                    const t_y: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(self.items.len - 1));
                                    const t: f32 = (t_x + t_y) / 2.0;
                                    break :blk grad.top_left.lerp(grad.bottom_right, t);
                                },
                                .Radial => |grad| blk: {
                                    const center: f32 = @as(f32, @floatFromInt(item_text.len)) / 2.0;
                                    const dist = @fabs(@as(f32, @floatFromInt(col - 1)) - center);
                                    const t: f32 = @min(1.0, dist / center);
                                    break :blk grad.center.lerp(grad.edge, t);
                                },
                            };
                            try text_color.toFgEscape(buffer);
                        }

                        if (i == self.selected) {
                            try buffer.write("\x1b[7m");
                        }

                        try buffer.writeFmt("\x1b[{};{}H", .{ y + i, x + col });

                        if (col == 0) {
                            try buffer.write(" ");
                        } else if (col <= item_text.len) {
                            try buffer.writeFmt("{c}", .{item_text[col - 1]});
                        }

                        if (i == self.selected) {
                            try buffer.write("\x1b[27m");
                        }
                    }
                }
            } else {
                if (self.style.text_gradient) |text_gradient| {
                    const item_text = self.items[i];
                    var col: u16 = 0;

                    if (i == self.selected) {
                        try buffer.write("\x1b[7m");
                    }

                    try buffer.writeFmt("\x1b[{};{}H ", .{ y + i, x });

                    while (col < item_text.len) : (col += 1) {
                        const text_color = switch (text_gradient) {
                            .Solid => |c| c,
                            .Horizontal => |grad| blk: {
                                const t: f32 = @as(f32, @floatFromInt(col)) / @as(f32, @floatFromInt(item_text.len - 1));
                                break :blk grad.left.lerp(grad.right, t);
                            },
                            .Vertical => |grad| blk: {
                                const t: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(self.items.len - 1));
                                break :blk grad.top.lerp(grad.bottom, t);
                            },
                            .Diagonal => |grad| blk: {
                                const t_x: f32 = @as(f32, @floatFromInt(col)) / @as(f32, @floatFromInt(item_text.len - 1));
                                const t_y: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(self.items.len - 1));
                                const t: f32 = (t_x + t_y) / 2.0;
                                break :blk grad.top_left.lerp(grad.bottom_right, t);
                            },
                            .Radial => |grad| blk: {
                                const center: f32 = @as(f32, @floatFromInt(item_text.len)) / 2.0;
                                const dist = @fabs(@as(f32, @floatFromInt(col)) - center);
                                const t: f32 = @min(1.0, dist / center);
                                break :blk grad.center.lerp(grad.edge, t);
                            },
                        };
                        try text_color.toFgEscape(buffer);
                        try buffer.writeFmt("{c}", .{item_text[col]});
                    }

                    if (i == self.selected) {
                        try buffer.write("\x1b[27m");
                    }
                } else {
                    if (i == self.selected) {
                        try buffer.write("\x1b[7m");
                    }

                    try buffer.writeFmt("\x1b[{};{}H {s}", .{ y + i, x, self.items[i] });

                    if (i == self.selected) {
                        try buffer.write("\x1b[27m");
                    }
                }
            }
        }

        if (self.style.fill != null or self.style.text_gradient != null) {
            try buffer.write("\x1b[0m");
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
    style: style_mod.Style,

    pub fn init(allocator: std.mem.Allocator, rect: Rect, style: style_mod.Style) TextInput {
        return TextInput{
            .rect = rect,
            .content = std.ArrayList(u8).init(allocator),
            .cursor_pos = 0,
            .style = style,
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
            if (self.style.text_gradient) |gradient| {
                var i: usize = 0;
                while (i < self.content.items.len) : (i += 1) {
                    const color = switch (gradient) {
                        .Solid => |c| c,
                        .Horizontal => |grad| blk: {
                            const t: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(self.content.items.len - 1));
                            break :blk grad.left.lerp(grad.right, t);
                        },
                        .Vertical => |grad| grad.top.lerp(grad.bottom, 0.5),
                        .Diagonal => |grad| blk: {
                            const t: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(self.content.items.len - 1));
                            break :blk grad.top_left.lerp(grad.bottom_right, t);
                        },
                        .Radial => |grad| blk: {
                            const center: f32 = @as(f32, @floatFromInt(self.content.items.len)) / 2.0;
                            const dist = @fabs(@as(f32, @floatFromInt(i)) - center);
                            const t: f32 = @min(1.0, dist / center);
                            break :blk grad.center.lerp(grad.edge, t);
                        },
                    };
                    try color.toFgEscape(buffer);
                    try buffer.writeFmt("{c}", .{self.content.items[i]});
                }
            } else {
                try buffer.writeFmt("{s}", .{self.content.items});
            }
        }

        try buffer.writeFmt("\x1b[{};{}H", .{ y, x + self.cursor_pos });

        if (self.style.text_gradient != null) {
            try buffer.write("\x1b[0m");
        }
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
