const std = @import("std");
const aoc = @import("aoc.zig");


pub fn day() !void {
    var p = try aoc.Parser.parse("day9.txt");
    p.ignoreWhitespace = true;

    // Here we go solving polynomials again.

    var extrapolationSum: i64 = 0;
    var historypolationSum: i64 = 0;

    while (!p.endOfFile()) {

        var frontier = [1]i64{0} ** 128;
        var newFrontier = [1]i64{0} ** 128;
        var historyFrontier = [1]i64{0} ** 128;
        var historyFrontierSize: u32 = 0;
        var frontierCount: u32 = 0;

        while (!p.endOfLine()) {
            const n = p.parseNumber(i64);

            newFrontier[0] = n;
            frontierCount += 1;
            for (1..frontierCount) |i| {
                const diff = newFrontier[i - 1] - frontier[i - 1];
                // This logic is incorrect, but breaks only on backward interpolation. But the input is small enough that we don't have to care about when it hits zero.
                //if (newFrontier[i - 1] == 0 and frontier[i - 1] == 0) {
                //    frontierCount = @intCast(i);
                //    break;
                //}
                newFrontier[i] = diff;
            }

            if (frontierCount == historyFrontierSize + 1) {
                historyFrontier[historyFrontierSize] = newFrontier[historyFrontierSize];
                historyFrontierSize += 1;
            }

            //std.debug.print("Frontier: {any}\n", .{newFrontier[0..frontierCount]});
            @memcpy(frontier[0..frontierCount], newFrontier[0..frontierCount]);
        }

        //std.debug.print("Frontier: {any}\n", .{frontier[0..frontierCount]});
        //std.debug.print("Hrontier: {any}\n", .{historyFrontier[0..frontierCount]});

        // Extrapolate
        var level = frontierCount - 1;
        newFrontier[level] = frontier[level];
        while (level > 0) {
            level -= 1;
            newFrontier[level] = frontier[level] + newFrontier[level + 1];
        }

        extrapolationSum += newFrontier[0];
        //std.debug.print("Extrapolation: {}\n", .{newFrontier[0]});

        std.debug.assert(frontierCount == historyFrontierSize);

        // Extrapole backwards
        level = historyFrontierSize - 1;
        newFrontier[level] = historyFrontier[level];
        while (level > 0) {
            level -= 1;
            newFrontier[level] = historyFrontier[level] - newFrontier[level + 1];
        }
        historypolationSum += newFrontier[0];
        //std.debug.print("Historypolation: {} ({any})\n", .{newFrontier[0], newFrontier[0..historyFrontierSize]});
    }

    std.debug.print("Day 9: {}  {}\n", .{ extrapolationSum, historypolationSum });
}