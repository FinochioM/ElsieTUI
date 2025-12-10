const std = @import("std");
const terminal = @import("terminal.zig");
const buffer_mod = @import("buffer.zig");
const Buffer = buffer_mod.Buffer;
const scene_mod = @import("scene.zig");
const Scene = scene_mod.Scene;
const MenuScene = @import("scenes/menu.zig").MenuScene;
const os = std.os;
const linux = os.linux;
const time_mod = std.time;

const TUI = struct {
    rows: u16,
    cols: u16,
    running: bool,
    buffer: Buffer,
    current_scene: Scene,
    menu_scene: *MenuScene,
    start_time: i64,

    fn init(allocator: std.mem.Allocator) !TUI {
        const size = try terminal.getSize();

        const menu_scene = try MenuScene.init(allocator);

        return TUI{
            .rows = size.rows,
            .cols = size.cols,
            .running = true,
            .buffer = Buffer.init(allocator),
            .current_scene = Scene.init(menu_scene),
            .menu_scene = menu_scene,
            .start_time = time_mod.milliTimestamp(),
        };
    }

    fn deinit(self: *TUI) void {
        self.buffer.deinit();
        self.current_scene.deinit();
    }

    fn updateSize(self: *TUI) !void {
        const size = try terminal.getSize();
        self.rows = size.rows;
        self.cols = size.cols;
    }

    fn render(self: *TUI) !void {
        self.buffer.clear();
        const current_time = time_mod.milliTimestamp();
        const elapsed_seconds: f32 = @floatFromInt(current_time - self.start_time);
        const time: f32 = elapsed_seconds / 1000.0;
        try self.current_scene.render(&self.buffer, self.rows, self.cols, time);
        self.buffer.flush();
    }

    fn handleInput(self: *TUI, key: anytype) !void {
        try self.current_scene.handleInput(key);

        if (self.menu_scene.shouldQuit()) {
            self.running = false;
        }
    }
};

var resize_flag: bool = false;

fn handleSigWinch(_: c_int) callconv(.C) void {
    resize_flag = true;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var sa = linux.Sigaction{
        .handler = .{ .handler = handleSigWinch },
        .mask = linux.empty_sigset,
        .flags = 0,
    };
    _ = linux.sigaction(linux.SIG.WINCH, &sa, null);

    try terminal.enableRawMode();
    defer terminal.disableRawMode();
    defer terminal.showCursor();

    terminal.hideCursor();
    std.debug.print("\x1b[2J", .{});

    var tui = try TUI.init(allocator);
    defer tui.deinit();

    const stdin = std.io.getStdIn().reader();

    try tui.render();

    while (tui.running) {
        var should_render = false;

        if (resize_flag) {
            try tui.updateSize();
            resize_flag = false;
            should_render = true;
        }

        var buf: [6]u8 = undefined;
        const bytes_read = try stdin.read(&buf);
        if (bytes_read > 0) {
            const key = @import("input.zig").parseKey(buf[0..bytes_read]);
            try tui.handleInput(key);
            should_render = true;
        }

        should_render = true;

        if (should_render) {
            try tui.render();
        }

        std.time.sleep(16_000_000);
    }
}
