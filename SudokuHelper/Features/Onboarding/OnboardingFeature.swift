//
//  OnboardingFeature.swift
//  SudokuHelper
//

import Foundation

/// The swipeable introduction. It asks its parent to close it when the player skips or taps Get Started;
/// the app feature then remembers that it has been seen.
struct OnboardingFeature: Reducer {
    struct State: Equatable {
        var page = 0

        var isLastPage: Bool { page == OnboardingPage.all.count - 1 }
    }

    enum Action: Equatable {
        case pageChanged(Int)
        case nextTapped
        case skipTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case finished
        }
    }

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .pageChanged(page):
            state.page = page
            return .none

        case .nextTapped:
            guard state.isLastPage else {
                state.page += 1
                return .none
            }
            return .send(.delegate(.finished))

        case .skipTapped:
            return .send(.delegate(.finished))

        case .delegate:
            return .none
        }
    }
}

/// One page of the introduction: text on top and a picture, example board or colour guide below.
struct OnboardingPage: Equatable {
    let title: String
    let text: String
    var symbol: String? = nil
    /// A small copy of the game screen shown under the text.
    var example: ExampleBoard.Example? = nil
    /// Shows the guide to the number-mode colours under the text.
    var showsColorGuide = false

    static let all: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Sudoku Helper",
            text: "Type in any Sudoku puzzle and the app shows you where each number can still go.",
            symbol: "square.grid.3x3.fill"
        ),
        OnboardingPage(
            title: "Enter Your Puzzle",
            text: "Tap New Game and type in the puzzle's starting numbers. Tap Start and they're locked, so you can't change them by accident.",
            example: .typingIn
        ),
        OnboardingPage(
            title: "Fill In a Square",
            text: "Tap a square to select it. Only the numbers that fit its row, column and box stay active on the pad.",
            example: .square(SudokuPosition(row: 4, column: 3))
        ),
        OnboardingPage(
            title: "Find Where a Number Goes",
            text: "With no square selected, tap a number. The board shows where it can go, then tap a square to place it.",
            example: .number(2)
        ),
        OnboardingPage(
            title: "What the Colours Mean",
            text: "After you pick a number, every square gets a colour.",
            showsColorGuide: true
        ),
        OnboardingPage(
            title: "Undo and Autosave",
            text: "Made a mistake? Tap undo to take back your last change. Your game is saved after every move, so tap Continue to pick up where you left off.",
            symbol: "arrow.uturn.backward.circle.fill"
        ),
    ]
}
