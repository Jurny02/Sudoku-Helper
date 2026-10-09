//
//  NumberPadView.swift
//  SudokuHelper
//

import SwiftUI

/// Buttons 1-9 plus an erase button for filling in the selected square,
/// or for picking a number to look for when no square is selected.
struct NumberPadView: View {
    /// Disables every button, e.g. when a starting number is selected.
    var isEnabled: Bool
    /// The numbers that can be tapped; the rest are greyed out.
    var allowedNumbers: Set<Int> = Set(1...9)
    /// Whether the erase button can be tapped.
    var canErase = true
    /// The number currently picked in number mode, drawn filled in.
    var highlightedNumber: Int? = nil
    var onNumber: (Int) -> Void
    var onErase: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(1...9, id: \.self) { number in
                let button = Button {
                    onNumber(number)
                } label: {
                    Text("\(number)")
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .disabled(!allowedNumbers.contains(number))

                if highlightedNumber == number {
                    button.buttonStyle(.borderedProminent)
                } else {
                    button.buttonStyle(.bordered)
                }
            }

            Button(action: onErase) {
                Image(systemName: "delete.left")
                    .font(.title3)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .disabled(!canErase)
            .accessibilityLabel("Erase")
        }
        .disabled(!isEnabled)
    }
}

#Preview {
    NumberPadView(isEnabled: true, onNumber: { _ in }, onErase: {})
        .padding()
}
