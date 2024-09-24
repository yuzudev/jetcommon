const std = @import("std");

const zul = @import("zul");

const Time = @import("../time.zig").Time;
const Date = @import("../time.zig").Date;
const TimestampPrecision = @import("../time.zig").TimestampPrecision;

const DateTime = @This();
pub const DateTimeFormat = enum { rfc3339, iso8601 };

zul_datetime: zul.DateTime,

pub fn fromUTC(year_: i16, month_: u8, day_: u8, hour_: u8, min: u8, sec: u8, micros: u32) !DateTime {
    return .{ .zul_datetime = try zul.DateTime.initUTC(year_, month_, day_, hour_, min, sec, micros) };
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

pub fn parse(input: []const u8) !DateTime {
    const zul_datetime = try zul.DateTime.parse(input, .rfc3339);
    return .{ .zul_datetime = zul_datetime };
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

pub fn dayOfWeek(self: DateTime) u4 {
    const months = [_]u4{ 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4 };

    const year_u16: u16 = @intCast(self.year());
    const yr = year_u16 - @as(u1, if (year_u16 - self.month() < 3) 1 else 0);

    const result = (yr +
        @divTrunc(yr, 4) -
        @divTrunc(yr, 100) +
        @divTrunc(yr, 400) +
        months[@as(usize, @intCast(self.month())) - 1] +
        self.day()) % 7;
    return @intCast(result);
}

pub inline fn dayName(self: DateTime) []const u8 {
    return switch (self.dayOfWeek()) {
        1 => "Mon",
        2 => "Tue",
        3 => "Wed",
        4 => "Thu",
        5 => "Fri",
        6 => "Sat",
        7 => "Sun",
        else => unreachable,
    };
}

pub inline fn monthNameAbbreviated(self: DateTime) []const u8 {
    return switch (self.zul_datetime.date().month) {
        1 => "Jan",
        2 => "Feb",
        3 => "Mar",
        4 => "Apr",
        5 => "May",
        6 => "Jun",
        7 => "Jul",
        8 => "Aug",
        9 => "Sep",
        10 => "Oct",
        11 => "Nov",
        12 => "Dec",
        else => unreachable,
    };
}

pub inline fn year(self: DateTime) i16 {
    return self.zul_datetime.date().year;
}

pub inline fn month(self: DateTime) u8 {
    return self.zul_datetime.date().month;
}

pub inline fn day(self: DateTime) u8 {
    return self.zul_datetime.date().day;
}

pub inline fn hour(self: DateTime) u8 {
    return self.zul_datetime.time().hour;
}

pub inline fn minute(self: DateTime) u8 {
    return self.zul_datetime.time().min;
}

pub inline fn seconds(self: DateTime) u8 {
    return self.zul_datetime.time().sec;
}

pub fn strftime(self: DateTime, writer: anytype, fmt: []const u8) !void {
    var index: usize = 0;

    while (index < fmt.len) {
        if (parseToken(fmt[index..])) |token| {
            switch (token) {
                .date_and_time => {
                    try writer.print("{s} {s} {} {}:{}:{} {}", .{
                        self.dayName(),
                        self.monthNameAbbreviated(),
                        self.day(),
                        self.hour(),
                        self.minute(),
                        self.seconds(),
                        self.year(),
                    });
                },
                else => return error.UnsupportedTimeFormatToken,
            }

            index += 2;
        } else {
            try writer.writeByte(fmt[index]);
            index += 1;
        }
    }
}

const Token = enum {
    abbreviated_weekday_name,
    full_weekday_name,
    abbreviated_month_name,
    full_month_name,
    date_and_time,
    year_truncated,
    day_of_month_zero_padded,
    MM_DD_YY,
    YYYY_MM_DD,
    week_based_year_truncated,
    week_based_year,
    hour_24hr,
    hour_12hr,
    day_of_year,
    month_decimal,
    minute,
    am_pm_designation,
    clock_time_24hr,
    clock_time_12hr,
    second,
    tab,
    iso8601_time,
    iso8601_weekday,
    week_number_sunday_first,
    week_number_iso8601,
    weekday_decimal_sunday_first,
    date,
    time,
    timezone_offset,
    timezone_name,
};

const tokens = [_]Token{};

fn parseToken(string: []const u8) ?Token {
    if (string.len < 2) return null;
    if (string[0] != '%') return null;
    return switch (string[1]) {
        // https://cplusplus.com/reference/ctime/strftime/
        'a' => .abbreviated_weekday_name,
        'A' => .full_weekday_name,
        'b' => .abbreviated_month_name,
        'B' => .full_month_name,
        'c' => .date_and_time,
        'C' => .year_truncated,
        'd' => .day_of_month_zero_padded,
        'D' => .MM_DD_YY,
        'F' => .YYYY_MM_DD,
        'g' => .week_based_year_truncated,
        'G' => .week_based_year,
        'h' => .abbreviated_month_name, // Same as %b
        'H' => .hour_24hr,
        'I' => .hour_12hr,
        'j' => .day_of_year,
        'm' => .month_decimal,
        'M' => .minute,
        'p' => .am_pm_designation,
        'r' => .clock_time_24hr,
        'R' => .clock_time_12hr,
        'S' => .second,
        't' => .tab,
        'T' => .iso8601_time,
        'u' => .iso8601_weekday,
        'U' => .week_number_sunday_first,
        'V' => .week_number_iso8601,
        'w' => .weekday_decimal_sunday_first,
        'x' => .date,
        'X' => .time,
        'z' => .timezone_offset,
        'Z' => .timezone_name,
        else => null,
    };
}
