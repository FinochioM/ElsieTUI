const std = @import("std");

pub const Buffer = struct {
    data: std.ArrayList(u8),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Buffer {
        return Buffer{
            .data = std.ArrayList(u8).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Buffer) void {
        self.data.deinit();
    }

    pub fn clear(self: *Buffer) void {
        self.data.clearRetainingCapacity();
    }

    pub fn write(self: *Buffer, text: []const u8) !void {
        try self.data.appendSlice(text);
    }

    pub fn writeFmt(self: *Buffer, comptime fmt: []const u8, args: anytype) !void {
        try std.fmt.format(self.data.writer(), fmt, args);
    }

    pub fn flush(self: *Buffer) void {
        std.debug.print("{s}", .{self.data.items});
    }
};
