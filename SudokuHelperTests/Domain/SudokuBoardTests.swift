//
//  SudokuBoardTests.swift
//  SudokuHelperTests
//
//  Created by Bartosz Jurczyk on 29/09/2026.
//

import Testing
@testable import SudokuHelper
@MainActor
struct SudokuBoardTests {

    @Test func candidatesLeaveOutNumbersInTheSameRowColumnAndBox() {
        // Row 1 has 9, 5, 4; column 1 has 1, 9, 6; its box has 9, 5, 6.
        #expect(SudokuBoard.sample.candidates(row: 0, column: 0) == [2, 3, 7, 8])
    }

    @Test func startingNumbersCannotBeChanged() {
        var board = SudokuBoard.sample
        board.setValue(1, row: 0, column: 1)
        #expect(board[0, 1] == 9)
        board.setValue(8, row: 0, column: 0)
        #expect(board[0, 0] == 8)
    }

    @Test func numberPlacedNineTimesIsComplete() throws {
        let solved = try #require(SudokuBoard(string: TestPuzzles.sampleSolution))
        #expect(solved.completedNumbers == Set(1...9))
        #expect(solved.isComplete)
        #expect(SudokuBoard.sample.completedNumbers.isEmpty)
    }

    @Test func clearingPlayerEntriesKeepsStartingNumbers() {
        var board = SudokuBoard.sample
        board.setValue(8, row: 0, column: 0)
        #expect(board.hasPlayerEntries)
        board.clearPlayerEntries()
        #expect(board == .sample)
    }
}

/// Puzzles shared by several test files.
enum TestPuzzles {
    /// The only solution of `SudokuBoard.sample`.
    static let sampleSolution = "895634217214587369763921458136795842472368195589412673948153726627849531351276984"
}
