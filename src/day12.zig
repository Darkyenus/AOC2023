const std = @import("std");
const aoc = @import("aoc.zig");

fn combinations(chars: []const u8, numbers: []const u32) u32 {
    if (numbers.len <= 0){
        if (std.mem.indexOfScalar(u8, chars, '#') == null) return 1;
        return 0;
    }
    const number = numbers[0];
    // Can it fit in here?
    if (number > chars.len) return 0;

    const canFitPositivelyHere = for (0..number) |i| {
        if (chars[i] == '.') break false;
    } else true;
    const canFitNegativelyHere = if (number < chars.len) chars[number] != '#' else true;

    var result: u32 = 0;
    if (canFitPositivelyHere and canFitNegativelyHere) {
        result += combinations(chars[@min(number + 1, chars.len)..], numbers[1..]);
    }
    if (chars[0] != '#') {
        result += combinations(chars[1..], numbers);
    }

    return result;
}

pub fn day() !void {
    var p = try aoc.Parser.parse("day12.txt");

    var combinationSum: u32 = 0;

    while (!p.endOfFile()) {
        var lineBuffer: [256]u8 = undefined;
        const lineTmp = p.until(' ');
        @memcpy(lineBuffer[0..lineTmp.len], lineTmp);
        const line = lineBuffer[0..lineTmp.len];

        p.skipWhitespace();

        var numbersBuffer: [32]u32 = undefined;
        var numberCount: u32 = 1;
        numbersBuffer[0] = p.number();
        while (p.peek() == ',') {
            p.nextReadIndex += 1;
            numbersBuffer[numberCount] = p.number();
            numberCount += 1;
        }
        const numbers = numbersBuffer[0..numberCount];

        _ = p.endOfLine();

        const c = combinations(line, numbers);
        std.debug.print("{s} {any} = {}\n", .{ line, numbers, c });

        combinationSum += c;
    }

    // 8725 too high
    std.debug.print("Day 12: {}\n", .{combinationSum});
}