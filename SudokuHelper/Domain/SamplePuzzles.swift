//
//  SamplePuzzles.swift
//  SudokuHelper
//

import Foundation

extension SudokuBoard {
    /// The example puzzle offered from the main menu, also used in previews.
    static let sample = SudokuBoard(string: """
        .95..4...
        .....73.9
        .6..21..8
        136......
        ..2.6.1..
        ......673
        9..15..2.
        6.78.....
        ...2..98.
        """)!
}
