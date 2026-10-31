const Unicode = @import("std").unicode;
const std = @import("std");
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
        const decoded = decodeNextCharacter(self.remaining) orelse unreachable;
        self.remaining = self.remaining[decoded.bytes_consumed..];
        return decoded;
    }

    //bytes are borrowed
    pub fn init(bytes: []const u8) DecodedIterator {
        return DecodedIterator{ .remaining = bytes};
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
