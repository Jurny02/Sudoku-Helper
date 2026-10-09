//
//  GameFeature.swift
//  SudokuHelper
//

import Foundation

/// The board with its number pad. In setup mode the player types in a new puzzle;
/// in play mode the starting numbers are locked and every change is saved right away.
struct GameFeature: Reducer {
    enum Mode: Equatable {
        case setup
        case play
    }

    /// Why Start couldn't begin the game straight away.
    enum PuzzleProblem: Equatable {
        case noSolution
        case severalSolutions
    }

    struct State: Equatable {
        var board: SudokuBoard
        var mode: Mode
        /// False for the example game, so playing it never touches the player's saved game.
        var savesProgress = true
        var selection: SudokuPosition?
        /// The number picked on the pad while no square is selected.
        var highlightedNumber: Int?
        /// Earlier versions of the board, newest last, so changes can be undone one at a time.
        var history: [SudokuBoard] = []
        var isSolved = false
        var showsSuccess = false
        var isConfirmingClear = false
        var puzzleProblem: PuzzleProblem?

        init(board: SudokuBoard, mode: Mode, savesProgress: Bool = true) {
            self.board = board
            self.mode = mode
            self.savesProgress = savesProgress
        }

        // What the screen shows, worked out from the state so it can be tested without a view.

        var isPadEnabled: Bool {
            !isSolved && (selection.map { !board.isGiven(row: $0.row, column: $0.column) } ?? true)
        }

        var allowedNumbers: Set<Int> {
            (selection.map { board.allowedNumbers(row: $0.row, column: $0.column) } ?? Set(1...9))
                .subtracting(board.completedNumbers)
        }

        var canErase: Bool {
            selection.map { board[$0.row, $0.column] != 0 } ?? false
        }

        /// The pad only shows a picked number while no square is selected.
        var padHighlightedNumber: Int? {
            selection == nil ? highlightedNumber : nil
        }

        var canUndo: Bool { !history.isEmpty && !isSolved }

        var canClear: Bool {
            !isSolved && (mode == .setup ? !board.isEmpty : board.hasPlayerEntries)
        }

        var canStart: Bool {
            !board.isEmpty && board.conflictingPositions().isEmpty
        }

        var hint: String {
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

        var clearTitle: String {
            mode == .setup ? "Clear the whole board?" : "Clear your numbers?"
        }

        var clearButtonTitle: String {
            mode == .setup ? "Clear Board" : "Clear My Numbers"
        }
    }

    enum Action: Equatable {
        case squareTapped(SudokuPosition)
        case numberTapped(Int)
        case eraseTapped
        case undoTapped
        case clearTapped
        case clearConfirmed
        case clearCancelled
        case startTapped
        case startAnywayTapped
        case puzzleProblemDismissed
        /// A tap outside the board and pad.
        case backgroundTapped
        case backToMenuTapped
        case viewBoardTapped
        case delegate(Delegate)

        /// Things the game asks its parent to do.
        enum Delegate: Equatable {
            case backToMenu
        }
    }

    let gameRepository: GameRepository

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .squareTapped(position):
            // Starting numbers can't be changed, so their squares can't be selected either.
            guard !state.isSolved, !state.board.isGiven(row: position.row, column: position.column) else {
                return .none
            }
            // With a number picked, tapping a square where it fits places it there and clears the pick;
            // tapping a square where it doesn't fit does nothing.
            if let number = state.highlightedNumber, state.selection == nil {
                guard state.board.candidates(row: position.row, column: position.column).contains(number) else {
                    return .none
                }
                state.highlightedNumber = nil
                return apply(&state) { $0.setValue(number, row: position.row, column: position.column) }
            }
            state.selection = state.selection == position ? nil : position
            return .none

        case let .numberTapped(number):
            // With a square selected, fill it in and deselect it. Otherwise pick (or un-pick) the number.
            guard let selection = state.selection else {
                state.highlightedNumber = state.highlightedNumber == number ? nil : number
                return .none
            }
            state.selection = nil
            return apply(&state) { $0.setValue(number, row: selection.row, column: selection.column) }

