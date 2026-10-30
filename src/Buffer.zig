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
