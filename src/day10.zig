const std = @import("std");
const aoc = @import("aoc.zig");

const Tile = enum(u3) {
    NorthSouth, // |
    EastWest, // -
    NorthEast, // L
    NorthWest, // J
    SouthWest, // 7
    SouthEast, // F
    Ground, // .
    Start, // S
};

fn tileFromChar(c: u8) Tile {
    return switch (c) {
        '|' => .NorthSouth,
        '-' => .EastWest,
        'L' => .NorthEast,
        'J' => .NorthWest,
        '7' => .SouthWest,
        'F' => .SouthEast,
        '.' => .Ground,
        'S' => .Start,
        else => @panic("Invalid char")
    };
}

const Connections = [_][2]Pos {
    .{ P(0, -1), P(0, 1) },
    .{ P(-1, 0), P(1, 0) },
    .{ P(0, -1), P(1, 0) },
    .{ P(0, -1), P(-1, 0) },
    .{ P(0, 1), P(-1, 0) },
    .{ P(0, 1), P(1, 0) },
};

const Directions = [_] Pos {
    P(0, 1),
    P(0, -1),
    P(1, 0),
    P(-1, 0),
};

const Pos = struct {
    x: i16,
    y: i16,

    fn plus(self: Pos, other: Pos) Pos {
        return .{.x = self.x + other.x, .y = self.y + other.y };
    }


    fn minus(self: Pos, other: Pos) Pos {
        return .{.x = self.x - other.x, .y = self.y - other.y };
    }

    fn neg(self: Pos) Pos {
        return .{.x = -self.x, .y = -self.y };
    }

    fn equals(self: Pos, other: Pos) bool {
        return self.x == other.x and self.y == other.y;
    }
};
fn P(x: i16, y: i16) Pos {
    return Pos { .x = x, .y = y };
}

const InOut = enum {
    Unknown,
    Pipe,
    In,
    Out,
};

