const std = @import("std");

pub const Key = union(enum) {
    Char: u8,
    ArrowUp,
    ArrowDown,
    ArrowLeft,
    ArrowRight,
    Enter,
    Escape,
    Backspace,
    Delete,
    Unknown,
};

pub fn parseKey(buf: []const u8) Key {
    if (buf.len == 0) return .Unknown;

    if (buf.len == 1) {
        return switch (buf[0]) {
            '\r', '\n' => .Enter,
            27 => .Escape,
            127 => .Backspace,
            else => .{ .Char = buf[0] },
        };
    }

    if (buf.len >= 3 and buf[0] == 27 and buf[1] == '[') {
        return switch (buf[2]) {
            'A' => .ArrowUp,
            'B' => .ArrowDown,
            'C' => .ArrowRight,
            'D' => .ArrowLeft,
            else => .Unknown,
        };
    }

    if (buf.len >= 4 and buf[0] == 27 and buf[1] == '[' and buf[2] == '3' and buf[3] == '~') {
        return .Delete;
    }

    return .Unknown;
}
