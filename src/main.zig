const std = @import("std");

pub fn main() !void {
    inline for (.{
        @import("./day1.zig"),
        @import("./day2.zig"),
        @import("./day3.zig"),
        @import("./day4.zig"),
        @import("./day5.zig"),
    }, 1..) |day, dayNumber| {
        var timer = std.time.Timer.start() catch @panic("need timer to work");
        const startTime = timer.read();
        try day.day();
        const endTime = timer.read();
        const duration = endTime - startTime;
        std.debug.print("Day {} took {} ns ({} ms)\n\n", .{ dayNumber, duration, @divTrunc(duration, 1000000) });
    }
}