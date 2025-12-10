const std = @import("std");
const Buffer = @import("buffer.zig").Buffer;
const input = @import("input.zig");

pub const Scene = struct {
    const Self = @This();

    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        render: *const fn (ptr: *anyopaque, buffer: *Buffer, rows: u16, cols: u16, time: f32) anyerror!void,
        handleInput: *const fn (ptr: *anyopaque, key: input.Key) anyerror!void,
        deinit: *const fn (ptr: *anyopaque) void,
    };

    pub fn init(pointer: anytype) Scene {
        const Ptr = @TypeOf(pointer);
        const ptr_info = @typeInfo(Ptr);
        _ = ptr_info;

        const gen = struct {
            fn render(ptr: *anyopaque, buffer: *Buffer, rows: u16, cols: u16, time: f32) anyerror!void {
                const self: Ptr = @ptrCast(@alignCast(ptr));
                return self.render(buffer, rows, cols, time);
            }

            fn handleInput(ptr: *anyopaque, key: input.Key) !void {
                const self: Ptr = @ptrCast(@alignCast(ptr));
                return self.handleInput(key);
            }

            fn deinit(ptr: *anyopaque) void {
                const self: Ptr = @ptrCast(@alignCast(ptr));
                return self.deinit();
            }
        };

        return .{
            .ptr = pointer,
            .vtable = &.{
                .render = gen.render,
                .handleInput = gen.handleInput,
                .deinit = gen.deinit,
            },
        };
    }

    pub fn render(self: Scene, buffer: *Buffer, rows: u16, cols: u16, time: f32) !void {
        return self.vtable.render(self.ptr, buffer, rows, cols, time);
    }

    pub fn handleInput(self: Scene, key: input.Key) !void {
        return self.vtable.handleInput(self.ptr, key);
    }

    pub fn deinit(self: Scene) void {
        return self.vtable.deinit(self.ptr);
    }
};
