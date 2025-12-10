const Color = @import("color").Color;

pub const AnimationType = union(enum) {
    None,
    Pulse: struct { speed: f32 },
    Cycle: struct { speed: f32 },
    Wave: struct { speed: f32, frequency: f32 },
    Breathe: struct { speed: f32 },
};

pub fn calculateAnimationFactor(anim_type: AnimationType, time: f32) f32 {
    return switch (anim_type) {
        .None => 0.0,
        .Pulse => |p| {
            const t = @mod(time * p.speed, 2.0);
            return if (t < 1.0) t else 2.0 - t;
        },
        .Cycle => |c| @mod(time * c.speed, 1.0),
        .Wave => |w| (@sin(time * w.speed * w.frequency) + 1.0) / 2.0,
        .Breathe => |b| {
            const t = @mod(time * b.speed, 2.0);
            return if (t < 1.0) t else 2.0 - t;
        },
    };
}
