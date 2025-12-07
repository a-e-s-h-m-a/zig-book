const std = @import("std");

pub const Error = error{
    MissingSentinel,
};

fn ensureSentinel(input: []const u8) Error![:0]const u8 {
    if (input.len == 0) {
        return Error.MissingSentinel;
    }
    if (input[input.len - 1] != 0) {
        return Error.MissingSentinel;
    }
    // Properly create sentinel slice
    return input[0 .. input.len - 1 :0];
}

/// Demonstrates sentinel-terminated strings and arrays in Zig, including:
/// - Zero-terminated string literals ([:0]const u8)
/// - Many-item sentinel pointers ([*:0]const u8)
/// - Sentinel-terminated arrays ([N:0]T)
/// - Converting between sentinel slices and regulat slices
/// - Mutation through sentinel pointers
pub fn main() !void {
    // Strings literald in Zig are ssentinel-terminated by default with a zero byte
    // [:0]const u8 denotes a slice with a sentinel value of 0 at the end
    const literal: [:0]const u8 = "data fundamentals";

    // Convert the sentinel slice to a many-item sentinel pointer
    // [*:0]const u8 is compatible with C-style null-terminated strings
    const c_ptr: [*:0]const u8 = literal;

    // std:mem:span converts a sentinel-terminated pointer back to a slice
    // It scans until it finds the sentinel value (0) to determine the length
    const bytes = std.mem.span(c_ptr);
    std.debug.print("literal len={} contents=\"{s}\"\n", .{ bytes.len, bytes });

    // Declare a sentinel-terminated array with explicit size and sentinel valur
    // [6:0]u8 means an array of 6 elements plus a sentinel 0 byte at position 6
    var label: [6:0]u8 = .{ 'l', 'a', 'b', 'e', 'l', 0 };

    // Create a mutable sentinel slice from the array
    // The [0.. :0] syntax creates a slice from index 0 to the end, with sentinel 0
    var sentinel_view: [:0]u8 = label[0.. :0];

    // Modify the first element through the sentinel slice
    sentinel_view[0] = 'L';

    // Creates a regular (non-sentinel) slice from the first 4 elements
    // This drops the sentinel gurantees but provides a bounded slice
    const trimmed: []const u8 = sentinel_view[0..4];
    std.debug.print("trimmed slice len={} -> {s}\n", .{ trimmed.len, trimmed });

    // Convert the sentinel slice to a many-item sentinel pointer
    // This allows unchecked indexing while preserving sentinel information
    const tail: [*:0]u8 = sentinel_view;

    // Modify element at index 4 through the many-item sentinel pointer
    // No bounds checking occurs, but the sentinel gurantees remains valid
    tail[4] = 'X';

    // Demonstrate that mutations through the pointer affected the original array
    // std.mem.span uses the sentinel to reconstruct the full slice
    std.debug.print("full label after mutation: {s}\n", .{std.mem.span(tail)});
    
    std.debug.print("\n\n----------------------------------\n\n", .{});
    
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // SCENARIO 1: Using allocSentinel (sentinel is OUTSIDE the slice)
    std.debug.print("=== Scenario 1: allocSentinel ===\n", .{});
    const user_raw = "Hello world";
    const buf1 = try allocator.allocSentinel(u8, user_raw.len, 0);
    defer allocator.free(buf1);
    @memcpy(buf1, user_raw);
    
    std.debug.print("buf1.len={}\n", .{buf1.len});
    std.debug.print("Last char: '{c}' (is it 0? {})\n", .{buf1[buf1.len - 1], buf1[buf1.len - 1] == 0});
    
    _ = ensureSentinel(buf1) catch |err| {
        std.debug.print("Error: {any}\n", .{err});
        std.debug.print("This is expected - sentinel is outside slice bounds\n\n", .{});
    };

    // SCENARIO 2: Manual allocation with null terminator INSIDE the slice
    std.debug.print("=== Scenario 2: Manual with null inside ===\n", .{});
    const buf2 = try allocator.alloc(u8, user_raw.len + 1);
    defer allocator.free(buf2);
    @memcpy(buf2[0..user_raw.len], user_raw);
    buf2[user_raw.len] = 0; // Put null terminator inside the slice
    
    std.debug.print("buf2.len={}\n", .{buf2.len});
    std.debug.print("Last char: is 0? {}\n\n", .{buf2[buf2.len - 1] == 0});
    
    _ = ensureSentinel(buf2) catch |err| {
        std.debug.print("Error: {any}\n\n", .{err});
        return;
    };

    // SCENARIO 3: String literals (already sentinel-terminated)
    std.debug.print("=== Scenario 3: String literal ===\n", .{});
    const literal2: [:0]const u8 = "Hello world";
    std.debug.print("This is already sentinel-terminated!\n", .{});
    std.debug.print("Type: [:0]const u8\n", .{});
    std.debug.print("literal: {any}\n", .{literal2});
}
