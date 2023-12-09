const std = @import("std");

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn isSymbol(line: []u8, index: usize) bool {
    if (index < 0 or index >= line.len) {
        return false;
    }
    return line[index] == '*';
}

const GearIndex = struct {
    line: u2,
    index: u30
};

fn sumNumbers(previousLine: []u8, currentLine: []u8, nextLine: []u8,
 previousPrimedGears: []u16, currentPrimedGears: []u16, nextPrimedGears: []u16) i32 {
    var sum: i32 = 0;

    var gears = [3][]u16 { previousPrimedGears, currentPrimedGears, nextPrimedGears };

    var previousRowGear: ?GearIndex = null;
    var number: i32 = 0;
    var numberGear: ?GearIndex = null;

    for (0..currentLine.len) |i| {
        // Find gear
        const gear: ?GearIndex = if (isSymbol(previousLine, i))
            GearIndex { .line = 0, .index = @intCast(i) }
        else if (isSymbol(currentLine, i))
            GearIndex { .line = 1, .index = @intCast(i) }
        else if (isSymbol(nextLine, i))
            GearIndex { .line = 2, .index = @intCast(i) }
        else null;

        const c = currentLine[i];
        if (isDigit(c)) {
            number *= 10;
            number += c - '0';
            numberGear = numberGear orelse previousRowGear orelse gear;
        } else if (number != 0) {
            numberGear = numberGear orelse gear;
            if (numberGear) |g| {
                const prime = &gears[g.line][g.index];
                if (prime.* == 0) {
                    // Prime it!
                    prime.* = @intCast(number);
                } else {
                    // Defuse it!
                    sum += @intCast(number * prime.*);
                    prime.* = std.math.maxInt(u16);// Poison it
                }

                numberGear = null;
            }
            number = 0;
        }
        previousRowGear = gear;
    }

    if (number != 0) {
        if (numberGear) |g| {
            const prime = &gears[g.line][g.index];
            if (prime.* == 0) {
                // Prime it!
                prime.* = @intCast(number);
            } else {
                // Defuse it!
                sum += @intCast(number * prime.*);
                prime.* = std.math.maxInt(u16);// Poison it
            }
        }
    }

    return sum;
}

pub fn day3() !void {

    const inputFile = try std.fs.cwd().openFile("day3.txt", .{});
    defer inputFile.close();

    var bufReader = std.io.bufferedReader(inputFile.reader());
    const reader = bufReader.reader().any();

    var lineBuffer1: [512]u8 = [1]u8{'.'} ** 512;
    var lineBuffer2: [512]u8 = [1]u8{'.'} ** 512;
    var lineBuffer3: [512]u8 = [1]u8{'.'} ** 512;

    var primedGearBuffer1: [512]u16 = [1]u16{0} ** 512;
    var primedGearBuffer2: [512]u16 = [1]u16{0} ** 512;
    var primedGearBuffer3: [512]u16 = [1]u16{0} ** 512;

    var previousLineBuffer: []u8 = lineBuffer1[0..];
    var currentLineBuffer: []u8 = lineBuffer2[0..];
    var nextLineBuffer: []u8 = lineBuffer3[0..];
    var previousPrimedGearBuffer: []u16 = &primedGearBuffer1;
    var currentPrimedGearBuffer: []u16 = &primedGearBuffer2;
    var nextPrimedGearBuffer: []u16 = &primedGearBuffer3;

    var previousLine: []u8 = previousLineBuffer;
    var currentLine: []u8 = try reader.readUntilDelimiter(currentLineBuffer, '\n');
    var nextLine: []u8 = try reader.readUntilDelimiter(nextLineBuffer, '\n');
    var previousPrimedGears: []u16 = previousPrimedGearBuffer;
    var currentPrimedGears: []u16 = currentPrimedGearBuffer;
    var nextPrimedGears: []u16 = nextPrimedGearBuffer;

    var sum: i32 = 0;
    var lastLine = false;

    while (true) {
        // Go over current line
        sum += sumNumbers(previousLine, currentLine, nextLine, previousPrimedGears, currentPrimedGears, nextPrimedGears);

        if (lastLine) {
            break;
        }

        // Swap buffers
        const newNextBuffer = previousLineBuffer;
        previousLineBuffer = currentLineBuffer;
        currentLineBuffer = nextLineBuffer;
        nextLineBuffer = newNextBuffer;

        // Swap lines
        previousLine = currentLine;
        currentLine = nextLine;
        nextLine = reader.readUntilDelimiter(nextLineBuffer, '\n') catch &[0]u8{};

        if (nextLine.len == 0) {
            nextLine = nextLineBuffer[0..currentLine.len];
            @memset(nextLine, '.');
            lastLine = true;
        }

        // Swap primed gears
        const newCurrentPrimedGearBuffer = previousPrimedGearBuffer;
        previousPrimedGearBuffer = currentPrimedGearBuffer;
        currentPrimedGearBuffer = nextPrimedGearBuffer;
        nextPrimedGearBuffer = newCurrentPrimedGearBuffer;

        previousPrimedGears = currentPrimedGears;
        currentPrimedGears = nextPrimedGears;
        nextPrimedGears = nextPrimedGearBuffer[0..currentLine.len];
        @memset(nextPrimedGears, 0);
    }

    std.debug.print("Day 3: {}\n", .{ sum });
}