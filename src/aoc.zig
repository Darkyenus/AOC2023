const std = @import("std");
pub const Parser = @import("Parser.zig");
pub const Deque = @import("deque.zig").Deque;

pub fn FixedDeque(comptime element: type) type {
    return struct {
        const DequeType = Deque(element);

        pub fn create(fixedBuffer: []element) DequeType {
            return .{ .tail = 0, .head = 0, .buf = fixedBuffer, .allocator = FailAllocator };
        }
    };
}

fn noAlloc (ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
    _ = ctx;
    _ = len;
    _ = ptr_align;
    _ = ret_addr;
    return null;
}
const FailAllocatorVTable: std.mem.Allocator.VTable = .{
    .alloc = noAlloc,
    .resize = std.mem.Allocator.noResize,
    .free = std.mem.Allocator.noFree
};
const FailAllocator: std.mem.Allocator = .{ .ptr = @constCast(&FailAllocatorVTable), .vtable = &FailAllocatorVTable };


pub fn gcd(comptime Int: type, a: Int, b: Int) Int {
    var high = @max(a, b);
    var low = @min(a, b);
    while (0 != low) {
        const newHigh = low;
        const newLow = high % low;
        high = newHigh;
        low = newLow;
    }
    return high;
}

pub fn lcm(comptime Int: type, a: Int, b: Int) Int {
    return a * (b / gcd(Int, a, b));
}