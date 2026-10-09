//
//  SudokuBoardView.swift
//  SudokuHelper
//

import SwiftUI

/// Draws a 9×9 Sudoku grid with thin lines between squares and thick lines around each 3×3 box.
struct SudokuBoardView: View {
    /// Line weights, digit size and highlight colours. The game uses `.game`; the onboarding demo uses `.onboarding`.
    struct Style {
        var thickLineWidth: CGFloat
        var thinLineWidth: CGFloat
        var thickLineColor: Color
        var thinLineColor: Color
        /// A fixed digit size in points, or nil to scale digits with the squares.
        var digitSize: CGFloat?
        var digitWeight: Font.Weight?
        /// Squares already holding the picked number.
        var existingColor: Color
        /// Empty squares where the picked number can go.
        var possibleColor: Color
        /// Empty squares where the picked number must go.
        var forcedColor: Color
        /// Squares where the picked number can't go.
        var blockedColor: Color

        static let game = Style(
            thickLineWidth: 2.5,
            thinLineWidth: 0.5,
            thickLineColor: .primary,
            thinLineColor: .secondary.opacity(0.6),
            digitSize: nil,
            digitWeight: nil,
            existingColor: .accentColor.opacity(0.35),
            possibleColor: .green.opacity(0.3),
            forcedColor: .yellow.opacity(0.55),
            blockedColor: .gray.opacity(0.25)
        )

        /// Softer tints of equal lightness and white blocked squares, so the highlights read clearly.
        static let onboarding = Style(
            thickLineWidth: 2,
            thinLineWidth: 0.5,
            thickLineColor: .primary,
            thinLineColor: Color(.separator),
            digitSize: 22,
            digitWeight: .medium,
            existingColor: .accentColor.opacity(0.18),
            possibleColor: .green.opacity(0.18),
            forcedColor: Color(red: 1, green: 0xD6 / 255, blue: 0x0A / 255).opacity(0.35),
            blockedColor: .clear
        )
    }

    let board: SudokuBoard
    @Binding var selection: SudokuPosition?
    /// When set (and no square is selected), shows where this number can and can't go.
    var highlightedNumber: Int? = nil
    /// Called when a square is tapped. When nil, tapping just toggles the selection.
    var onSquareTapped: ((SudokuPosition) -> Void)? = nil
    var style: Style = .game

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let cellSide = side / CGFloat(SudokuBoard.size)

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Color(.systemBackground))

                VStack(spacing: 0) {
                    ForEach(0..<SudokuBoard.size, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<SudokuBoard.size, id: \.self) { column in
                                cell(row: row, column: column, side: cellSide)
                            }
                        }
                    }
                }

                GridLines(cellSide: cellSide, style: style)
                    .allowsHitTesting(false)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func cell(row: Int, column: Int, side: CGFloat) -> some View {
        let position = SudokuPosition(row: row, column: column)
        let value = board[row, column]
        ZStack {
            background(for: position, value: value)

            if value != 0 {
                let isGiven = board.isGiven(row: row, column: column)
                Text("\(value)")
                    .font(.system(
                        // A fixed size where set, but never more than the squares can hold on a small board.
                        size: min(style.digitSize ?? .infinity, side * 0.6),
                        weight: style.digitWeight ?? (isGiven ? .semibold : .regular),
                        design: .rounded
                    ))
                    .foregroundStyle(numberColor(row: row, column: column, isGiven: isGiven))
            }
        }
        .frame(width: side, height: side)
        .contentShape(Rectangle())
        .onTapGesture {
            // Starting numbers can't be changed, so their squares can't be selected either.
            guard !board.isGiven(row: row, column: column) else { return }
            if let onSquareTapped {
                onSquareTapped(position)
            } else {
                selection = selection == position ? nil : position
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Row \(row + 1), column \(column + 1), \(value == 0 ? "empty" : "\(value)")")
        .accessibilityAddTraits(selection == position ? [.isButton, .isSelected] : .isButton)
    }

    /// Starting numbers are black, the player's numbers use the accent color, and clashes are red.
    private func numberColor(row: Int, column: Int, isGiven: Bool) -> Color {
        if board.hasConflict(row: row, column: column) { return .red }
        return isGiven ? .primary : .accentColor
    }

    /// Highlights the selected square, the squares that share its row, column or box,
    /// and other squares holding the same number.
    /// With no square selected but a number picked, shows where that number can go instead.
    private func background(for position: SudokuPosition, value: Int) -> Color {
        guard let selection else {
            if let highlightedNumber {
                return placementColor(for: highlightedNumber, at: position)
            }
            return .clear
        }
        if selection == position {
            return Color.accentColor.opacity(0.35)
        }
        let selectedValue = board[selection.row, selection.column]
        if selectedValue != 0 && value == selectedValue {
            return Color.accentColor.opacity(0.2)
        }
        if selection.sharesUnit(with: position) {
            return Color.accentColor.opacity(0.08)
        }
        return .clear
    }

    /// The style's colour for what the square means for the picked number (see `PlacementHint`).
    private func placementColor(for number: Int, at position: SudokuPosition) -> Color {
        switch PlacementHint.hint(for: number, at: position, on: board) {
        case .existing: style.existingColor
        case .forced: style.forcedColor
        case .possible: style.possibleColor
        case .blocked: style.blockedColor
        }
    }
}

/// The grid lines, drawn on top of the squares so the thick box borders stay crisp.
private struct GridLines: View {
    let cellSide: CGFloat
    let style: SudokuBoardView.Style

    var body: some View {
        let total = cellSide * CGFloat(SudokuBoard.size)
        ZStack(alignment: .topLeading) {
            ForEach(0...SudokuBoard.size, id: \.self) { index in
                let isBoxEdge = index % 3 == 0
                let width = isBoxEdge ? style.thickLineWidth : style.thinLineWidth
                let color = isBoxEdge ? style.thickLineColor : style.thinLineColor
                let position = CGFloat(index) * cellSide

                Rectangle()
                    .fill(color)
                    .frame(width: width, height: total)
                    .offset(x: position - width / 2)

                Rectangle()
                    .fill(color)
                    .frame(width: total, height: width)
                    .offset(y: position - width / 2)
            }
        }
        .frame(width: total, height: total, alignment: .topLeading)
    }
}

#Preview {
    @Previewable @State var selection: SudokuPosition? = SudokuPosition(row: 0, column: 2)
    SudokuBoardView(board: .sample, selection: $selection)
        .padding()
}

#Preview("Number mode") {
    @Previewable @State var selection: SudokuPosition? = nil
    SudokuBoardView(board: .sample, selection: $selection, highlightedNumber: 5)
        .padding()
}
