//
//  SimpleSolverTests.swift
//  SudokuHelperTests
//

import Testing
@testable import SudokuHelper

@MainActor
struct SimpleSolverTests {

    @Test func solvesTheExamplePuzzle() throws {
        let result = SimpleSolver.run(.sample)
        #expect(result.outcome == .solved)
        #expect(result.board == SudokuBoard.sample.filled(with: TestPuzzles.sampleSolution))
        #expect(result.progress.filled == 52)
    }

    @Test func firstStepFillsTheTopMostYellowSquareForOne() {
        var board = SudokuBoard.sample
        var progress = SimpleSolver.Progress()
        let forced = SimpleSolver.forcedSquare(for: 1, on: board)

        let step = SimpleSolver.step(&board, &progress)
        if let forced {
            #expect(step == .placed(1, at: forced))
            #expect(board[forced.row, forced.column] == 1)
            #expect(progress.number == 1)
        } else {
            #expect(step == .nothingFor(1))
            #expect(progress.number == 2)
        }
    }

    @Test func movesOnToTheNextNumberWhenThereIsNoYellowSquare() {
        // On an empty board nothing is forced.
        var board = SudokuBoard()
        var progress = SimpleSolver.Progress(number: 4)
        #expect(SimpleSolver.step(&board, &progress) == .nothingFor(4))
        #expect(progress.number == 5)
        #expect(progress.emptyRounds == 0)
    }

    @Test func givesUpAfterThreeRoundsWithoutAFill() {
        let result = SimpleSolver.run(SudokuBoard())
        #expect(result.outcome == .stuck)
        #expect(result.progress.steps == 27)
        #expect(result.progress.filled == 0)
    }
}

extension SudokuBoard {
    /// This board with every empty square filled from an 81-character solution.
    func filled(with solution: String) -> SudokuBoard {
        var board = self
        for (index, character) in solution.enumerated() {
            board.setValue(Int(String(character)) ?? 0, row: index / 9, column: index % 9)
        }
        return board
    }
}
