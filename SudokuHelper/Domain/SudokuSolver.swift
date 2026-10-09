//
//  SudokuSolver.swift
//  SudokuHelper
//

import Foundation

/// Works out how many ways a board can be completed.
enum SudokuSolver {
    /// Counts the solutions of `board`, stopping once `limit` is reached.
    /// A proper puzzle has exactly one; `solutionCount(of:limit: 2)` tells 0, 1 and "more than one" apart.
    static func solutionCount(of board: SudokuBoard, limit: Int = 2) -> Int {
        let size = SudokuBoard.size
        // Bit n set = number n is already used in that row, column or box.
        var rows = [Int](repeating: 0, count: size)
        var columns = [Int](repeating: 0, count: size)
        var boxes = [Int](repeating: 0, count: size)
        var empty: [Int] = []

        for index in board.values.indices {
            let value = board.values[index]
            let row = index / size, column = index % size, box = row / 3 * 3 + column / 3
            if value == 0 {
                empty.append(index)
                continue
            }
            let bit = 1 << value
            // Two equal numbers in a unit: no solution at all.
            if rows[row] & bit != 0 || columns[column] & bit != 0 || boxes[box] & bit != 0 { return 0 }
            rows[row] |= bit
            columns[column] |= bit
            boxes[box] |= bit
        }

        var found = 0

        func search() {
            guard found < limit else { return }
            // Fill the square with the fewest options first, which keeps the search small.
            var best = -1, bestOptions = 0, bestCount = 10
            for (position, index) in empty.enumerated() where index >= 0 {
                let row = index / size, column = index % size, box = row / 3 * 3 + column / 3
                let options = ~(rows[row] | columns[column] | boxes[box]) & 0b11_1111_1110
                let count = options.nonzeroBitCount
                if count < bestCount {
                    best = position
                    bestOptions = options
                    bestCount = count
                    if count <= 1 { break }
                }
            }
            guard best >= 0 else {
                found += 1
                return
            }
            guard bestCount > 0 else { return }

            let index = empty[best]
            let row = index / size, column = index % size, box = row / 3 * 3 + column / 3
            empty[best] = -1
            for number in 1...9 where bestOptions & (1 << number) != 0 {
                let bit = 1 << number
                rows[row] |= bit
                columns[column] |= bit
                boxes[box] |= bit
                search()
                rows[row] &= ~bit
                columns[column] &= ~bit
                boxes[box] &= ~bit
                if found >= limit { break }
            }
            empty[best] = index
        }

        search()
        return found
    }
}
