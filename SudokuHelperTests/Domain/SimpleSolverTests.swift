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

    @Test func fillsTheTopMostYellowSquareThenMovesOnToTheNextNumber() throws {
        var board = SudokuBoard.sample
        var progress = SimpleSolver.Progress()
        let forced = try #require(SimpleSolver.forcedSquare(for: 1, on: board))

        #expect(SimpleSolver.step(&board, &progress) == .placed(1, at: forced))
        #expect(board[forced.row, forced.column] == 1)
        #expect(progress.number == 2)
    }

    @Test func skipsNumbersAlreadyOnTheBoardNineTimes() throws {
        // The solution with all the 5s and the 6 in row 1, column 4 missing, so 1–4 are already complete.
        var puzzle = Array(TestPuzzles.sampleSolution.map { $0 == "5" ? "." : $0 })
        puzzle[3] = "."
        var board = try #require(SudokuBoard(string: String(puzzle)))
        var progress = SimpleSolver.Progress(number: 1)

        let step = SimpleSolver.step(&board, &progress)
        guard case .placed(5, _) = step else {
            Issue.record("Expected 1–4 to be skipped and a 5 to be placed, got \(step)")
            return
        }
        #expect(progress.number == 6)
        #expect(progress.steps == 1)
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
