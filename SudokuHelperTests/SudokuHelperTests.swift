//
//  SudokuHelperTests.swift
//  SudokuHelperTests
//
//  Created by Bartosz Jurczyk on 29/09/2026.
//

import Testing
@testable import SudokuHelper

struct SudokuBoardTests {

    @Test func examplePuzzleHasExactlyOneSolution() {
        #expect(SudokuBoard.sample.solutionCount(limit: 2) == 1)
    }

    @Test func emptyBoardHasMoreThanOneSolution() {
        #expect(SudokuBoard().solutionCount(limit: 2) == 2)
    }

    @Test func clashingNumbersHaveNoSolution() throws {
        // Two 5s in the first row.
        let board = try #require(SudokuBoard(string: "55" + String(repeating: ".", count: 79)))
        #expect(board.solutionCount() == 0)
    }

    @Test func unsolvableWithoutDirectClashHasNoSolution() throws {
        // The top-left square sees 1–8 in its row and a 9 in its column, so nothing fits there.
        let board = try #require(SudokuBoard(string:
            ".12345678" +
            "........." +
            "........." +
            "9........" +
            String(repeating: ".", count: 45)
        ))
        #expect(board.candidates(row: 0, column: 0).isEmpty)
        #expect(board.solutionCount() == 0)
    }

    @Test func candidatesLeaveOutNumbersInTheSameRowColumnAndBox() {
        // Row 1 has 9, 5, 4; column 1 has 1, 9, 6; its box has 9, 5, 6.
        #expect(SudokuBoard.sample.candidates(row: 0, column: 0) == [2, 3, 7, 8])
    }

    @Test func onlyPlaceLeftInABoxIsFound() {
        // In the example, row 6 column 6 is the only place left for a 2 in the middle box.
        #expect(SudokuBoard.sample.isOnlyPlace(for: 2, row: 5, column: 5))
        #expect(!SudokuBoard.sample.isOnlyPlace(for: 2, row: 0, column: 0))
    }

    @Test func startingNumbersCannotBeChanged() {
        var board = SudokuBoard.sample
        board.setValue(1, row: 0, column: 1)
        #expect(board[0, 1] == 9)
        board.setValue(8, row: 0, column: 0)
        #expect(board[0, 0] == 8)
    }

    @Test func numberPlacedNineTimesIsComplete() throws {
        let solved = try #require(SudokuBoard(string:
            "895634217214587369763921458136795842472368195589412673948153726627849531351276984"))
        #expect(solved.completedNumbers == Set(1...9))
        #expect(solved.isComplete)
        #expect(SudokuBoard.sample.completedNumbers.isEmpty)
    }
}
