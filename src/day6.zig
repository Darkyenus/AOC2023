const std = @import("std");
const Parser = @import("Parser.zig");

fn raceOptions(duration: u64, record: u64) u64 {
    // hold = (-duration +- sqrt(duration^2 - 4*record)) / (-2)

    const sqrtInside: u64 = (duration * duration - 4 * record) * 4;
    const sqrt: u64 = std.math.sqrt(sqrtInside);
    const sqrtSquare: u64 = sqrt * sqrt;
    //const floorSqrt: u64 = if (sqrtSquare <= sqrtInside) sqrt else sqrt - 1;
    const ceilSqrt: u64 = if (sqrtSquare >= sqrtInside) sqrt else sqrt + 1;

    const holdLow4: u64 = duration * 2 - ceilSqrt;
    const holdHigh4: u64 = duration * 2 + ceilSqrt;

    const holdLow: u64 = (holdLow4 + 4) >> 2;
    const holdHigh: u64 = (holdHigh4 - 1) >> 2;

    const possibilities: u64 = holdHigh - holdLow + 1;
    //std.debug.print("Duration {}, Record: {}, possibilities: {}, low: {} ({}), high: {} ({})\n", .{ duration, record, possibilities, holdLow, holdLow4, holdHigh, holdHigh4 });
    return possibilities;
}

fn width10(n: u32) u32 {
    var w: u32 = 10;
    while (w < n) {
        w *= 10;
    }
    return w;
}

pub fn day() !void {
    var p = try Parser.parse("day6.txt");
    p.ignoreWhitespace = true;

    // Duration of the race
    var times: [64]u64 = undefined;
    var timeCount: u64 = 0;
    // Record distance in the race
    var distances: [64]u64 = undefined;
    var distanceCount: u64 = 0;

    var bigTime: u64 = 0;
    var bigDistance: u64 = 0;

    p.skipUntilIncluding(':');
    while (!p.endOfLine()) {
        const time = p.number();
        times[timeCount] = time;
        timeCount += 1;

        bigTime = bigTime * width10(time) + time;
    }

    p.skipUntilIncluding(':');
    while (!p.endOfLine()) {
        const dist = p.number();
        distances[distanceCount] = dist;
        distanceCount += 1;

        bigDistance = bigDistance * width10(dist) + dist;
    }

    std.debug.assert(timeCount == distanceCount);

    var possibilityProduct: u64 = 1;
    for (0..timeCount) |i| {
        const duration = times[i];
        const record = distances[i];

        const possibilities = raceOptions(duration, record);

        possibilityProduct *= possibilities;
    }

    std.debug.print("Day 6: {} {}\n", .{possibilityProduct, raceOptions(bigTime, bigDistance)});
}

// math

// duration = hold + run
// run = duration - hold
// distance = run * hold
// distance(hold): (duration - hold) * hold
// distanceOverRecord(hold): (duration - hold) * hold - record
// distanceOverRecord(hold): duration * hold - hold * hold - record
// distanceOverRecord(hold): -1*hold^2 + duration*hold - record
// solve using quadratic equation
// hold = (-duration +- sqrt(duration^2 - 4*(-1)*(-record))) / (2*-1)
// hold = (-duration +- sqrt(duration^2 - 4*record)) / (-2)

// test
// duration = 7, record = 9
// >>> (-7 + math.sqrt(7*7 - 4*9)) / -2
// 1.6972243622680054
// >>> (-7 - math.sqrt(7*7 - 4*9)) / -2
// 5.302775637731995

// now to convert this into nice whole numbers
