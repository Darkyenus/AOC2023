const std = @import("std");

fn RollingHashMatcher(comptime needle: [] const u8) type {
    const HashInt = @Type(.{ .Int = .{ .signedness = .unsigned, .bits =needle.len * 5 }});

    comptime var needleHash: HashInt = 0;
    inline for (needle) |c| {
        if (c < 'a' or c > 'z') unreachable;

        needleHash <<= 5;
        needleHash += (c - 'a');
    }
    return struct {
        currentHash: HashInt = 0,
        currentHashFill: i32 = 0,

        pub fn match(self: *@This(), character: u8) bool {
            if (character >= 'a' and character <= 'z') {
                self.currentHash = (self.currentHash << 5) | (character - 'a');
                self.currentHashFill = @min(needle.len, self.currentHashFill + 1);

                return self.currentHashFill == needle.len and self.currentHash == needleHash;
            }

            // Reset hash
            self.reset();
            return false;
        }

        pub fn reset(self: *@This()) void {
            self.currentHashFill = 0;
        }
    };
}

pub fn day1() !void {

    const inputFile = try std.fs.cwd().openFile("day1.txt", .{});
    defer inputFile.close();

    var bufReader = std.io.bufferedReader(inputFile.reader());
    const reader = bufReader.reader();

    // Comptime to the rescue!
    // There is a bug in zig compiler, this works as a workaround.
    // RollingHashMatcher(){} should be directly in matchers tuple.
    // mN must be var for workaround to work and reset() calls are here just to prevent zig from complaining that it is not mutated.
    var m1 = RollingHashMatcher("one") {};
    m1.reset();
    var m2 = RollingHashMatcher("two") {};
    m2.reset();
    var m3 = RollingHashMatcher("three") {};
    m3.reset();
    var m4 = RollingHashMatcher("four") {};
    m4.reset();
    var m5 = RollingHashMatcher("five") {};
    m5.reset();
    var m6 = RollingHashMatcher("six") {};
    m6.reset();
    var m7 = RollingHashMatcher("seven") {};
    m7.reset();
    var m8 = RollingHashMatcher("eight") {};
    m8.reset();
    var m9 = RollingHashMatcher("nine") {};
    m9.reset();
    var matchers = .{
        m1, m2, m3, m4, m5, m6, m7, m8, m9
    };


    var totalSum: i32 = 0;
    var lines: i32 = 0;

    // Read lines
    while (true) {
        // Read line characters
        var firstDigit: ?i32 = null;
        var lastDigit: i32 = 0;
        while (true) {
            if (reader.readByte()) |c| {
                if (c == '\n') {
                    break;
                }
                var digit: ?i32 = null;
                if (c >= '0' and c <= '9') {
                    digit = c - '0';
                }

                inline for (&matchers, 1..) |*matcher, matchDigit| {
                    if (matcher.match(c)) {
                        digit = matchDigit;
                        // Do not break, other matchers need to see this too
                    }
                }

                if (digit) |d| {
                    firstDigit = firstDigit orelse d;
                    lastDigit = d;
                }
            } else |err| {
                if (err == error.EndOfStream) {
                    break;
                }
                return err;
            }
        }

        const lineNumber = (firstDigit orelse break) * 10 + lastDigit;
        totalSum += lineNumber;
        lines += 1;
    }

    std.debug.print("Day 1: {}\n", .{totalSum});
}