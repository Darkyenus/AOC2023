const std = @import("std");
const aoc = @import("aoc.zig");

const NodeID = [3]u8;
const ZERO_NODE: NodeID = .{0,0,0};
fn intFromNodeID(node: NodeID) u24 {
    return (@as(u24, node[2]) << 16) | (@as(u24, node[1]) << 8) | (@as(u24, node[0]));
}

fn isStartNode(node: NodeID) bool {
    return node[2] == 'A';
}

fn isEndNode(node: NodeID) bool {
    return node[2] == 'Z';
}

fn NodeIDFromLetters(letters: *const [3] u8) NodeID {
    return letters.*;
}

fn readIdentifier(p: *aoc.Parser) NodeID {
    return NodeIDFromLetters(p.nextFew(3) orelse undefined);
}

const Directions = struct {
    directions: [2048]Direction = undefined,
    directionCount: u32 = 0,

    fn add(self: *Directions, node: NodeID, directions: [2]NodeID) void {
        self.directions[self.directionCount] = .{.origin = node, .next = directions};
        self.directionCount += 1;
    }

    fn prepare(self: *Directions) void {
        std.mem.sort(Direction, self.directions[0..self.directionCount], {}, Direction.lessThan);
    }

    fn lookup(self: Directions, node: NodeID) [2]NodeID {
        const index = std.sort.binarySearch(Direction,
            node,
            self.directions[0..self.directionCount], {}, Direction.compare)
            orelse @panic("Element not found");
        return self.directions[index].next;
    }
};

const Direction  = struct {
    origin: NodeID = ZERO_NODE,
    next: [2] NodeID = .{ZERO_NODE, ZERO_NODE},

    fn lessThan(context: void, lhs: Direction, rhs: Direction) bool {
        _ = context;
        return intFromNodeID(lhs.origin) < intFromNodeID(rhs.origin);
    }

    fn compare(context: void, key: NodeID, item: Direction) std.math.Order {
        _ = context;
        return std.math.order(intFromNodeID(key), intFromNodeID(item.origin));
    }
};

pub fn day() !void {
    var p = try aoc.Parser.parse("day8.txt");

    var instructions: [1024]u1 = undefined;
    var instructionCount: u32 = 0;

    while (!p.endOfLine()) {
        const step: u1 = if ((p.next() orelse undefined) == 'L') 0 else 1;
        instructions[instructionCount] = step;
        instructionCount += 1;
    }

    var directions = Directions {};

    _ = p.endOfLine();
    while (!p.endOfFile()) {
        const node = readIdentifier(&p);
        p.skip(" = (");
        const left = readIdentifier(&p);
        p.skip(", ");
        const right = readIdentifier(&p);
        p.skip(")");
        _ = p.endOfLine();

        directions.add(node, .{left, right});
    }
    directions.prepare();

    var lcm: u64 = 1;

    //for (directions.directions[0..directions.directionCount]) |d| {
    //    std.debug.print("{s} = ({s}, {s})\n", .{d.origin, d.next[0], d.next[1]});
    //}

    for (directions.directions[0..directions.directionCount], 0..) |origin, i| {
        _ = i;
        var current = origin.origin;
        if (!isStartNode(current)) break;
        var stepCount: u32 = 0;
        var currentInstruction: u32 = 0;

        //std.debug.print("{}: {s}", .{i, current});

        while (!isEndNode(current)) {
            const new = directions.lookup(current)[instructions[currentInstruction]];
            if (std.mem.eql(u8, &current, &new)) @panic("Trivial endless cycle!");
            current = new;
            stepCount += 1;
            currentInstruction += 1;
            //std.debug.print("-> {s}", .{current});

            if (currentInstruction == instructionCount) {
                currentInstruction = 0;
            }
        }
        //std.debug.print("\n{}\n", .{stepCount});

        lcm = aoc.lcm(u64, lcm, stepCount);
    }

    // This works just because the input was kind.
    
    std.debug.print("Day 8: {}\n", .{ lcm });
}