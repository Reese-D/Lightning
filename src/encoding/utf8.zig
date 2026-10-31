const Unicode = @import("std").unicode;
const std = @import("std");

// #foldable{0} Source
// TODO implement the above is a future editor feature to fold code blocks as a hierarchy where higher numbers nest within lower numbers
pub const Character = union(enum) {
    codepoint: u21,
    invalid_byte: u8,
};

pub const Decoded = struct {
    character: Character,
    bytes_consumed: u8,
};

pub const DecodedIterator = struct {
    remaining: []const u8,

    pub fn next(self: *DecodedIterator) ?Decoded {
        const decoded = decodeNextCharacter(self.remaining) orelse return null;
        self.remaining = self.remaining[decoded.bytes_consumed..];
        return decoded;
    }

    //bytes are borrowed
    pub fn init(bytes: []const u8) DecodedIterator {
        return DecodedIterator{ .remaining = bytes };
    }
};

pub fn decodeNextCharacter(bytes: []const u8) ?Decoded {
    if (bytes.len == 0) {
        return null;
    }
    const invalid = Decoded{ .bytes_consumed = 1, .character = Character{ .invalid_byte = bytes[0] } };
    const length = Unicode.utf8ByteSequenceLength(bytes[0]) catch {
        return invalid;
    };
    if (length > bytes.len) {
        return invalid;
    }
    const character = switch (length) {
        1 => bytes[0],
        2 => Unicode.utf8Decode2(bytes[0..2].*),
        3 => Unicode.utf8Decode3(bytes[0..3].*),
        4 => Unicode.utf8Decode4(bytes[0..4].*),
        else => unreachable,
    } catch return invalid;

    return Decoded{ .character = .{ .codepoint = character }, .bytes_consumed = length };
}

// #foldable{0} Tests
test "decoder returns null for empty input" {
    try std.testing.expect(decodeNextCharacter("") == null);
}

test "decoder reads one to four byte codepoints" {
    const inputs = [_][]const u8{ "A", "é", "€", "😀", "\x00", "\xF4\x8F\xBF\xBF" };
    const codepoints = [_]u21{ 'A', 'é', '€', '😀', 0, 0x10FFFF };
    const lengths = [_]u8{ 1, 2, 3, 4, 1, 4 };

    for (inputs, codepoints, lengths) |input, codepoint, length| {
        try std.testing.expectEqualDeep(Decoded{
            .character = .{ .codepoint = codepoint },
            .bytes_consumed = length,
        }, decodeNextCharacter(input).?);
    }
}

test "decoder preserves malformed input one byte at a time" {
    const inputs = [_][]const u8{
        "\x80", // Stray continuation byte.
        "\xFF", // Invalid leading byte.
        "\xC2", // Truncated two-byte sequence.
        "\xE2\x82", // Truncated three-byte sequence.
        "\xF0\x9F\x98", // Truncated four-byte sequence.
        "\xE2A\xAC", // Invalid continuation byte.
        "\xC0\xAF", // Overlong two-byte encoding.
        "\xE0\x80\xAF", // Overlong three-byte encoding.
        "\xF0\x80\x80\xAF", // Overlong four-byte encoding.
        "\xED\xA0\x80", // Surrogate code point.
        "\xF4\x90\x80\x80", // Above U+10FFFF.
    };

    for (inputs) |input| {
        try std.testing.expectEqualDeep(Decoded{
            .character = .{ .invalid_byte = input[0] },
            .bytes_consumed = 1,
        }, decodeNextCharacter(input).?);
    }
}

test "iterator resumes valid decoding after an invalid byte" {
    const bytes = "A\xFFé";
    var iterator = DecodedIterator.init(bytes);
    const expected = [_]Decoded{
        .{ .character = .{ .codepoint = 'A' }, .bytes_consumed = 1 },
        .{ .character = .{ .invalid_byte = 0xFF }, .bytes_consumed = 1 },
        .{ .character = .{ .codepoint = 'é' }, .bytes_consumed = 2 },
    };

    for (expected) |item| {
        try std.testing.expectEqualDeep(item, iterator.next().?);
    }
    try std.testing.expectEqual(@as(usize, 0), iterator.remaining.len);
    try std.testing.expectEqualStrings("A\xFFé", bytes);
}

test "iterator returns null repeatedly at end of input" {
    var iterator = DecodedIterator.init("A");
    _ = iterator.next();
    try std.testing.expect(iterator.next() == null);
    try std.testing.expect(iterator.next() == null);

    var empty = DecodedIterator.init("");
    try std.testing.expect(empty.next() == null);
}
