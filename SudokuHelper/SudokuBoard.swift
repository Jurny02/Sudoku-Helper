//
//  SudokuBoard.swift
//  SudokuHelper
//

import Foundation

/// The row and column of one square, both 0...8.
struct SudokuPosition: Hashable {
    var row: Int
    var column: Int

    func sharesUnit(with other: SudokuPosition) -> Bool {
        row == other.row
            || column == other.column
            || (row / 3 == other.row / 3 && column / 3 == other.column / 3)
    }
}

/// A 9×9 Sudoku grid. Values are 1...9, and 0 means the square is empty.
struct SudokuBoard: Codable, Equatable {
    static let size = 9

    private(set) var values: [Int]
    /// Squares filled in by the puzzle itself. The player can't change these.
    private(set) var givens: [Bool]

    init() {
        values = Array(repeating: 0, count: Self.size * Self.size)
        givens = Array(repeating: false, count: Self.size * Self.size)
    }

    /// Builds a puzzle from 81 characters, where digits 1-9 are starting numbers and anything else is empty.
    init?(string: String) {
        let chars = Array(string.filter { !$0.isWhitespace })
        guard chars.count == Self.size * Self.size else { return nil }
        values = chars.map { Int(String($0)) ?? 0 }
        givens = values.map { $0 != 0 }
    }

    subscript(row: Int, column: Int) -> Int {
        values[row * Self.size + column]
    }

    func isGiven(row: Int, column: Int) -> Bool {
        givens[row * Self.size + column]
    }

    /// Puts a number (or 0 to erase) in a square. Does nothing for the puzzle's starting numbers.
    mutating func setValue(_ value: Int, row: Int, column: Int) {
        precondition((0...9).contains(value), "Sudoku values must be 0...9")
        guard !isGiven(row: row, column: column) else { return }
        values[row * Self.size + column] = value
    }

    var isEmpty: Bool { values.allSatisfy { $0 == 0 } }

    /// Numbers that already appear nine times, so there's nowhere left to put them.
    var completedNumbers: Set<Int> {
        Set((1...9).filter { number in values.filter { $0 == number }.count >= Self.size })
    }

    /// Whether the player has filled in any square themselves.
    var hasPlayerEntries: Bool {
        zip(values, givens).contains { value, isGiven in value != 0 && !isGiven }
    }

    /// Turns every number currently on the board into a fixed starting number.
    /// Used when the player has finished typing in a new puzzle.
    mutating func lockNumbersAsGivens() {
        givens = values.map { $0 != 0 }
    }

    /// Removes every number the player entered, keeping the puzzle's starting numbers.
    mutating func clearPlayerEntries() {
        for index in values.indices where !givens[index] {
            values[index] = 0
        }
    }

    var isComplete: Bool {
        !values.contains(0) && conflictingPositions().isEmpty
    }

    /// The squares that share a row, column or 3×3 box with the given square, excluding itself.
    static func peers(ofRow row: Int, column: Int) -> [(row: Int, column: Int)] {
        var result: [(row: Int, column: Int)] = []
        let boxRow = row / 3 * 3
        let boxColumn = column / 3 * 3
        for r in 0..<size {
            for c in 0..<size {
                guard r != row || c != column else { continue }
                let sameBox = (boxRow..<boxRow + 3).contains(r) && (boxColumn..<boxColumn + 3).contains(c)
                if r == row || c == column || sameBox {
                    result.append((r, c))
                }
            }
        }
        return result
    }

    /// The numbers that can still go in an empty square without clashing with its row, column or box.
    /// Returns an empty set for squares that already hold a number.
    func candidates(row: Int, column: Int) -> Set<Int> {
        guard self[row, column] == 0 else { return [] }
        return allowedNumbers(row: row, column: column)
    }

    /// The numbers that could go in this square given its row, column and box,
    /// ignoring whatever the square itself holds, so a filled square can still be changed.
    func allowedNumbers(row: Int, column: Int) -> Set<Int> {
        var remaining = Set(1...9)
        for peer in Self.peers(ofRow: row, column: column) {
            remaining.remove(self[peer.row, peer.column])
        }
        return remaining
    }

    /// Whether this empty square is the only place left for the number in its row, its column or its 3×3 box.
    func isOnlyPlace(for number: Int, row: Int, column: Int) -> Bool {
        guard candidates(row: row, column: column).contains(number) else { return false }

        func fitsNowhereElse(_ squares: [(row: Int, column: Int)]) -> Bool {
            !squares.contains { square in
                (square.row != row || square.column != column)
                    && candidates(row: square.row, column: square.column).contains(number)
            }
        }

        let rowSquares = (0..<Self.size).map { (row: row, column: $0) }
        let columnSquares = (0..<Self.size).map { (row: $0, column: column) }
        let boxRow = row / 3 * 3
        let boxColumn = column / 3 * 3
        let boxSquares = (0..<Self.size).map { (row: boxRow + $0 / 3, column: boxColumn + $0 % 3) }

        return fitsNowhereElse(rowSquares) || fitsNowhereElse(columnSquares) || fitsNowhereElse(boxSquares)
    }

    /// Whether the number in this square also appears in its row, column or box.
    func hasConflict(row: Int, column: Int) -> Bool {
        let value = self[row, column]
        guard value != 0 else { return false }
        return Self.peers(ofRow: row, column: column).contains { self[$0.row, $0.column] == value }
    }

    func conflictingPositions() -> [(row: Int, column: Int)] {
        var result: [(row: Int, column: Int)] = []
        for r in 0..<Self.size {
            for c in 0..<Self.size where hasConflict(row: r, column: c) {
                result.append((r, c))
            }
        }
        return result
    }
}
