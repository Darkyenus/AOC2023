
const std = @import("std");

file: std.fs.File,
buffer: [1024]u8 = undefined,
bufferSize: usize = 0,
nextReadIndex: usize = 0,
eof: bool = false,
ignoreWhitespace: bool = false,

pub fn parse(path: [] const u8) !@This() {
    const file = try std.fs.cwd().openFile(path, .{});
    return .{
        .file = file
    };
}

fn available(self: *@This(), atLeast: usize) ?[]const u8 {
    const remaining = self.bufferSize - self.nextReadIndex;
    if (remaining >= atLeast) {
        return self.buffer[self.nextReadIndex..self.bufferSize];
    }
    if (self.eof) {
        return null;
    }
    // Compact buffer
    if (self.nextReadIndex > 0) {
        std.mem.copyForwards(u8, self.buffer[0..remaining], self.buffer[self.nextReadIndex .. (self.nextReadIndex + remaining)]);
        self.bufferSize -= self.nextReadIndex;
        self.nextReadIndex = 0;
    }
    // Read remaining
    const readBytes = self.file.readAll(self.buffer[self.bufferSize..]) catch unreachable;
    if (readBytes < self.buffer.len - self.bufferSize) {
        self.eof = true;
        self.file.close();
    }
    self.bufferSize += readBytes;
    if (self.bufferSize >= atLeast) {
        return self.buffer[0..self.bufferSize];
    }
    return null;
}

pub fn endOfFile(self: *@This()) bool {
    return self.available(1) == null;
}

// Reads one character, if available
pub fn next(self: *@This()) ?u8 {
    if (self.available(1)) |b| {
        self.nextReadIndex += 1;
        return b[0];
    }

    return null;
}

// Reads few characters, if available
pub fn nextFew(self: *@This(), comptime amount: u32) ?*const [amount] u8 {
    if (self.available(amount)) |b| {
        self.nextReadIndex += amount;
        return b[0..amount];
    }

    return null;
}

// Peeks one characters, if available
pub fn peek(self: *@This()) ?u8 {
    if (self.available(1)) |b| {
        return b[0];
    }

    return null;
}

pub fn maybeSkip(self: *@This(), literal: [] const u8) bool {
    if (self.ignoreWhitespace) self.skipWhitespace();
    if (self.available(literal.len)) |b| {
        if (std.mem.eql(u8, b[0..literal.len], literal)) {
            self.nextReadIndex += literal.len;
            return true;
        }
    }
    return false;
}

pub fn skip(self: *@This(), literal: [] const u8) void {
    if (!self.maybeSkip(literal)) {
        std.debug.panic("Expected to skip {s}, but found {?s}", .{ literal, self.available(literal.len + 5) });
    }
}

/// Skip characters, until scalar is found. Skip it too and return.
/// If scalar is never found, panic.
pub fn skipUntilIncluding(self: *@This(), scalar: u8) void {
    while (self.available(1)) |a| {
        if (std.mem.indexOfScalar(u8, a, scalar)) |i| {
            self.nextReadIndex += i + 1;
            return;
        }
        self.nextReadIndex += a.len;
    }
    std.debug.panic("Scalar '{}' not found", .{ scalar });
}

pub fn skipWhitespace(self: *@This()) void {
    while (true) {
        if (self.peek()) |c| {
            if (c == ' ' or c == '\t') {
                self.nextReadIndex += 1;
            } else return;
        } else return;
    }
}

pub fn endOfLine(self: *@This()) bool {
    if (self.ignoreWhitespace) self.skipWhitespace();
    return self.maybeSkip("\r\n") or self.maybeSkip("\n") or self.endOfFile();
}

// Returns a decimal number or null if the current character is not a digit
pub fn maybeNumber(self: *@This()) ?u32 {
    return self.maybeParseNumber(u32);
}

pub fn maybeParseNumber(self: *@This(), comptime Int: type) ?Int {
    if (self.ignoreWhitespace) self.skipWhitespace();
    var negative: bool = false;
    if (@typeInfo(Int).Int.signedness == .signed) {
        if ((self.peek() orelse return null) == '-') {
            self.nextReadIndex += 1;
            negative = true;
        }
    }

    var result: ?Int = null;

    while (self.peek()) |c| {
        if (c >= '0' and c <= '9') {
            self.nextReadIndex += 1;
            result = (result orelse 0) * 10 + (c - '0');
        } else break;
    }

    if (@typeInfo(Int).Int.signedness == .signed and negative) {
        if (result) |r| {
            return -r;
        } else {
            self.nextReadIndex -= 1;
            return null;
        }
    }
    return result;
}

pub fn number(self: *@This()) u32 {
    if (self.maybeNumber()) |n| {
        return n;
    }
    std.debug.panic("Expected number, got {?s}", .{ self.available(10) });
}


pub fn parseNumber(self: *@This(), comptime Int: type) Int {
    if (self.maybeParseNumber(Int)) |n| {
        return n;
    }
    std.debug.panic("Expected number, got {?s}", .{ self.available(10) });
}

// Returns a substring of the input starting from the current position
// and ending where `ch` is found or until the end if not found
pub fn until(self: *@This(), ch: u8) []const u8 {
    if (self.ignoreWhitespace) self.skipWhitespace();
    var av = self.available(1) orelse return &[0]u8{};
    if (std.mem.indexOfScalar(u8, av, ch)) |i| {
        self.nextReadIndex += i;
        return av[0..i];
    }
    av = self.available(av.len + 1) orelse return &[0]u8{};
    if (std.mem.indexOfScalar(u8, av, ch)) |i| {
        self.nextReadIndex += i;
        return av[0..i];
    }
    if (self.eof) {
        self.nextReadIndex += av.len;
        return av;
    }
    std.debug.panic("Buffer is not large enough, separator '{}' did not appear within {} bytes", .{ ch, av.len });
}

// Returns a substring of the input starting from the current position
// and ending just before line separator or until the end if not found
pub fn untilEndOfLine(self: *@This()) []const u8 {
    if (self.ignoreWhitespace) self.skipWhitespace();
    var av = self.available(1) orelse return &[0]u8{};
    if (std.mem.indexOfAny(u8, av, "\n\r")) |i| {
        self.nextReadIndex += i;
        return av[0..i];
    }
    av = self.available(av.len + 1) orelse return &[0]u8{};
    if (std.mem.indexOfAny(u8, av, "\n\r")) |i| {
        self.nextReadIndex += i;
        return av[0..i];
    }
    if (self.eof) {
        self.nextReadIndex += av.len;
        return av;
    }
    std.debug.panic("Buffer is not large enough, separator CR/LF did not appear within {} bytes", .{ av.len });
}