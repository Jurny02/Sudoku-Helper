//
//  SuccessView.swift
//  SudokuHelper
//

import SwiftUI

/// Shown over the board when the puzzle has been solved.
struct SuccessView: View {
    var onBackToMenu: () -> Void
    var onViewBoard: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, options: .nonRepeating)

                Text("Puzzle Solved!")
                    .font(.title.bold())

                Text("Every square is filled in and nothing clashes. Well done!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    Button(action: onBackToMenu) {
                        Text("Back to Menu")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.glassProminent)

                    Button(action: onViewBoard) {
                        Text("View Board")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(GlassOutlineButtonStyle())
                }
                .padding(.top, 8)
            }
            .padding(24)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))
            .padding(32)
        }
    }
}

#Preview {
    SuccessView(onBackToMenu: {}, onViewBoard: {})
}
