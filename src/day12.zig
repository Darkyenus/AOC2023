const std = @import("std");
const aoc = @import("aoc.zig");


const DPCache = [50][200]u64;
fn combinationsDP(chars: []const u8, numbers: []const u32, cache: *DPCache) u64 {
    const c = &cache[numbers.len][chars.len];
    if (c.* == 0) {
        c.* = 1 + combinations(chars, numbers, cache);
    }
    return c.* - 1;
}
fn combinations(chars: []const u8, numbers: []const u32, cache: *DPCache) u64 {
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

    var result: u64 = 0;
    if (canFitPositivelyHere and canFitNegativelyHere) {
        result += combinationsDP(chars[@min(number + 1, chars.len)..], numbers[1..], cache);
    }
    if (chars[0] != '#') {
        result += combinationsDP(chars[1..], numbers, cache);
    }

    return result;
}

pub fn day() !void {
    var p = try aoc.Parser.parse("day12.txt");

    var combinationSum: u64 = 0;

    while (!p.endOfFile()) {
        var lineBuffer: [512]u8 = undefined;
        const lineTmp = p.until(' ');
        @memcpy(lineBuffer[0..lineTmp.len], lineTmp);
        var lineLen: usize = lineTmp.len;
        for (1..5) |_| {
            lineBuffer[lineLen] = '?';
            lineLen += 1;
            @memcpy(lineBuffer[lineLen.. lineLen + lineTmp.len], lineTmp);
            lineLen += lineTmp.len;
        }
        const line = lineBuffer[0..lineLen];

        p.skipWhitespace();

        var numbersBuffer: [128]u32 = undefined;
        var numberCount: u32 = 1;
        numbersBuffer[0] = p.number();
        while (p.peek() == ',') {
            p.nextReadIndex += 1;
            numbersBuffer[numberCount] = p.number();
            numberCount += 1;
        }
        for (1..5) |repeat| {
            @memcpy(numbersBuffer[repeat * numberCount .. repeat * numberCount + numberCount], numbersBuffer[0..numberCount]);
        }
        const numbers = numbersBuffer[0..numberCount * 5];

        _ = p.endOfLine();

        var cache : DPCache = std.mem.zeroes(DPCache);
        const c = combinations(line, numbers, &cache);
        //std.debug.print("{s} {any} = {}\n", .{ line, numbers, c });

        combinationSum += c;
    }

    std.debug.print("Day 12: {}\n", .{combinationSum});
}
