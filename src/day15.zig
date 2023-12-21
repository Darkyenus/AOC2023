const std = @import("std");
const aoc = @import("aoc.zig");

fn hash(text: []const u8) u8 {
    var result: u8 = 0;

    for (text) |c| {
        result = @truncate((@as(u32, result) + c) * 17);
    }
    return result;
}

const SUBSLOT = struct {
    label: [8]u8 = undefined,
    labelLength: u8 = 0,
    lens: u8 = 0,
};

const SLOT = struct {
    subslots: [8]SUBSLOT = undefined,
    used: u8 = 0,

    fn indexOf(slot: SLOT, label: []const u8) ?u8 {
        return for (0..slot.used) |i| {
            if (std.mem.eql(u8, slot.subslots[i].label[0..slot.subslots[i].labelLength], label)) {
                return @intCast(i);
            }
        } else return null;
    }

    fn remove(slot: *SLOT, subslotIndex: u8) void {
        std.mem.copyForwards(SUBSLOT, slot.subslots[subslotIndex..slot.used-1], slot.subslots[subslotIndex + 1..slot.used]);
        slot.used -= 1;
    }
};

const HASHMAP = struct {
    slots: [256]SLOT = std.mem.zeroes([256]SLOT),

    fn remove(hm:*HASHMAP, label: []const u8) void {
        const slot = hash(label);
        if (hm.slots[slot].indexOf(label)) |subSlot| {
            hm.slots[slot].remove(subSlot);
        }
    }

    fn put(hm:*HASHMAP, label: []const u8, lens: u8) void {
        const slot = hash(label);
        if (hm.slots[slot].indexOf(label)) |subSlot| {
            hm.slots[slot].subslots[subSlot].lens = lens;
        } else {
            const subslot = &hm.slots[slot].subslots[hm.slots[slot].used];
            hm.slots[slot].used += 1;
            @memcpy(subslot.label[0..label.len], label);
            subslot.labelLength = @intCast(label.len);
            subslot.lens = lens;
        }
    }
};

pub fn day() !void {
    var p = try aoc.Parser.parse("day15.txt");

    var hashSumPart1: u32 = 0;
    var hashMap = HASHMAP{};

    while (true) {
        const segment = p.untilEndOfLineOr(',');
        _ = p.maybeSkip(",");
        if (segment.len <= 0) break;
        //std.debug.print("'{s}'\n", .{segment});

        hashSumPart1 += hash(segment);

        var labelLength: u32 = 0;
        while (segment[labelLength] >= 'a' and segment[labelLength] <= 'z') {
            labelLength += 1;
        }

        if (segment[labelLength] == '-') {
            hashMap.remove(segment[0..labelLength]);
        } else {
            hashMap.put(segment[0..labelLength], segment[labelLength + 1] - '0');
        }
    }

    var lensSum: usize = 0;
    for (hashMap.slots, 1..) |slot, boxNumber| {
        for (0..slot.used, 1..) |subSlot, subSlotNumber| {
            lensSum += boxNumber * subSlotNumber * slot.subslots[subSlot].lens;
        }
    }

    std.debug.print("Day 15: {} {}\n", .{hashSumPart1, lensSum});
}