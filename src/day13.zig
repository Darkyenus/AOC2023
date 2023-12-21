const std = @import("std");
const aoc = @import("aoc.zig");

const Line = u256;

fn loadLine(line: []const u8) Line {
    var result: Line = 0;
    for (line, 0..) |c, i| {
        if (c == '#') {
            result |= @as(Line, 1) << @intCast(i);
        }
    }
    return result;
}

fn findHorizontalSymmetry(grid: []Line, width: u32, targetSmudges: u32) ?u32 {
    //std.debug.print("\nFind symmetry: W: {}, H: {}, TS: {}\n", .{width, grid.len, targetSmudges});
    column: for (1..width) |c| {
        var smudges: u32 = 0;
        for (grid) |line| {
            const reverseLine = @bitReverse(line) >> @intCast(256 - width);

            const reverseShiftLeft = @as(i32, @intCast(width)) - @as(i32, @intCast(c*2));
            const maskSize = width - @abs(reverseShiftLeft);

            var lineA = line;
            var lineB = reverseLine;

            //std.debug.print("C: {} Line: {b} Shift: {} Mask size: {}\n", .{c, line, reverseShiftLeft, maskSize});
            if (reverseShiftLeft >= 0) {
                lineA >>= @intCast(reverseShiftLeft);
            } else {
                lineB >>= @intCast(-reverseShiftLeft);
            }


            const mask = (@as(u32, 1) << @intCast(maskSize)) - 1;
            //std.debug.print("Line: {b:>20}  {b:>20}  {b:>20}\n", .{line, lineA & mask, mask});
            //std.debug.print("Rine: {b:>20}  {b:>20}\n", .{reverseLine, lineB & mask});

            const match = (lineA ^ lineB) & mask;
            smudges += @popCount(match);

            //std.debug.print("({b} ^ {b}) = {b} ({})\n", .{lineA & mask, lineB & mask, match, smudges});

            if (smudges > targetSmudges) continue :column;
        }

        if (smudges == targetSmudges) return @intCast(width - c);
    }
    return null;
}

fn transposeLinesInto(line: []const Line, out: []Line) void {
    for (out, 0..) |*outLine, w| {
        const bit = @as(Line, 1) << @intCast(w);
        for (line, 0..) |inLine, h| {
            if (inLine & bit != 0) {
                outLine.* |= @as(Line, 1) << @intCast(h);
            }
        }
    }
}

pub fn day() !void {
    var p = try aoc.Parser.parse("day13.txt");

    var sum: u64 = 0;

    grid: while (!p.endOfFile()) {

        var lines = std.mem.zeroes([256]Line);
        var transposeLines = std.mem.zeroes([256]Line);

        var height: u32 = 1;
        const width: u32 = w: {
            const firstLine = p.untilEndOfLine();
            if (firstLine.len <= 0) {
                _ = p.endOfLine();
                continue :grid;
            }
            lines[0] = loadLine(firstLine);
            break :w @intCast(firstLine.len);
        };

        while (p.endOfLine()) {
            const line = p.untilEndOfLine();
            if (line.len <= 0) break;
            lines[height] = loadLine(line);
            height += 1;
        }

        transposeLinesInto(lines[0..height], transposeLines[0..width]);

        // Find the correct reflection planes
        const smudges: u32 = 2;// 2 because of how XOR with reflection works...
        const horizontal = findHorizontalSymmetry(lines[0..height], width, smudges);
        const vertical = if (horizontal == null) findHorizontalSymmetry(transposeLines[0..width], height, smudges) else null;
        //std.debug.print("H: {any}   V: {any}\n", .{horizontal, vertical});

        if (horizontal) |h| {
            sum += h;
        } else if (vertical) |v| {
            sum += 100 * v;
        } else @panic("No symmetry found");
    }

    std.debug.print("Day 13: {}\n", .{ sum });
}