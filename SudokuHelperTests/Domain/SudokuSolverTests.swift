//
//  SudokuSolverTests.swift
//  SudokuHelperTests
//

import Testing
@testable import SudokuHelper
@MainActor
struct SudokuSolverTests {

    @Test func examplePuzzleHasExactlyOneSolution() {
        #expect(SudokuSolver.solutionCount(of: .sample, limit: 2) == 1)
    }

    @Test func emptyBoardHasMoreThanOneSolution() {
        #expect(SudokuSolver.solutionCount(of: SudokuBoard(), limit: 2) == 2)
    }

    @Test func clashingNumbersHaveNoSolution() throws {
        // Two 5s in the first row.
        let board = try #require(SudokuBoard(string: "55" + String(repeating: ".", count: 79)))
        #expect(SudokuSolver.solutionCount(of: board) == 0)
    }

    @Test func unsolvableWithoutDirectClashHasNoSolution() throws {
        // The top-left square sees 1–8 in its row and a 9 in its column, so nothing fits there.
        let board = try #require(SudokuBoard(string:
            ".12345678" + "........." + "........." + "9........" + String(repeating: ".", count: 45)))
        #expect(board.candidates(row: 0, column: 0).isEmpty)
        #expect(SudokuSolver.solutionCount(of: board) == 0)
    }
}
