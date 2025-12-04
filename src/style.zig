const Color = @import("color.zig").Color;

pub const Style = struct {
    border: ?BorderColor,
    fill: ?Fill,
    text_color: ?Color,

    pub fn init() Style {
        return Style{
            .border = null,
            .fill = null,
            .text_color = null,
        };
    }

    pub fn withBorder(self: Style, border: BorderColor) Style {
        var result = self;
        result.border = border;
        return result;
    }

    pub fn withFill(self: Style, fill: Fill) Style {
        var result = self;
        result.fill = fill;
        return result;
    }

    pub fn withTextColor(self: Style, color: Color) Style {
        var result = self;
        result.text_color = color;
        return result;
    }
};

pub const BorderColor = union(enum) {
    Solid: Color,
    VerticalGradient: struct { top: Color, bottom: Color },
    HorizontalGradient: struct { left: Color, right: Color },
    DiagonalGradient: struct { top_left: Color, bottom_right: Color },
    RadialGradient: struct { center: Color, edge: Color },
};

pub const Fill = union(enum) {
    Solid: Color,
    VerticalGradient: struct { top: Color, bottom: Color },
    HorizontalGradient: struct { left: Color, right: Color },
    DiagonalGradient: struct { top_left: Color, bottom_right: Color },
    RadialGradient: struct { center: Color, edge: Color },
};