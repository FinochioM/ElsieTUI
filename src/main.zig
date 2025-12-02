const std = @import("std");
const terminal = @import("terminal.zig");
const buffer_mod = @import("buffer.zig");
const Buffer = buffer_mod.Buffer;
const scene_mod = @import("scene.zig");
const Scene = scene_mod.Scene;
const MenuScene = @import("scenes/menu.zig").MenuScene;
const os = std.os;
const linux = os.linux;

const TUI = struct {
    rows: u16,
    cols: u16,
    running: bool,
    buffer: Buffer,
    current_scene: Scene,
    menu_scene: *MenuScene,

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
        try self.current_scene.render(&self.buffer, self.rows, self.cols);
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

        if (should_render) {
            try tui.render();
        }
    }
}
