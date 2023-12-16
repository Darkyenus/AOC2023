const std = @import("std");
const aoc = @import("aoc.zig");


pub fn day() !void {
    var p = try aoc.Parser.parse("day11.txt");

    var yDistance: u32 = 0;
    var xDistances: [512]u32 = undefined;
    var yDistances: [512]u32 = undefined;
    var starInColumn = [1]bool{ false } ** 512;

    var starPositions: [512][2]u32 = undefined;
    var starCount: u32 = 0;

    var width: usize = 0;

    var y: u32 = 0;
    while (!p.endOfFile()) {
        var starInRow = false;
        const line = p.untilEndOfLine();
        width = line.len;
        if (line.len == 0) {
            std.debug.print("YO: {?s}\n", .{p.nextFew(10)});
        }
        //std.debug.print("{}: {s} ({any})\n", .{y, line, p});

        for (line, 0..) |c, x| {
            if (c == '#') {
                starInColumn[x] = true;
                starInRow = true;
                starPositions[starCount] = .{ @intCast(x), @intCast(y) };
                starCount += 1;
            }
        }

        yDistance += if (starInRow) 1 else 1000000;
        yDistances[y] = yDistance - 1;

        y += 1;
        _ = p.endOfLine();
    }

    var xDistance:u32 = 0;
    for (0..width) |x| {
        xDistances[x] = xDistance;
        xDistance += if (starInColumn[x]) 1 else 1000000;
    }

    var distanceSum: u64 = 0;

    //std.debug.print("X: {any}\n", .{xDistances[0..width]});
    //std.debug.print("Y: {any}\n", .{yDistances[0..y]});

    for (0..starCount - 1) |firstStarIndex| {
        for (firstStarIndex + 1 .. starCount) |secondStarIndex| {
            const firstX: i64 = xDistances[starPositions[firstStarIndex][0]];
            const firstY: i64 = yDistances[starPositions[firstStarIndex][1]];

            const secondX: i64 = xDistances[starPositions[secondStarIndex][0]];
            const secondY: i64 = yDistances[starPositions[secondStarIndex][1]];

            const manhattanDistance = @abs(firstX - secondX) + @abs(firstY - secondY);
            //std.debug.print("{} to {}: {} ({} + {}) ({any} to {any})\n", .{firstStarIndex + 1, secondStarIndex + 1, manhattanDistance, @abs(firstX - secondX),  @abs(firstY - secondY), starPositions[firstStarIndex], starPositions[secondStarIndex]});
            distanceSum += manhattanDistance;
        }
    }

    //702771271959 too high
    std.debug.print("Day 11: {}\n", .{ distanceSum });
}