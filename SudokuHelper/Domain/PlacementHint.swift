//
//  PlacementHint.swift
//  SudokuHelper
//

import Foundation

/// What a square means for a picked number in number mode. The board view turns each one into a colour.
enum PlacementHint: Equatable, Sendable {
    /// The square already holds the number.
    case existing
    /// The number must go here: it's the only one that fits the square, or the square is the only place
    /// left for it in its row, column or box.
    case forced
    /// The number fits here but could also go elsewhere.
    case possible
    /// The number would clash here, or the square holds a different number.
    case blocked

    static func hint(for number: Int, at position: SudokuPosition, on board: SudokuBoard) -> PlacementHint {
        let value = board[position.row, position.column]
        if value == number { return .existing }
        guard value == 0 else { return .blocked }

        let candidates = board.candidates(row: position.row, column: position.column)
        guard candidates.contains(number) else { return .blocked }
        if candidates == [number] || isOnlyPlace(for: number, at: position, on: board) { return .forced }
        return .possible
    }

    /// Whether the square is the only place left for the number in its row, its column or its 3×3 box.
    static func isOnlyPlace(for number: Int, at position: SudokuPosition, on board: SudokuBoard) -> Bool {
        guard board.candidates(row: position.row, column: position.column).contains(number) else { return false }

        func fitsNowhereElse(_ squares: [SudokuPosition]) -> Bool {
            !squares.contains { square in
                square != position && board.candidates(row: square.row, column: square.column).contains(number)
            }
        }

        let size = SudokuBoard.size
        let rowSquares = (0..<size).map { SudokuPosition(row: position.row, column: $0) }
        let columnSquares = (0..<size).map { SudokuPosition(row: $0, column: position.column) }
        let boxRow = position.row / 3 * 3
        let boxColumn = position.column / 3 * 3
        let boxSquares = (0..<size).map { SudokuPosition(row: boxRow + $0 / 3, column: boxColumn + $0 % 3) }

        return fitsNowhereElse(rowSquares) || fitsNowhereElse(columnSquares) || fitsNowhereElse(boxSquares)
    }
}
