const Color = @import("color.zig").Color;

pub const BorderStyle = struct {
    color: ColorStyle,

    pub const ColorStyle = union(enum) {
        Solid: Color,
        VerticalGradient: struct {
            top: Color,
            bottom: Color,
        },
        HorizontalGradient: struct {
            left: Color,
            right: Color,
        },
    };

    pub fn solid(color: Color) BorderStyle {
        return BorderStyle{ .color = .{ .Solid = color } };
    }


    pub fn verticalGradient(top: Color, bottom: Color) BorderStyle {
        return BorderStyle{ .color = .{ .VerticalGradient = .{ .top = top, .bottom = bottom } } };
    }

    pub fn horizontalGradient(left: Color, right: Color) BorderStyle {
        return BorderStyle{ .color = .{ .HorizontalGradient = .{ .left = left, .right = right } } };
    }
};