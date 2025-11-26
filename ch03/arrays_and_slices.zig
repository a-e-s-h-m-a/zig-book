const std = @import("std");

/// Prints information about a slice including its label, length, and first element.
/// If the slice is empty, displays -1 as the head value.
fn describe(label: []const u8, data: []const i32) void {
    // Get first element or -1 if slice is empty
    const head = if (data.len > 0) data[0] else -1;
    std.debug.print("{s}: len={} head={d}\n", .{ label, data.len, head });
}

/// Demonstrates array and slice fundamentals in Zig, including:
/// - Array declaration and initialization
/// - Creating slices from arrays with different mutability
/// - Modifying arrays through direct indexing and slices
/// - Array copying behavior (value semantics)
/// - Creating empty and zero-length slices
pub fn main() !void {
    // Declare mutable array with inferred size
    var values = [_]i32{ 3, 5, 8, 13 };
    // Declare const array with explicit size using anonymous struct syntax
    const owned: [4]i32 = .{ 1, 2, 3, 4 };

    // Create a mutable slice covering the entire array
    var mutable_slice: []i32 = values[0..];
    // Create an immutable slice of the first two elements
    const prefix: []const i32 = values[0..2];
    // Create a zero-length slice (empty but valid)
    const empty = values[0..0];

    // Modify array directly by index
    values[1] = 99;
    // Modify array through mutable slice
    mutable_slice[0] = -3;

    std.debug.print("array len={} allows mutation\n", .{values.len});
    describe("mutable_slice", mutable_slice);
    describe("prefix", prefix);
    // Demonstrate that slice modification affects the underlying array
    std.debug.print("values[0] after slice write = {d}\n", .{values[0]});
    std.debug.print("empty slice len={} is zero-length\n", .{empty.len});

    // Arrays are copied by value in Zig
    var copy = owned;
    copy[0] = -1;
    // Show that modifying the copy doesn't affect the original
    std.debug.print("copy[0]={d} owned[0]={d}\n", .{ copy[0], owned[0] });

    // Create a slice from an empty array literal using address-of operator
    const zero: []const i32 = &[_]i32{};
    std.debug.print("zero slice len={} from literal\n", .{zero.len});
    
    var runtime_array: [5]u8 = .{ 10, 20, 30, 40, 50 };
    const view: []u8 = runtime_array[0..0];
    std.debug.print("Initial slice: len={}, ptr={*}\n", .{ view.len, view.ptr });
    
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var list: std.ArrayList(u8) = .{};
    defer list.deinit(allocator);
    try list.append(allocator, 100);
    try list.append(allocator, 200);
    try list.append(allocator, 250);
    
    std.debug.print("ArrayList items after append: {any}\n", .{ list.items });
    
    //5) Show that slice 'view' remains unchanged and still points to original array
    std.debug.print(
        "Slice after ArrayList changes: len={}, ptr={*}\n",
        .{ view.len, view.ptr }
    );
    
    // 6) Modify the underlying array
    runtime_array[0] = 99;
    std.debug.print("After arr[0] = 99 → arr = {any}\n", .{ runtime_array });
    std.debug.print("Slice view still points arr: len={}, ptr={*}\n", .{ view.len, view.ptr });
}