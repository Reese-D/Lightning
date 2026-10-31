const Buffer = @import("Buffer.zig");
const std = @import("std");
const Decoder = @import("encoding/utf8.zig");

pub const Point = struct {
    x: u32,
    y: u32,
};

pub const Viewport = struct {
    columns: u32,
    rows: u32,
};

pub const Pane = struct {
    buffer: *Buffer,
    viewport: Viewport,
    cursor_position: Point,
    
    pub fn init(buffer: *Buffer, width: u32, height: u32) Pane {
        return Pane{
            .buffer = buffer,
            .viewport = .{ .columns = width, .rows = height },
            .cursor_position = .{ .x = 0, .y = 0 },
        };
    }
    
    pub fn render(self: *Pane) !void {
        var decoder = Decoder.DecodedIterator.init(self.buffer.contents);
        var rows: u32 = 0;
        var columns: u32 = 0;
        
        while(decoder.next()) |decoded| {
            if(rows == self.viewport.rows){
                break;
            }
            if(columns >= self.viewport.columns and !decoded.character.isCodepoint('\n')) {
                consumeUntilNewline(&decoder);
                rows += 1;
                columns = 0;
                continue;
            }
            switch(decoded.character) {
                .codepoint => |codepoint| {
                    switch(codepoint) {
                        '\n' => {
                            rows += 1;
                            columns = 0;
                            //TODO display a newline character
                        },
                        '\r' => {
                            if(decoder.peek()) |next| {
                                if(next.character.isCodepoint('\n')) {
                                    //Do nothing, \r\n is a newline so just treat it as \n in the next iteration
                                }else{
                                    //TODO display a ^m character
                                }
                            }else {
                                //TODO also display a ^m character
                            }
                        },
                        else => {
                            //Display valid utf8 character and increment columns depending on how many characters wide it is
                            //if it's wider than the remaining columns, don't display it but increase column width appropriately
                        }
                    }
                },
                .invalid_byte => {
                    //TODO Display invalid bytes as escapes
                    columns += 1;
                },
            }
        }
    }

    fn consumeUntilNewline(decodeIter: *Decoder.DecodedIterator) void {
        while(decodeIter.next()) |decoded| {
            if(decoded.character.isCodepoint('\n')){
                return;
            }
        }
    }

};
