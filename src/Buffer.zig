const std = @import("std");
const Buffer = @This();

path: []const u8,
contents: []u8,
allocator: std.mem.Allocator,

/// alloc:             Borrowed
/// path:              Copied
/// owned_contents:    Transferred on success, but on failure caller must handle lifetime
pub fn initWithOwnedContents(
    alloc: std.mem.Allocator,
    path: []const u8,
    owned_contents: []u8,
) !Buffer {
    // Complete all fallible work before accepting ownership of the contents.
    const path_copy = try alloc.dupe(u8, path);

    return .{
        .path = path_copy,
        .contents = owned_contents,
        .allocator = alloc,
    };
}

pub fn deinit(self: *Buffer) void {
    self.allocator.free(self.path);
    self.allocator.free(self.contents);
}

// #foldable{0} Tests
test "buffer owns a copy of the path" {
    const allocator = std.testing.allocator;
    var path = [_]u8{ 'f', 'i', 'l', 'e' };
    const contents = try allocator.dupe(u8, "text");
    var buffer = initWithOwnedContents(allocator, &path, contents) catch |err| {
        allocator.free(contents);
        return err;
    };
    defer buffer.deinit();

    path[0] = 'X';
    try std.testing.expectEqualStrings("file", buffer.path);
    try std.testing.expectEqualStrings("Xile", &path);
}

test "buffer takes contents without copying and releases owned allocations" {
    const allocator = std.testing.allocator;
    const contents = try allocator.dupe(u8, "\x00\xFFtext");
    var buffer = initWithOwnedContents(allocator, "file", contents) catch |err| {
        allocator.free(contents);
        return err;
    };
    defer buffer.deinit();

    try std.testing.expect(buffer.contents.ptr == contents.ptr);
    try std.testing.expectEqualSlices(u8, "\x00\xFFtext", buffer.contents);
    // The testing allocator checks cleanup for leaks and double frees.
}

test "failed initialization leaves contents owned by the caller" {
    // Allow contents allocation, then fail the path copy during initialization.
    var failing = std.testing.FailingAllocator.init(std.testing.allocator, .{
        .fail_index = 1,
    });
    const allocator = failing.allocator();
    const contents = try allocator.dupe(u8, "text");
    defer allocator.free(contents);

    try std.testing.expectError(error.OutOfMemory, initWithOwnedContents(allocator, "file", contents));
    try std.testing.expect(failing.has_induced_failure);
    try std.testing.expectEqualStrings("text", contents);
    contents[0] = 'T';
    try std.testing.expectEqualStrings("Text", contents);
}
