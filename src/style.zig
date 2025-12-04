const Color = @import("color.zig").Color;

pub const BorderStyle = struct {
    color: ColorStyle,
    fill: FillStyle,

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

    pub const FillStyle = union(enum) {
        None,
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
        return BorderStyle{
            .color = .{ .Solid = color },
            .fill = .None,
        };
    }

    pub fn verticalGradient(top: Color, bottom: Color) BorderStyle {
        return BorderStyle{
            .color = .{ .VerticalGradient = .{ .top = top, .bottom = bottom } },
            .fill = .None,
        };
    }

    pub fn horizontalGradient(left: Color, right: Color) BorderStyle {
        return BorderStyle{
            .color = .{ .HorizontalGradient = .{ .left = left, .right = right } },
            .fill = .None,
        };
    }

    pub fn withFill(self: BorderStyle, fill: FillStyle) BorderStyle {
        var result = self;
        result.fill = fill;
        return result;
    }
};