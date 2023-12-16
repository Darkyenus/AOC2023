const std = @import("std");
const Parser = @import("Parser.zig");

const Card = enum(u4) {
    _J,// Joker
    _2,
    _3,
    _4,
    _5,
    _6,
    _7,
    _8,
    _9,
    _T,
    _Q,
    _K,
    _A,
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
        // Remove jokers from histogram considerations
        const jokers = histogramArray[@intFromEnum(Card._J)];
        histogramArray[@intFromEnum(Card._J)] = 0;

        const histogram: @Vector(13, u3) = histogramArray;
        // How many times the most frequent card occurs
        const max = @reduce(.Max, histogram);
        // How many times the least frequent card occurs, ignoring cards that don't occur at all
        const min = @reduce(std.builtin.ReduceOp.Min, histogram -% @as(@TypeOf(histogram), @splat(1))) +% 1;

        const twosCount = @reduce(.Add, @select(u3, histogram == @as(@TypeOf(histogram), @splat(2)), @as(@TypeOf(histogram), @splat(1)), @as(@TypeOf(histogram), @splat(0))));

        // 1 joker and 4 different cards: pair
        // 1 joker and 2+1+1 = 3oak
        // 1 joker and 2+2 = full house
        // 1 joker and 3+1 = 4oak
        // 1 joker and 4 = 5oak
        // 2 joker and 1+1+1: 3oak
        // 2 joker and 2+1: 4oak
        // 2 joker and 3: 5oak
        // 3 joker and 1+1: 4oak
        // 3 joker and 2: 5oak
        // 4 joker and 1: 5oak
        // 5 joker: 5oak
        hand.type = switch (max + jokers) {
            5 => .FiveOfAKind,
            4 => .FourOfAKind,
            3 => if (min == 2) .FullHouse else .ThreeOfAKind,
            2 => if (twosCount == 2) .TwoPair else .OnePair,
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