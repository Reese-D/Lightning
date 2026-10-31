const std = @import("std");
const curses = @import("ncurses_bindings.zig");

/// Owns a single active ncurses session. Don't copy this or initialize another session while it is active.
pub const Terminal = struct {
    screen: *curses.SCREEN,
    window: *curses.WINDOW,

    pub fn init() !Terminal {
        const terminalIn = curses.isatty(curses.STDIN_FILENO);
        const terminalOut = curses.isatty(curses.STDOUT_FILENO);

        if (terminalIn == 0 or terminalOut == 0) {
            return error.NotATerminal;
        }

        //affects how c library functions will interpret text/regional conventions
        //LC_CTYPE for character handling, "" chooses settings from process env
        const localePtr = curses.setlocale(curses.LC_CTYPE, "");
        if (localePtr == null) {
            return error.LocaleInitializationFailed;
        }

        
        const screen = curses.newterm(null, curses.stdout, curses.stdin) orelse return error.TerminalInitializationFailed;
        errdefer {
            const status_code = curses.endwin();
            curses.delscreen(screen);
            if (status_code == curses.ERR) {
                std.log.warn("curses failed to restore terminal state", .{});
            }
        }

        const window = curses.stdscr orelse return error.TerminalInitializationFailed;

        // Check that we can control keys directly, draw our own text, and decode special keys.
        if (curses.raw() == curses.ERR or
            curses.noecho() == curses.ERR or
            curses.keypad(window, true) == curses.ERR)
            {
                return error.TerminalConfigurationFailed;
            }

        return .{ .screen = screen, .window = window };
    }

    /// Cleanup is best-effort; always release screen even if restoration fails.
    pub fn deinit(self: *Terminal) void {
        const status_code = curses.endwin();
        curses.delscreen(self.screen);
        self.* = undefined;

        if (status_code == curses.ERR) {
            std.log.warn("curses failed to restore terminal state", .{});
        }
    }
};
