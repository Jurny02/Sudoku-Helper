//
//  GameView.swift
//  SudokuHelper
//

import SwiftUI

/// Shows a `GameFeature`: the board, the number pad and the toolbar. All decisions live in the feature.
struct GameView: View {
    let store: Store<GameFeature.State, GameFeature.Action>

    private var state: GameFeature.State { store.state }

    var body: some View {
        VStack(spacing: 24) {
            SudokuBoardView(
                board: state.board,
                selection: .constant(state.selection),
                highlightedNumber: state.highlightedNumber,
                onSquareTapped: { store.send(.squareTapped($0)) }
            )

            NumberPadView(
                isEnabled: state.isPadEnabled,
                allowedNumbers: state.allowedNumbers,
                canErase: state.canErase,
                highlightedNumber: state.padHighlightedNumber,
                onNumber: { store.send(.numberTapped($0)) },
                onErase: { store.send(.eraseTapped) }
            )

            Text(state.hint)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Tapping anywhere outside the board and pad clears the selected square or picked number.
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { store.send(.backgroundTapped) }
        }
        .background { CalmBackdrop() }
        // No title, to keep the top bar light; the hint text says which mode you're in.
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .confirmationDialog(
            state.clearTitle,
            isPresented: store.binding(\.isConfirmingClear) { $0 ? .clearTapped : .clearCancelled },
            titleVisibility: .visible
        ) {
            Button(state.clearButtonTitle, role: .destructive) { store.send(.clearConfirmed) }
        }
        .alert(
            state.puzzleProblem?.title ?? "",
            isPresented: store.binding(\.puzzleProblem.isPresent) { _ in .puzzleProblemDismissed },
            presenting: state.puzzleProblem
        ) { problem in
            Button("Keep Editing", role: .cancel) { store.send(.puzzleProblemDismissed) }
            if problem == .severalSolutions {
                Button("Start Anyway") { store.send(.startAnywayTapped) }
            }
        } message: { problem in
            Text(problem.message)
        }
        .overlay {
            if state.showsSuccess {
                SuccessView(
                    onBackToMenu: { store.send(.backToMenuTapped) },
                    onViewBoard: { store.send(.viewBoardTapped, animation: .default) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.spring(duration: 0.4), value: state.showsSuccess)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Undo", systemImage: "arrow.uturn.backward") { store.send(.undoTapped) }
                .disabled(!state.canUndo)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button("Clear", systemImage: "trash") { store.send(.clearTapped) }
                .disabled(!state.canClear)
        }

        if state.mode == .setup {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Start") { store.send(.startTapped) }
                    .fontWeight(.semibold)
                    .disabled(!state.canStart)
            }
        }
    }
}

private extension Optional {
    /// Lets an optional drive an `isPresented` binding.
    var isPresent: Bool { self != nil }
}

#Preview("Play") {
    NavigationStack {
        GameView(store: Store(
            initialState: GameFeature.State(board: .sample, mode: .play),
            reducer: GameFeature(gameRepository: InMemoryGameRepository())
        ))
    }
}

#Preview("Setup") {
    NavigationStack {
        GameView(store: Store(
            initialState: GameFeature.State(board: SudokuBoard(), mode: .setup),
            reducer: GameFeature(gameRepository: InMemoryGameRepository())
        ))
    }
}
