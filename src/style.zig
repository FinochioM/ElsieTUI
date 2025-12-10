const Color = @import("color.zig").Color;

pub const Style = struct {
    border: ?BorderColor,
    border_style: BorderStyle,
    fill: ?Fill,
    text_gradient: ?TextGradient,
    fill_shading: Shading,

    pub fn init() Style {
        return Style{
            .border = null,
            .border_style = .Single,
            .fill = null,
            .fill_shading = .None,
            .text_gradient = null,
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

    pub fn withTextGradient(self: Style, text_gradient: TextGradient) Style {
        var result = self;
        result.text_gradient = text_gradient;
        return result;
    }

    pub fn withBorderStyle(self: Style, border_style: BorderStyle) Style {
        var result = self;
        result.border_style = border_style;
        return result;
    }

    pub fn withFillShading(self: Style, fill_shading: Shading) Style {
        var result = self;
        result.fill_shading = fill_shading;
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

pub const TextGradient = union(enum) {
    Solid: Color,
    Horizontal: struct { left: Color, right: Color },
    Vertical: struct { top: Color, bottom: Color },
    Diagonal: struct { top_left: Color, bottom_right: Color },
    Radial: struct { center: Color, edge: Color },
};

pub const BorderStyle = union(enum) {
    Single,
    Double,
    Rounded,
    Thick,
    Dotted,
};

pub const Shading = union(enum) {
    None,
    Light,
    Stripple,
    Block,
};
