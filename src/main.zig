const std = @import("std");

pub const InputError = error{InvalidInput};
pub const State = enum { Playing, GameOver, Quit };

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

/// brute force check for winner
pub fn didPlayerWin(player: i8, board: *[9]i8) bool {
    return calculateScore(player, board) == 3;
}

const MiniMaxResult = struct { value: i32, choice: usize = undefined };

/// ? What is wrong with this ?
pub fn minimax(board: [9]i8, maximize: bool) MiniMaxResult {
    var board_copy = board;
    if (didPlayerWin(1, &board_copy) or didPlayerWin(-1, &board_copy)) {
        return MiniMaxResult{ .value = 10 };
    }
    if (maximize) {
        var max: ?MiniMaxResult = null;
        for (0..board.len) |i| {
            if (board_copy[i] == 0) {
                board_copy[i] = -1;
                var res = minimax(board_copy, false);
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
                board_copy[i] = 1;
                var res = minimax(board_copy, true);
                // printBoard(&board_copy);
                // std.debug.print("\nScore: {d}", .{res.value});
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

pub fn calculateScore(player: i8, board: *[9]i8) i8 {
    var score: i8 = 0;
    for (WINNING_POSITIONS) |position| {
        var cnt: i8 = 0;
        for (position) |i| {
            if (board[i] != player) {
                break;
            }
            cnt += 1;
        }
        if (cnt > score) {
            score = cnt;
        }
    }
    return score;
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
    const state = State.Playing;
    while (state == State.Playing) {
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
            std.debug.print("Result: {d}, value: {d}", .{ result.choice, result.value });
            board[result.choice] = current_player;
        }
        // check for winner
        const win = didPlayerWin(current_player, &board);
        if (win) {
            std.debug.print("\nPlayer {d} won!", .{if (current_player == 1) @as(i8, 1) else @as(i8, 2)});
            printBoard(&board);
            break;
        }
        current_player *= -1;
    }
}

test "winner test" {
    var board = [_]i8{0} ** 9;
    var win = didPlayerWin(1, &board);
    try std.testing.expect(!win);
    board[0] = 1;
    board[1] = 1;
    board[2] = 1;
    win = didPlayerWin(1, &board);
    try std.testing.expect(win);
}
