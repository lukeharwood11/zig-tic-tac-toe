const std = @import("std");
const game = @import("game.zig");

const MiniMaxResult = struct { value: i32, choice: usize = undefined };

pub fn minimax(board: [9]i8, maximize: bool) MiniMaxResult {
    var board_copy = board;
    // get the score for the *opposite* player
    const state = game.getBoardState(&board_copy);
    switch (state) {
        .draw => {
            return .{ .value = 0 };
        },
        .player1_won => {
            return .{ .value = -1 };
        },
        .player2_won => {
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
