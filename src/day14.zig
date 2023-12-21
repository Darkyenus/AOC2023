const std = @import("std");
const aoc = @import("aoc.zig");

const Tile = enum(u4) {
    Empty = 0,
    Blocker = 1,
    Round = 2
};

const Grid = struct {
    // [h][w]
    grid: [1024][1024]Tile = std.mem.zeroes([1024][1024]Tile),
    width: u32 = 0,
    height: u32 = 0,

    fn moveAllNorth(grid: *Grid) void {
        for (0..grid.width) |w| {
            var moveTo: u32 = 0;
            for (0..grid.height) |h| {
                if (grid.grid[h][w] == Tile.Blocker) {
                    moveTo = @intCast(h + 1);
                } else if (grid.grid[h][w] == Tile.Round) {
                    grid.grid[h][w] = Tile.Empty;
                    grid.grid[moveTo][w] = Tile.Round;
                    moveTo += 1;
                }
            }
        }
    }


    fn moveAllSouth(grid: *Grid) void {
        for (0..grid.width) |w| {
            var moveTo: u32 = grid.height - 1;
            for (0..grid.height) |hr| {
                const h = grid.height - hr - 1;
                if (grid.grid[h][w] == Tile.Blocker and h > 0) {
                    moveTo = @truncate(h - 1);
                } else if (grid.grid[h][w] == Tile.Round) {
                    grid.grid[h][w] = Tile.Empty;
                    grid.grid[moveTo][w] = Tile.Round;
                    moveTo -%= 1;
                }
            }
        }
    }

    fn moveAllWest(grid: *Grid) void {
        for (0..grid.height) |h| {
            var moveTo: u32 = 0;
            for (0..grid.width) |w| {
                if (grid.grid[h][w] == Tile.Blocker) {
                    moveTo = @intCast(w + 1);
                } else if (grid.grid[h][w] == Tile.Round) {
                    grid.grid[h][w] = Tile.Empty;
                    grid.grid[h][moveTo] = Tile.Round;
                    moveTo += 1;
                }
            }
        }
    }

    fn moveAllEast(grid: *Grid) void {
        for (0..grid.height) |h| {
            var moveTo: u32 = grid.width - 1;
            for (0..grid.width) |wr| {
                const w = grid.width - wr - 1;
                if (grid.grid[h][w] == Tile.Blocker) {
                    moveTo = @truncate(w -% 1);
                } else if (grid.grid[h][w] == Tile.Round) {
                    grid.grid[h][w] = Tile.Empty;
                    grid.grid[h][moveTo] = Tile.Round;
                    moveTo -%= 1;
                }
            }
        }
    }

    fn moveCycle(grid: *Grid) void {
        grid.moveAllNorth();
        grid.moveAllWest();
        grid.moveAllSouth();
        grid.moveAllEast();
    }

    fn calculateLoad(grid: Grid) u32 {
        var load: u32 = 0;
        for (0..grid.height) |h| {
            const multiplier: u32 = grid.height - @as(u32, @intCast(h));
            for (0..grid.width) |w| {
                if (grid.grid[h][w] == Tile.Round) {
                    load += multiplier;
                }
            }
        }
        return load;
    }

    fn print(grid: Grid) void {
        for (0..grid.height) |h| {
            for (0..grid.width) |w| {
                if (grid.grid[h][w] == Tile.Round) {
                    std.debug.print("O", .{});
                } else if (grid.grid[h][w] == Tile.Blocker) {
                    std.debug.print("#", .{});
                } else {
                    std.debug.print(".", .{});
                }
            }
            std.debug.print("\n", .{});
        }
        std.debug.print("\n", .{});
    }
};


pub fn day() !void {
    var p = try aoc.Parser.parse("day14.txt");

    var grid = Grid {};

    while (!p.endOfFile()) {
        const line = p.untilEndOfLine();
        if (line.len == 0) break;
        grid.width = @intCast(line.len);
        for (line, 0..) |c, w| {
            grid.grid[grid.height][w] = if (c == 'O') Tile.Round else if (c == '#') Tile.Blocker else Tile.Empty;
        }
        grid.height += 1;

        _ = p.endOfLine();
    }

    var part1Grid = grid;
    part1Grid.moveAllNorth();
    const part1Load = part1Grid.calculateLoad();

    var part2Grid = grid;
    const cycles = 1000000000;
    var loadRecord = std.mem.zeroes([512]u32);
    const part2Load = p2l: for (0..cycles) |cycle| {
        part2Grid.moveCycle();
        loadRecord[cycle] = part2Grid.calculateLoad();

        if (cycle < 100) continue;

        //std.debug.print("{}: {}\n", .{cycle, part2Grid.calculateLoad()});

        if (std.mem.lastIndexOfScalar(u32, loadRecord[0..cycle], loadRecord[cycle])) |cycleStart| {
            const cycleLength = cycle - cycleStart;
            if (cycleStart > cycleLength * 2) {
                if (
                    std.mem.eql(u32, loadRecord[cycleStart - cycleLength + 1 .. cycleStart + 1], loadRecord[cycleStart + 1 .. cycle + 1]) and
                    std.mem.eql(u32, loadRecord[cycleStart - cycleLength*2 + 1 .. cycleStart-cycleLength + 1], loadRecord[cycleStart + 1 .. cycle + 1])
                    ) {
                    //std.debug.print("Found cycle of length {}\n", .{cycleLength});

                    break :p2l loadRecord[cycleStart + (cycles - cycleStart) % cycleLength - 1];
                }
            }
        }
    } else @panic("No cycle found");

    std.debug.print("Day 14: {} {}\n", .{part1Load, part2Load});

}