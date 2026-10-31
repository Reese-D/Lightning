const std = @import("std");

const Buffer = @import("Buffer.zig");
const Terminal = @import("frontend/terminal.zig").Terminal;

pub fn main(init: std.process.Init) !void {
    // Argument storage stays valid for the lifetime of the process arena.
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 2) {
        std.log.err("Usage: lightning <filename>", .{});
        return;
    }
    for (args[2..]) |arg| {
        std.log.warn("Extra unused argument will be discarded: {s}", .{arg});
    }

    //Read the whole file the user passed in, unless it's >16mb
    const contents = std.Io.Dir.cwd().readFileAlloc(
        init.io,
        args[1],
        init.gpa,
        .limited(16 * 1024 * 1024),
    ) catch |err| {
        std.log.err("Cannot read '{s}': {s}", .{
            args[1],
            @errorName(err),
        });
        return err;
    };

    var buffer = Buffer.initWithOwnedContents(init.gpa, args[1], contents) catch |err| {
        // Initialization failed: main still owns contents.
        init.gpa.free(contents);
        return err;
    };
    // Initialization succeeded: only buffer is responsible for freeing contents.
    defer buffer.deinit();

    std.log.info("Initial file: {s}", .{buffer.path});

    //Setup our frontend, right now we only support terminal editing (no gui)
    var terminal = try Terminal.init();
    defer terminal.deinit();

    
    
}
