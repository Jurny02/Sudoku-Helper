//
//  GameView.swift
//  SudokuHelper
//

import SwiftUI

/// The board with its number pad. In setup mode the player types in a new puzzle;
/// in play mode the starting numbers are locked and every change is saved right away.
struct GameView: View {
    enum Mode {
        case setup
        case play
    }

    @State private var board: SudokuBoard
    @State private var mode: Mode
    @State private var selection: SudokuPosition?
    /// The number picked on the pad while no square is selected.
    @State private var highlightedNumber: Int?
    /// Earlier versions of the board, newest last, so changes can be undone one at a time.
    @State private var history: [SudokuBoard] = []
    @State private var isConfirmingClear = false
    @State private var isSolved = false
    @State private var showsSuccess = false
    /// False for the example game, so playing it never touches the player's saved game.
    private let savesProgress: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    init(board: SudokuBoard, mode: Mode, savesProgress: Bool = true) {
        _board = State(initialValue: board)
        _mode = State(initialValue: mode)
        self.savesProgress = savesProgress
    }

    var body: some View {
        VStack(spacing: 24) {
            SudokuBoardView(
                board: board,
                selection: $selection,
                highlightedNumber: highlightedNumber,
                onSquareTapped: { squareTapped($0) }
            )

            NumberPadView(
                isEnabled: selection.map { !board.isGiven(row: $0.row, column: $0.column) } ?? true,
                allowedNumbers: (selection.map { board.allowedNumbers(row: $0.row, column: $0.column) } ?? Set(1...9))
                    .subtracting(board.completedNumbers),
                canErase: selection.map { board[$0.row, $0.column] != 0 } ?? false,
                highlightedNumber: selection == nil ? highlightedNumber : nil,
                onNumber: { numberTapped($0) },
                onErase: { set(0) }
            )
            // A solved puzzle is finished, so it can only be looked at.
            .disabled(isSolved)

            Text(hint)
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
                .onTapGesture {
                    selection = nil
                    highlightedNumber = nil
                }
        }
        // No title, to keep the top bar light; the hint text says which mode you're in.
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .confirmationDialog(clearTitle, isPresented: $isConfirmingClear, titleVisibility: .visible) {
            Button(mode == .setup ? "Clear Board" : "Clear My Numbers", role: .destructive) {
                apply { board in
                    if mode == .setup {
                        board = SudokuBoard()
                    } else {
                        board.clearPlayerEntries()
                    }
                }
            }
        }
        .overlay {
            if showsSuccess {
                SuccessView(
                    onBackToMenu: { dismiss() },
                    onViewBoard: { withAnimation { showsSuccess = false } }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        // Save after every change, and again when the app goes to the background or the player leaves.
        .onChange(of: board) {
            checkIfSolved()
            if let highlightedNumber, board.completedNumbers.contains(highlightedNumber) {
                self.highlightedNumber = nil
            }
            autosave()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { autosave() }
        }
        .onDisappear { autosave() }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Undo", systemImage: "arrow.uturn.backward") { undo() }
                .disabled(history.isEmpty || isSolved)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button("Clear", systemImage: "trash") {
                isConfirmingClear = true
            }
            .disabled(isSolved || (mode == .setup ? board.isEmpty : !board.hasPlayerEntries))
        }

        if mode == .setup {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Start") { startGame() }
                    .fontWeight(.semibold)
                    .disabled(board.isEmpty || !board.conflictingPositions().isEmpty)
            }
        }
    }

    private var hint: String {
        if mode == .setup {
            return "Type in the puzzle's starting numbers, then tap Start."
        }
        if selection != nil {
            return "Tap an empty spot to go back to picking a number."
        }
        return highlightedNumber == nil
            ? "Pick a number to see where it fits, or tap a square to fill it in."
            : "Tap a green or yellow square to place the number there."
    }

    private var clearTitle: String {
        mode == .setup ? "Clear the whole board?" : "Clear your numbers?"
    }

    /// With a square selected, fills it in and deselects it. Otherwise picks (or un-picks) the number to look for.
    private func numberTapped(_ number: Int) {
        if selection != nil {
            set(number)
            selection = nil
        } else {
            highlightedNumber = highlightedNumber == number ? nil : number
        }
    }

    /// With a number picked, tapping a square where it fits places it there and clears the pick;
    /// tapping a square where it doesn't fit does nothing. Otherwise the tap selects or deselects the square.
    private func squareTapped(_ position: SudokuPosition) {
        if let number = highlightedNumber, selection == nil {
            guard board.candidates(row: position.row, column: position.column).contains(number) else { return }
            apply { $0.setValue(number, row: position.row, column: position.column) }
            highlightedNumber = nil
        } else {
            selection = selection == position ? nil : position
        }
    }

    private func set(_ value: Int) {
        guard let selection else { return }
        apply { $0.setValue(value, row: selection.row, column: selection.column) }
    }

    /// Changes the board, remembering the previous version so it can be undone.
    private func apply(_ change: (inout SudokuBoard) -> Void) {
        var updated = board
        change(&updated)
        guard updated != board else { return }
        history.append(board)
        if history.count > 500 { history.removeFirst() }
        board = updated
    }

    private func undo() {
        guard let previous = history.popLast() else { return }
        board = previous
    }

    /// Locks the typed-in numbers as the puzzle's starting numbers and begins playing.
    private func startGame() {
        board.lockNumbersAsGivens()
        mode = .play
        selection = nil
        highlightedNumber = nil
        // Typing in the puzzle can't be undone once the game has started.
        history = []
        GameStorage.save(board)
    }

    /// Shows the success screen once every square is filled in without clashes.
    /// A solved game is removed from storage, so Continue doesn't reopen a finished puzzle.
    private func checkIfSolved() {
        guard mode == .play, !isSolved, board.isComplete else { return }
        isSolved = true
        selection = nil
        highlightedNumber = nil
        if savesProgress { GameStorage.clear() }
        withAnimation(.spring(duration: 0.4)) { showsSuccess = true }
    }

    /// A puzzle that is still being typed in is never saved, so it can't overwrite the saved game.
    private func autosave() {
        guard mode == .play, savesProgress, !isSolved else { return }
        GameStorage.save(board)
    }
}

#Preview("Play") {
    NavigationStack {
        GameView(board: .sample, mode: .play)
    }
}

#Preview("Setup") {
    NavigationStack {
        GameView(board: SudokuBoard(), mode: .setup)
    }
}
