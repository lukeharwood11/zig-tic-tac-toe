const std = @import("std");

const Board = [9]i8;
pub const InputError = error{InvalidInput};
pub const BoardState = enum {
    player1_won,
    player2_won,
    draw,
    no_winner,

    fn isGameOver(self: BoardState) bool {
        return self != .no_winner;
    }

    fn toString(self: BoardState) []const u8 {
        return switch (self) {
            .player1_won => "Player 1 won!",
            .player2_won => "Player 2 won!",
            .draw => "No Winner!",
            .no_winner => "Game still in progress...",
        };
    }
};

/// future me should turn this into a bit-mask
const WINNING_POSITIONS: [8][3]usize = .{
    .{ 0, 3, 6 },
    .{ 1, 4, 7 },
    .{ 2, 5, 8 },
    .{ 0, 1, 2 },
    .{ 3, 4, 5 },
    .{ 6, 7, 8 },
    .{ 0, 4, 8 },
    .{ 2, 4, 6 },
};

/// Check the current state of the board.
/// Return whether there's a winner, a draw, or the game is still going
pub fn getBoardState(board: *Board) BoardState {
    for (WINNING_POSITIONS) |position| {
        var player1 = true;
        var player2 = true;
        for (position) |i| {
            if (board[i] != 1) {
                player1 = false;
            }
            if (board[i] != -1) {
                player2 = false;
            }
        }
        if (player1) {
            return BoardState.player1_won;
        } else if (player2) {
            return BoardState.player2_won;
        }
    }
    for (board) |val| {
        if (val == 0) {
            return BoardState.no_winner;
        }
    } else {
        return BoardState.draw;
    }
}

const MiniMaxResult = struct { value: i32, choice: usize = undefined };

pub fn minimax(board: [9]i8, maximize: bool) MiniMaxResult {
    var board_copy = board;
    // get the score for the *opposite* player
    const state = getBoardState(&board_copy);
    switch (state) {
        .draw => {
            return .{ .value = 0 };
        },
        .player1_won => {
            // std.debug.print("\nPlayer 1 won - Player: {d}\n", .{player});
            // printBoard(&board_copy);
            return .{ .value = -1 };
        },
        .player2_won => {
            // std.debug.print("\nPlayer 2 won - Player: {d}\n", .{player});
            // printBoard(&board_copy);
            return .{ .value = 1 };
        },
        else => {},
    }
    if (maximize) {
        // this is the AI player
        var max: ?MiniMaxResult = null;
        for (0..board.len) |i| {
            if (board_copy[i] == 0) {
                var b = board_copy;
                b[i] = -1;
                var res = minimax(b, false);
                res.choice = i;
                if (max) |current| {
                    max = if (res.value < current.value) current else res;
                } else {
                    max = res;
                }
            }
        }
        // max will be null if the board full (tie game)
        return max orelse .{ .value = 0 };
    } else {
        var min: ?MiniMaxResult = null;
        for (0..board.len) |i| {
            if (board_copy[i] == 0) {
                var b = board_copy;
                b[i] = 1;
                var res = minimax(b, true);
                res.choice = i;
                if (min) |current| {
                    min = if (res.value > current.value) current else res;
                } else {
                    min = res;
                }
            }
        }
        // min will be null if the board full (tie game)
        return min orelse .{ .value = 0 };
    }
}

pub fn getValidMove(board: *[9]i8) !usize {
    const reader = std.io.getStdIn().reader();
    var bfr: [1024]u8 = undefined;
    // infinite loop until valid input
    while (true) {
        std.debug.print("[0-8] >>> ", .{});
        const in = reader.readUntilDelimiter(&bfr, '\n') catch "";
        if (std.fmt.parseInt(usize, in, 10)) |index| {
            if (index < 0 or index >= 9) {
                std.debug.print("\nInvalid entry [0-8]\n", .{});
                continue;
            }
            if (board[index] == 0) {
                return index;
            } else {
                std.debug.print("\nOops.. someone is already there... Pick again.\n", .{});
            }
        } else |_| {
            std.debug.print("\nSome error occurred.\n", .{});
        }
    }
    return InputError.InvalidInput;
}

pub fn printBoard(board: *[9]i8) void {
    std.debug.print("\n", .{});
    for (0..3) |_| {
        std.debug.print("+---", .{});
    }
    std.debug.print("+\n", .{});
    for (board, 1..) |value, i| {
        if (value != 0) {
            std.debug.print("| {c} ", .{if (value == 1) @as(u8, 'x') else @as(u8, 'o')});
        } else {
            std.debug.print("|   ", .{});
        }
        if (i % 3 == 0) {
            std.debug.print("|\n", .{});
            for (0..3) |_| {
                std.debug.print("+---", .{});
            }
            std.debug.print("+\n", .{});
        }
    }
    std.debug.print("\n", .{});
}

pub fn main() !void {
    var board = [_]i8{0} ** 9;
    var current_player: i8 = 1;
    var state = BoardState.no_winner;
    while (state == BoardState.no_winner) {
        std.debug.print("Current Player: {d}", .{if (current_player == 1) @as(i8, 1) else @as(i8, 2)});
        printBoard(&board);
        if (current_player == 1) {
            if (getValidMove(&board)) |move| {
                board[move] = current_player;
                std.log.info("{d}", .{move});
            } else |_| {
                std.debug.print("\nError parsing move...\n", .{});
                break;
            }
        } else {
            const result = minimax(board, true);
            board[result.choice] = current_player;
        }
        state = getBoardState(&board);
        if (state.isGameOver()) {
            printBoard(&board);
            std.debug.print("\n{s}", .{state.toString()});
            break;
        }
        current_player *= -1;
    }
}

test "winner test" {
    var board = [_]i8{0} ** 9;
    var state = getBoardState(&board);
    try std.testing.expect(state == .no_winner);
    board[0] = 1;
    board[1] = 1;
    board[2] = 1;
    state = getBoardState(&board);
    try std.testing.expect(state == .player1_won);
}
