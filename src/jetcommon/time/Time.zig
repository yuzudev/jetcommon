const std = @import("std");

const zul = @import("zul");

zul_time: zul.Time,

const Time = @This();

pub const Format = enum {
    rfc3339,
};

pub fn init(hour: u8, min: u8, sec: u8, micros: u32) !Time {
    const zul_time = try zul.Time.init(hour, min, sec, micros);
    return .{ .zul_time = zul_time };
}

pub fn parse(input: []const u8, fmt: Format) !Time {
    return switch (fmt) {
        .rfc3339 => .{ .zul_time = try zul.Time.parse(input, .rfc3339) },
    };
}
