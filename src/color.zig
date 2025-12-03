const std = @import("std");

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,

    pub fn rgb(r: u8, g: u8, b: u8) Color {
        return Color{ .r = r, .g = g, .b = b };
    }

    pub fn toFgEscape(self: Color, buffer: anytype) !void {
        try buffer.writeFmt("\x1b[38;2;{};{};{}m", .{ self.r, self.g, self.b });
    }

    pub fn toBgEscape(self: Color, buffer: anytype) !void {
        try buffer.writeFmt("\x1b[48;2;{};{};{}m", .{ self.r, self.g, self.b });
    }

    // predefined
    pub const Black = rgb(0, 0, 0);
    pub const Red = rgb(205, 49, 49);
    pub const Green = rgb(13, 188, 121);
    pub const Yellow = rgb(229, 229, 16);
    pub const Blue = rgb(36, 114, 200);
    pub const Magenta = rgb(188, 63, 188);
    pub const Cyan = rgb(17, 168, 205);
    pub const White = rgb(229, 229, 229);

    pub const BrightBlack = rgb(102, 102, 102);
    pub const BrightRed = rgb(241, 76, 76);
    pub const BrightGreen = rgb(35, 209, 139);
    pub const BrightYellow = rgb(245, 245, 67);
    pub const BrightBlue = rgb(59, 142, 234);
    pub const BrightMagenta = rgb(214, 112, 214);
    pub const BrightCyan = rgb(41, 184, 219);
    pub const BrightWhite = rgb(255, 255, 255);
};