        case .eraseTapped:
            // Erasing keeps the square selected, so another number can go straight in.
            guard let selection = state.selection else { return .none }
            return apply(&state) { $0.setValue(0, row: selection.row, column: selection.column) }

        case .undoTapped:
            guard let previous = state.history.popLast() else { return .none }
            state.board = previous
            return save(state)

        case .clearTapped:
            state.isConfirmingClear = true
            return .none

        case .clearConfirmed:
            state.isConfirmingClear = false
            let mode = state.mode
            return apply(&state) { board in
                if mode == .setup {
                    board = SudokuBoard()
                } else {
                    board.clearPlayerEntries()
                }
            }

        case .clearCancelled:
            state.isConfirmingClear = false
            return .none

        case .startTapped:
            // Start right away only if the puzzle has exactly one solution; otherwise explain first.
            switch SudokuSolver.solutionCount(of: state.board, limit: 2) {
            case 0:
                state.puzzleProblem = .noSolution
                return .none
            case 1:
                return startGame(&state)
            default:
                state.puzzleProblem = .severalSolutions
                return .none
            }

        case .startAnywayTapped:
            state.puzzleProblem = nil
            return startGame(&state)

        case .puzzleProblemDismissed:
            state.puzzleProblem = nil
            return .none

        case .backgroundTapped:
            state.selection = nil
            state.highlightedNumber = nil
            return .none

        case .backToMenuTapped:
            return .send(.delegate(.backToMenu))

        case .viewBoardTapped:
            state.showsSuccess = false
            return .none

        case .delegate:
            return .none
        }
    }

    /// Changes the board, remembering the previous version so it can be undone, then checks for a win and saves.
    private func apply(_ state: inout State, _ change: (inout SudokuBoard) -> Void) -> Effect<Action> {
        var updated = state.board
        change(&updated)
        guard updated != state.board else { return .none }
        state.history.append(state.board)
        if state.history.count > 500 { state.history.removeFirst() }
        state.board = updated

        // A number that is on the board nine times has nowhere left to go.
        if let number = state.highlightedNumber, updated.completedNumbers.contains(number) {
            state.highlightedNumber = nil
        }

        // Once every square is filled in without clashes the puzzle is solved. A solved game is removed
        // from storage, so Continue doesn't reopen a finished puzzle.
        if state.mode == .play, updated.isComplete {
            state.isSolved = true
            state.showsSuccess = true
            state.selection = nil
            state.highlightedNumber = nil
            guard state.savesProgress else { return .none }
            return .run { [gameRepository] _ in gameRepository.clear() }
        }
        return save(state)
    }

    /// Locks the typed-in numbers as the puzzle's starting numbers and begins playing.
    private func startGame(_ state: inout State) -> Effect<Action> {
        state.board.lockNumbersAsGivens()
        state.mode = .play
        state.selection = nil
        state.highlightedNumber = nil
        // Typing in the puzzle can't be undone once the game has started.
        state.history = []
        return save(state)
    }

    /// A puzzle that is still being typed in is never saved, so it can't overwrite the saved game.
    private func save(_ state: State) -> Effect<Action> {
        guard state.mode == .play, state.savesProgress, !state.isSolved else { return .none }
        let board = state.board
        return .run { [gameRepository] _ in gameRepository.save(board) }
    }
}

extension GameFeature.PuzzleProblem {
    var title: String {
        switch self {
        case .noSolution: "This Puzzle Can't Be Solved"
        case .severalSolutions: "This Puzzle Has More Than One Solution"
        }
    }

    var message: String {
        switch self {
        case .noSolution:
            "Some of the numbers you typed in can't all be right at once. Check them against your puzzle."
        case .severalSolutions:
            "A number may be missing. You can still play it, but the hints may not lead to one answer."
        }
    }
}
