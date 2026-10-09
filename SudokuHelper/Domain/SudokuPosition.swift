//
//  SudokuPosition.swift
//  SudokuHelper
//

import Foundation

/// The row and column of one square, both 0...8.
struct SudokuPosition: Hashable, Sendable {
    var row: Int
    var column: Int

    func sharesUnit(with other: SudokuPosition) -> Bool {
        row == other.row
            || column == other.column
            || (row / 3 == other.row / 3 && column / 3 == other.column / 3)
    }
}
