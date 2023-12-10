const std = @import("std");
const aoc = @import("aoc.zig");

pub fn day() !void {
    var p = try aoc.Parser.parse("day4.txt");
    p.ignoreWhitespace = true;

    var duplicatesDequeBuffer: [512]u64 = undefined;
    var duplicatesDeque = aoc.FixedDeque(u64).create(&duplicatesDequeBuffer);

    var pointSum: u32 = 0;
    var cardAmount: u64 = 0;
    while (p.maybeSkip("Card")) {
        _ = p.number();// Card number
        p.skip(":");

        const copies: u64 = @as(u64, 1) + (duplicatesDeque.popFront() orelse 0);
        cardAmount += copies;

        var winNumbers: i100 = 0;
        while (true) {
            const winNumber = p.number();
            //std.debug.print("Win: {}\n", .{winNumber});

            winNumbers |= @as(i100, 1) << @intCast(winNumber);

            if (p.maybeSkip("|")) {
                break;
            }
        }

        var cardNumbers: i100 = 0;
        while (true) {
            const cardNumber = p.number();
            //std.debug.print("Got: {}\n", .{cardNumber});
            cardNumbers |= @as(i100, 1) << @intCast(cardNumber);
            if (p.endOfLine()) break;
        }

        const matchingNumbers = winNumbers & cardNumbers;
        const matchingNumberCount = @popCount(matchingNumbers);

        while (duplicatesDeque.len() < matchingNumberCount) {
            duplicatesDeque.pushBack(0) catch unreachable;
        }
        for (0..matchingNumberCount) |i| {
            const dupAmount = duplicatesDeque.get(i) orelse unreachable;
            dupAmount.* += copies;
        }

        const points = (@as(u32, 1) << @intCast(matchingNumberCount)) >> 1;
        pointSum += points;
    }

    std.debug.print("Day 4: {} {}\n", .{ pointSum, cardAmount });
}