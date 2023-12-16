const std = @import("std");
const Parser = @import("Parser.zig");

const Card = enum(u4) {
    _2 = 0,
    _3 = 1,
    _4 = 2,
    _5 = 3,
    _6 = 4,
    _7 = 5,
    _8 = 6,
    _9 = 7,
    _T = 8,
    _J = 9,
    _Q = 10,
    _K = 11,
    _A = 12,
};

const HandType = enum(u3) {
    HighCard,
    OnePair,
    TwoPair,
    ThreeOfAKind,
    FullHouse,
    FourOfAKind,
    FiveOfAKind,
};

const Hand = struct {
    cards: [5]Card = undefined,
    type: HandType = HandType.HighCard,
    bid: u32 = 0,

    fn rawCards(self: Hand) u20 {
        return (@as(u20, @intFromEnum(self.cards[0])) << 16)
        | (@as(u20, @intFromEnum(self.cards[1])) << 12)
        | (@as(u20, @intFromEnum(self.cards[2])) << 8)
        | (@as(u20, @intFromEnum(self.cards[3])) << 4)
        | (@as(u20, @intFromEnum(self.cards[4])) << 0);
    }

    fn isLessThan(context: void, lhs: Hand, rhs: Hand) bool {
        _ = context;
        if (@intFromEnum(lhs.type) < @intFromEnum(rhs.type)) return true;
        if (@intFromEnum(lhs.type) > @intFromEnum(rhs.type)) return false;

        return lhs.rawCards() < rhs.rawCards();
    }
};

pub fn day() !void {
    var p = try Parser.parse("day7.txt");

    var hands: [2048] Hand = undefined;
    var handCount: u32 = 0;

    handReading: while (!p.endOfFile()) {
        const hand = &hands[handCount];
        handCount += 1;

        var histogramArray = [1]u3{0} ** 13;

        for (0..5) |cardIndex| {
            const c = p.next() orelse break :handReading;
            const card: Card = switch (c) {
                '2' => ._2,
                '3' => ._3,
                '4' => ._4,
                '5' => ._5,
                '6' => ._6,
                '7' => ._7,
                '8' => ._8,
                '9' => ._9,
                'T' => ._T,
                'J' => ._J,
                'Q' => ._Q,
                'K' => ._K,
                'A' => ._A,
                else => undefined
            };
            hand.cards[cardIndex] = card;
            histogramArray[@intFromEnum(card)] += 1;
        }
        p.skipWhitespace();
        hand.bid = p.number();

        // Compute hand type
        const histogram: @Vector(13, u3) = histogramArray;
        hand.type = switch (@reduce(.Max, histogram)) {
            5 => .FiveOfAKind,
            4 => .FourOfAKind,
            3 => if (@reduce(std.builtin.ReduceOp.Min, histogram -% @as(@TypeOf(histogram), @splat(1))) == 1) .FullHouse else .ThreeOfAKind,
            2 =>
                // Differentiating between two pair and one pair is tricky.
                // two pair has: 0 (few times), 2, 2, 1
                // one pair has: 0 (few times), 2, 1, 1, 1
                // XOR (10, 10, 01, 0...) = 01
                // XOR (10, 01, 01, 01, 0...) = 11
                if (@reduce(std.builtin.ReduceOp.Xor, histogram) == 3) .OnePair else .TwoPair
            ,
            1 => .HighCard,
            else => undefined,
        };

        _ = p.endOfLine();
    }

    std.mem.sort(Hand, hands[0..handCount], {}, Hand.isLessThan);

    var totalWinnings: u32 = 0;
    for (hands[0..handCount], 1..) |hand, rank| {
        std.debug.print("{:>5}: {}\n", .{rank, hand});

        totalWinnings += @intCast(hand.bid * rank);
    }

    //1st part: 250120186
    std.debug.print("Day 7: {}\n", .{ totalWinnings });
}