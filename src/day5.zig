const std = @import("std");
const Parser = @import("Parser.zig");

const T = u64;

const Mapping = struct {
    const Entry = struct {
        source: T,
        destination: T,
        size: T,

        fn sourceContains(self: Entry, value: T) bool {
            return value >= self.source and value < self.source + self.size;
        }

        fn lessThan(ctx: void, a: Entry, b: Entry) bool {
            _ = ctx;
            return a.source < b.source;
        }
    };

    entries: [128]Entry = undefined,
    entryCount: u32 = 0,

    fn add(self: *Mapping, source: T, destination: T, size: T) void {
        self.entries[self.entryCount] = .{ .source = source, .destination = destination, .size = size };
        self.entryCount += 1;
    }

    fn sort(self: *Mapping) void {
        std.mem.sort(Entry, self.entries[0..self.entryCount], {}, Entry.lessThan);
    }

    fn remap(self: Mapping, value: T) T {
        // TODO: Use binary search here (though that is not necessary yet)
        for (self.entries[0..self.entryCount]) |entry| {
            if (value >= entry.source and value < entry.source + entry.size) {
                return value - entry.source + entry.destination;
            }
        }
        return value;
    }

    fn remapRangeSet(self: Mapping, rangeSet: RangeSet) RangeSet {
        var result = RangeSet{};

        var nextMappingToConsider: u32 = 0;
        const mappingEntries = self.entries[0..self.entryCount];
        const inputRanges = rangeSet.ranges[0..rangeSet.rangeCount];

        for (inputRanges) |range| {
            var rangeStart = range.start;
            const rangeEnd = range.start + range.length;

            while (rangeStart < rangeEnd) {
                while (nextMappingToConsider < mappingEntries.len and
                 mappingEntries[nextMappingToConsider].source + mappingEntries[nextMappingToConsider].size <= rangeStart) {
                    nextMappingToConsider += 1;
                }

                if (nextMappingToConsider >= mappingEntries.len) {
                    // No more mapping, everything else is kept
                    result.addRange(rangeStart, rangeEnd - rangeStart);
                    break;
                }

                const mapping = mappingEntries[nextMappingToConsider];
                if (mapping.source > rangeStart) {
                    // Not mapping yet
                    const identityEnd = @min(rangeEnd, mapping.source);
                    result.addRange(rangeStart, identityEnd - rangeStart);
                    rangeStart = identityEnd;
                } else {
                    // Remapping
                    const remappedEnd = @min(rangeEnd, mapping.source + mapping.size);
                    result.addRange(rangeStart - mapping.source + mapping.destination, remappedEnd - rangeStart);
                    rangeStart = remappedEnd;
                }
            }
        }
        //std.debug.print("Remapped: \n\t", .{});
        //rangeSet.debugPrint();
        //std.debug.print("\nto\n\t", .{});
        //result.debugPrint();
        //std.debug.print("\nwhich compressed down to\n\t", .{});
        result.compress();

        //result.debugPrint();
        //std.debug.print("\n", .{});

        return result;
    }
};

const Mappings = struct {
    mappings: [7]Mapping = [1]Mapping{ .{} } ** 7,

    fn remap(self: Mappings, value: T) T {
        var v = value;
        for (self.mappings) |m| {
            //std.debug.print("{} -> ", .{v});
            v = m.remap(v);
            //std.debug.print("{}\n", .{v});
        }
        return v;
    }

    fn remapRangeSet(self: Mappings, rangeSet: RangeSet) RangeSet {
        var v = rangeSet;
        for (self.mappings) |m| {
            v = m.remapRangeSet(v);
        }
        return v;
    }
};

/// Set of ranges
const RangeSet = struct {
    const Range = struct {
        start: T,
        length: T,

        fn lessThan(ctx: void, a: Range, b: Range) bool {
            _ = ctx;
            return a.start < b.start;
        }

        fn extendBy(self: *Range, byRange: Range) bool {
            std.debug.assert(byRange.start >= self.start);

            const selfEnd = self.start + self.length;
            if (byRange.start > selfEnd) return false;

            std.debug.assert(byRange.start <= selfEnd);

            const byEnd = byRange.start + byRange.length;
            const futherEnd = @max(selfEnd, byEnd);
            self.length = futherEnd - self.start;
            return true;
        }
    };

    ranges: [128]Range = undefined,
    rangeCount: u32 = 0,

    fn addRange(self: *RangeSet, start: T, length: T) void {
        self.ranges[self.rangeCount] = .{ .start = start, .length = length };
        self.rangeCount += 1;
    }

    fn debugPrint(self: RangeSet) void {
        for (self.ranges[0..self.rangeCount], 0..) |range, i| {
            if (i != 0) std.debug.print(", ", .{});
            std.debug.print("{}-{}", .{range.start, range.start + range.length - 1});
        }
    }

    fn compress(self: *RangeSet) void {
        std.mem.sort(Range, self.ranges[0..self.rangeCount], {}, Range.lessThan);
        // First one always stays
        var read: u32 = 1;
        var write: u32 = 1;
        while (read < self.rangeCount) {
            // Check if ranges overlap
            const range = self.ranges[read];
            const previousRange = &self.ranges[write - 1];
            if (previousRange.extendBy(range)) {
                read += 1;
            } else {
                self.ranges[write] = range;
                read += 1;
                write += 1;
            }
        }
        if (write < self.rangeCount) {
            //std.debug.print("Compressed RangeSet from {} to {} ranges\n", .{self.rangeCount, write});
        }
        self.rangeCount = write;
    }
};

pub fn day() !void {
    var p = try Parser.parse("day5.txt");
    p.ignoreWhitespace = true;

    var seeds: [128]T = undefined;
    var seedCount: u32 = 0;

    var seedRangeSet = RangeSet {};

    p.skip("seeds:");
    while (!p.endOfLine()) {
        const rangeStart = p.number();
        const rangeLength = p.number();
        seedRangeSet.addRange(rangeStart, rangeLength);

        // Old
        seeds[seedCount] = rangeStart;
        seedCount += 1;
        seeds[seedCount] = rangeLength;
        seedCount += 1;
    }
    _ = p.endOfLine();

    var mappings = Mappings {};
    for (&mappings.mappings) |*m| {
        p.skipUntilIncluding(':');
        _ = p.endOfLine();

        while (!p.endOfLine()) {
            const destination = p.number();
            const source = p.number();
            const length = p.number();
            m.add(@intCast(source), @intCast(destination), @intCast(length));
            _ = p.endOfLine();
        }

        m.sort();
    }

    var minSeed: ?T = null;
    for (seeds[0..seedCount]) |seed| {
        //std.debug.print("Seed {}:\n", .{ seed });
        const remapped = mappings.remap(seed);
        minSeed = @min(minSeed orelse remapped, remapped);
    }

    seedRangeSet.compress();
    const remappedSeedRange = mappings.remapRangeSet(seedRangeSet);

    std.debug.print("Day 5: {?} {}\n", .{ minSeed, remappedSeedRange.ranges[0].start });
}