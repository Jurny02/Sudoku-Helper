//
//  SimpleSolver.swift
//  SudokuHelper
//

import Foundation

/// Solves a puzzle the way a player would with number mode, one check at a time:
/// pick a number, and if it has a yellow ("must go here") square, fill the top-most one. Either way, move on
/// to the next number, going round 1–9 and skipping numbers that are already on the board nine times.
/// After three rounds without filling anything, it gives up.
enum SimpleSolver {
    /// How many full rounds of 1–9 may pass without a fill before the solver gives up.
    static let maxEmptyRounds = 3

    struct Progress: Equatable {
        /// The number to check next.
        var number = 1
        /// Rounds of 1–9 in a row that filled nothing.
        var emptyRounds = 0
        /// Whether the current round has filled a square yet.
        var filledThisRound = false
        /// Numbers checked so far.
        var steps = 0
        /// Squares filled so far.
        var filled = 0
    }

    enum Outcome: Equatable {
        case running
        case solved
        /// The method can't place another number; the puzzle needs a smarter technique.
        case stuck
    }

    enum Step: Equatable {
        case placed(Int, at: SudokuPosition)
        case nothingFor(Int)
    }

    /// The top-most (then left-most) square where `number` must go, if there is one.
    static func forcedSquare(for number: Int, on board: SudokuBoard) -> SudokuPosition? {
        for row in 0..<SudokuBoard.size {
            for column in 0..<SudokuBoard.size {
                let position = SudokuPosition(row: row, column: column)
                if PlacementHint.hint(for: number, at: position, on: board) == .forced {
                    return position
                }
            }
        }
        return nil
    }

    /// Checks the next number and fills one square if it can, then moves on to the number after it.
    static func step(_ board: inout SudokuBoard, _ progress: inout Progress) -> Step {
        skipCompletedNumbers(on: board, &progress)
        let number = progress.number
        progress.steps += 1

        let result: Step
        if let position = forcedSquare(for: number, on: board) {
            board.setValue(number, row: position.row, column: position.column)
            progress.filled += 1
            progress.filledThisRound = true
            progress.emptyRounds = 0
            result = .placed(number, at: position)
        } else {
            result = .nothingFor(number)
        }

        advance(&progress)
        skipCompletedNumbers(on: board, &progress)
        return result
    }

    /// Moves to the next number, counting a round that filled nothing when it wraps from 9 back to 1.
    private static func advance(_ progress: inout Progress) {
        guard progress.number == 9 else {
            progress.number += 1
            return
        }
        progress.number = 1
        if !progress.filledThisRound { progress.emptyRounds += 1 }
        progress.filledThisRound = false
    }

    /// Numbers already on the board nine times have nowhere left to go, so they aren't checked.
    static func skipCompletedNumbers(on board: SudokuBoard, _ progress: inout Progress) {
        let completed = board.completedNumbers
        guard completed.count < 9 else { return }
        while completed.contains(progress.number) {
            advance(&progress)
        }
    }

    static func outcome(of board: SudokuBoard, _ progress: Progress) -> Outcome {
        if board.isComplete { return .solved }
        if progress.emptyRounds >= maxEmptyRounds { return .stuck }
        return .running
    }

    /// Runs the method to the end without any delay.
    static func run(_ board: SudokuBoard) -> (board: SudokuBoard, progress: Progress, outcome: Outcome) {
        var board = board
        var progress = Progress()
        skipCompletedNumbers(on: board, &progress)
        while outcome(of: board, progress) == .running {
            _ = step(&board, &progress)
        }
        return (board, progress, outcome(of: board, progress))
    }
}
