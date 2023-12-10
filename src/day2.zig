const std = @import("std");

const RGB = struct {
    r: i32 = 0,
    g: i32 = 0,
    b: i32 = 0,

    pub fn possible(self: RGB, constraint: RGB) bool {
        return self.r <= constraint.r and self.g <= constraint.g and self.b <= constraint.b;
    }

    pub fn max(self: RGB, other: RGB) RGB {
        return .{ .r = @max(self.r, other.r), .g= @max(self.g, other.g), .b = @max(self.b, other.b) };
    }
};

fn parseInt(reader: std.io.AnyReader) !i32 {
    var result: i32 = 0;
    while (true) {
        if (reader.readByte()) |c| {
            if (c >= '0' and c <= '9') {
                result = result * 10 + (c - '0');
            } else {
                break;
            }
        } else |e| {
            if (e == error.EndOfStream) {
                break;
            }
            return e;
        }
    }
    return result;
}

pub fn day() !void {

    const inputFile = try std.fs.cwd().openFile("day2.txt", .{});
    defer inputFile.close();

    var bufReader = std.io.bufferedReader(inputFile.reader());
    const reader = bufReader.reader().any();

    var gameNumberSum: i32 = 0;
    var powerSum: i32 = 0;
    const rgbCriteria: RGB = .{
        .r = 12, .g = 13, .b = 14
    };

    // Iterate lines
    while (true) {
        // Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        reader.skipBytes("Game ".len, .{}) catch |e| if (e == error.EndOfStream) break else return e;
        const gameNumber = try parseInt(reader);//:
        try reader.skipBytes(" ".len, .{});

        var gameRGB: RGB = .{};

        // Read rounds
        var hasMoreRounds = true;
        while (hasMoreRounds) {
            var roundRGB = RGB {};
            // Read color
            while (true) {
                const colorAmount = try parseInt(reader);//' '
                const color = try reader.readByte();
                if (color == 'r') {
                    try reader.skipBytes("ed".len, .{});
                    roundRGB.r = colorAmount;
                } else if (color == 'g') {
                    try reader.skipBytes("reen".len, .{});
                    roundRGB.g = colorAmount;
                } else if (color == 'b') {
                    try reader.skipBytes("lue".len, .{});
                    roundRGB.b = colorAmount;
                } else undefined;

                if (reader.readByte()) |separator| {
                    if (separator == ',') {
                        // Expect more colors in round
                        try reader.skipBytes(" ".len, .{});
                        continue;
                    } else if (separator == ';') {
                        // No more colors in round, but has more rounds
                        try reader.skipBytes(" ".len, .{});
                        break;
                    } else if (separator == '\n') {
                        // No more colors in round and no more rounds
                        hasMoreRounds = false;
                        break;
                    } else unreachable;
                } else |e| {
                    if (e == error.EndOfStream) {
                        // No more colors in round and no more rounds
                        hasMoreRounds = false;
                        break;
                    }
                    return e;
                }
            }

            gameRGB = gameRGB.max(roundRGB);
        }

        if (gameRGB.possible(rgbCriteria)) {
            gameNumberSum += gameNumber;
        }
        powerSum += gameRGB.r * gameRGB.g * gameRGB.b;
    }

    std.debug.print("Day 2: {}   {}\n", .{ gameNumberSum, powerSum });
}