const Maze = struct {
    tiles: [1 << 15]Tile = undefined,
    inout: [1 << 15]InOut = undefined,
    width: u32 = 0,
    height: u32 = 0,

    fn index(self: Maze, pos: Pos) ?usize {
        if (pos.x < 0 or pos.y < 0 or pos.x >= self.width or pos.y >= self.height) return null;
        return @intCast(@as(u32, @intCast(pos.x)) + @as(u32, @intCast(pos.y)) * self.height);
    }

    fn tile(self: Maze, pos: Pos) Tile {
        if (self.index(pos)) |i| {
            return self.tiles[i];
        }
        return Tile.Ground;
    }

    fn setMark(self: *Maze, pos: Pos, m: InOut) void {
        if (self.index(pos)) |i| {
            const current = self.inout[i];
            if (current == .Unknown or m == .Pipe) {
                self.inout[i] = m;
            }
        }
    }

    fn getMark(self: Maze, pos: Pos) ?InOut {
        if (self.index(pos)) |i| {
            return self.inout[i];
        }
        return null;
    }

    fn startNext(self: Maze, pos: Pos) [2]Pos {
        var result: [2]Pos = undefined;
        var rI: u32 = 0;

        for (Directions) |dir| {
            const neighbor = @intFromEnum(self.tile(pos.plus(dir)));
            if (neighbor >= Connections.len) continue;
            for (Connections[neighbor]) |c| {
                if (c.neg().equals(dir)) {
                    result[rI] = pos.plus(dir);
                    rI += 1;
                }
            }
        }

        std.debug.assert(rI == 2);
        return result;
    }

    fn next(self: *Maze, pos: Pos, previousPos: Pos, polarity: u1) Pos {
        const t = self.tile(pos);
        const n = nextTile: for (Connections[@intFromEnum(t)]) |c| {
            if (pos.plus(c).equals(previousPos)) continue;
            break :nextTile pos.plus(c);
        } else unreachable;

        const forwardDir = pos.minus(previousPos);
        const rightDir = Pos {.x = -forwardDir.y, .y = forwardDir.x };
        const leftDir = Pos {.x = forwardDir.y, .y = -forwardDir.x };
        const forwardPos = pos.plus(forwardDir);
        const rightPos = pos.plus(rightDir);
        const leftPos = pos.plus(leftDir);

        const inOut = [_]InOut {.In, .Out};
        const rightMark = inOut[polarity];
        const leftMark = inOut[polarity ^ 1];

        if (t == .EastWest or t == .NorthSouth) {
            // Marks are to the left and to the right
            self.setMark(rightPos, rightMark);
            self.setMark(leftPos, leftMark);
        } else {
            // There is one mark forward and one mark to the opposite side
            if (rightPos.equals(n)) {
                // Turns to the right, so forward is left (and, well, left is left)
                self.setMark(leftPos, leftMark);
                self.setMark(forwardPos, leftMark);
            } else {
                self.setMark(rightPos, rightMark);
                self.setMark(forwardPos, rightMark);
            }
        }

        return n;
    }

    fn floodMarks(self: *Maze) u32 {
        while (true) {
            var i: usize = 0;
            var fixups: usize = 0;
            for (0..self.height) |y| {
                for (0..self.width) |x| {
                    const current = self.inout[i];
                    if (current == .Unknown) {
                        var newMark: InOut = .Unknown;
                        for (Directions) |d| {
                            const neighborMark = self.getMark(d.plus(Pos{.x = @intCast(x), .y = @intCast(y)})) orelse continue;
                            if (neighborMark == .Pipe or neighborMark == .Unknown) continue;
                            if (newMark != .Unknown and newMark != neighborMark) {
                                @panic("In & Out have met!");
                            }
                            newMark = neighborMark;
                            fixups += 1;
                        }
                        self.inout[i] = newMark;
                    }

                    i += 1;
                }
            }

            //std.debug.print("Fixup iteration...\n", .{});
            if (fixups == 0) break;
        }

        var inCount: u32 = 0;
        var outCount: u32 = 0;
        for (0..self.width*self.height) |i| {
            const mark = self.inout[i];
            if (mark == .In) {
                inCount += 1;
            } else if (mark == .Out) {
                outCount += 1;
            } else if (mark == .Unknown) {
                @panic("Got unresolved marks!");
            }
            //if ((i % self.width) == 0) std.debug.print("\n", .{});
            //std.debug.print("{s}", .{ if (mark == .Pipe) "X" else if (mark == .Out) "O" else "." });
        }

        // Now we need to figure out, which one is actually outside, until out it has been arbitrary
        const outside: InOut = out: for (0..self.width) |i| {
            const m = self.getMark(.{.x = @intCast(i), .y = 0 }) orelse continue;
            if (m == .In or m == .Out) break :out m;

            const n = self.getMark(.{.x = @intCast(i), .y = @intCast(self.height - 1) }) orelse continue;
            if (n == .In or n == .Out) break :out n;
        } else for (0..self.height) |i| {
            const m = self.getMark(.{.x = 0, .y = @intCast(i) }) orelse continue;
            if (m == .In or m == .Out) break :out m;

            const n = self.getMark(.{.x = @intCast(self.width - 1), .y = @intCast(i) }) orelse continue;
            if (n == .In or n == .Out) break :out n;
        } else @panic("None of the outer cells are marked, you will have to find a better algorithm for this.");

        //std.debug.print("Out: {}, In: {}\n", .{ outCount, inCount });
        return if (outside == .Out) inCount else outCount;
    }
};

pub fn day() !void {
    var p = try aoc.Parser.parse("day10.txt");

    var maze = Maze {};
    var mazeOut: u32 = 0;

    var startPos: Pos = .{.x = -1, .y = -1 };

    while (!p.endOfFile()) {
        const line = p.untilEndOfLine();
        for (line, 0..) |c, x| {
            const tile = tileFromChar(c);
            maze.tiles[mazeOut] = tile;
            maze.inout[mazeOut] = .Unknown;
            mazeOut += 1;

            if (tile == .Start) {
                startPos = .{.x = @intCast(x), .y = @intCast(maze.height) };
            }
        }
        maze.width = @intCast(line.len);
        maze.height += 1;
        _ = p.endOfLine();
    }

    //std.debug.print("Start: {}\n", .{startPos});

    var distance: u32 = 1;
    var previous: [2]Pos = .{ startPos, startPos };
    maze.setMark(startPos, .Pipe);
    var ends: [2]Pos = maze.startNext(startPos);

    while (!ends[0].equals(ends[1])) {
        for (0..2) |i| {
            const next = maze.next(ends[i], previous[i], @intCast(i));
            maze.setMark(next, .Pipe);
            previous[i] = ends[i];
            ends[i] = next;
        }
        distance += 1;
        //std.debug.print("{}: {any}\n", .{distance, ends});
    }

    // Floodfill grow seeds
    const inCount = maze.floodMarks();

    // 5619 is too much
    std.debug.print("Day 10: {}  {}\n", .{ distance, inCount });
}