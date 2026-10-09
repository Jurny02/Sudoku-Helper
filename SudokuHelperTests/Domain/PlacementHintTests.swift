//
//  PlacementHintTests.swift
//  SudokuHelperTests
//

import Testing
@testable import SudokuHelper
@MainActor
struct PlacementHintTests {
    let board = SudokuBoard.sample

    @Test func squareHoldingTheNumberIsExisting() {
        #expect(PlacementHint.hint(for: 9, at: SudokuPosition(row: 0, column: 1), on: board) == .existing)
    }

    @Test func squareHoldingAnotherNumberIsBlocked() {
        #expect(PlacementHint.hint(for: 2, at: SudokuPosition(row: 0, column: 1), on: board) == .blocked)
    }

    @Test func emptySquareWhereTheNumberClashesIsBlocked() {
        // Row 1 already has a 9.
        #expect(PlacementHint.hint(for: 9, at: SudokuPosition(row: 0, column: 0), on: board) == .blocked)
    }

    @Test func onlyPlaceLeftInABoxIsForced() {
        // Row 6, column 6 is the only place left for a 2 in the middle box.
        let position = SudokuPosition(row: 5, column: 5)
        #expect(PlacementHint.isOnlyPlace(for: 2, at: position, on: board))
        #expect(PlacementHint.hint(for: 2, at: position, on: board) == .forced)
    }

    @Test func onlyCandidateOfASquareIsForced() {
        // Row 2, column 5's only candidate is 8.
        #expect(board.candidates(row: 1, column: 4) == [8])
        #expect(PlacementHint.hint(for: 8, at: SudokuPosition(row: 1, column: 4), on: board) == .forced)
    }

    @Test func squareWithOtherOptionsIsPossible() {
        #expect(PlacementHint.hint(for: 2, at: SudokuPosition(row: 0, column: 0), on: board) == .possible)
    }
}
