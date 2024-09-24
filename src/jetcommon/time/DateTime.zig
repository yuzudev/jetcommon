const std = @import("std");

const zul = @import("zul");

const Time = @import("../time.zig").Time;
const Date = @import("../time.zig").Date;
const TimestampPrecision = @import("../time.zig").TimestampPrecision;

const DateTime = @This();

zul_datetime: zul.DateTime,

pub fn fromUTC(year: i16, month: u8, day: u8, hour: u8, min: u8, sec: u8, micros: u32) !DateTime {
    return .{ .zul_datetime = try zul.DateTime.initUTC(year, month, day, hour, min, sec, micros) };
}

pub fn fromUnix(value: i64, precision: TimestampPrecision) !DateTime {
    const zul_datetime = switch (precision) {
        .seconds => try zul.DateTime.fromUnix(value, .seconds),
        .milliseconds => try zul.DateTime.fromUnix(value, .milliseconds),
        .microseconds => try zul.DateTime.fromUnix(value, .microseconds),
    };
    return .{ .zul_datetime = zul_datetime };
}

pub fn now() DateTime {
    return .{ .zul_datetime = zul.DateTime.now() };
}

pub fn date(self: DateTime) Date {
    return .{ .zul_date = self.zul_datetime.date() };
}

pub fn time(self: DateTime) Time {
    return .{ .zul_time = self.zul_datetime.time() };
}

pub fn unix(self: DateTime, precision: TimestampPrecision) i64 {
    return switch (precision) {
        .seconds => self.zul_datetime.unix(.seconds),
        .milliseconds => self.zul_datetime.unix(.milliseconds),
        .microseconds => self.zul_datetime.unix(.microseconds),
    };
}

pub fn format(
    self: DateTime,
    comptime actual_format: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    try self.zul_datetime.format(actual_format, options, writer);
}
