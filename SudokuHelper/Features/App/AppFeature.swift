//
//  AppFeature.swift
//  SudokuHelper
//

import Foundation

/// The root of the app: the main menu, the stack of game screens on top of it, and the onboarding.
struct AppFeature: Reducer {
    /// A game screen pushed on top of the menu. Each push gets its own id, so two games are never confused.
    struct Route: Hashable, Identifiable {
        let id: Int
        let game: GameFeature.State

        static func == (lhs: Route, rhs: Route) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    struct State: Equatable {
        var path: [Route] = []
        /// Whether Continue has a game to open.
        var hasSavedGame = false
        var isShowingOnboarding = false
        var nextRouteID = 0
    }

    enum Action: Equatable {
        case onAppear
        case continueTapped
        case newGameTapped
        case exampleGameTapped
        case howToPlayTapped
        /// SwiftUI changed the navigation path, e.g. the back button was tapped.
        case pathChanged([Route])
        case game(id: Route.ID, GameFeature.Action.Delegate)
        case onboarding(OnboardingFeature.Action.Delegate)
    }

    let gameRepository: GameRepository
    let settings: AppSettings

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .onAppear:
            state.hasSavedGame = gameRepository.load() != nil
            // The introduction opens by itself only on the very first launch.
            if !settings.hasSeenOnboarding {
                state.isShowingOnboarding = true
            }
            return .none

        case .continueTapped:
            guard let board = gameRepository.load() else {
                state.hasSavedGame = false
                return .none
            }
            push(GameFeature.State(board: board, mode: .play), on: &state)
            return .none

        case .newGameTapped:
            push(GameFeature.State(board: SudokuBoard(), mode: .setup), on: &state)
            return .none

        case .exampleGameTapped:
            // The example is never saved, so it can't replace the player's own game.
            push(GameFeature.State(board: .sample, mode: .play, savesProgress: false), on: &state)
            return .none

        case .howToPlayTapped:
            state.isShowingOnboarding = true
            return .none

        case let .pathChanged(path):
            let wentBack = path.count < state.path.count
            state.path = path
            if wentBack { refreshSavedGame(&state) }
            return .none

        case let .game(id, .backToMenu):
            if let index = state.path.firstIndex(where: { $0.id == id }) {
                state.path.removeSubrange(index...)
            }
            refreshSavedGame(&state)
            return .none

        case .onboarding(.finished):
            state.isShowingOnboarding = false
            return .run { [settings] _ in settings.hasSeenOnboarding = true }
        }
    }

    private func push(_ game: GameFeature.State, on state: inout State) {
        state.path.append(Route(id: state.nextRouteID, game: game))
        state.nextRouteID += 1
    }

    /// Back on the menu, a game may have been saved, started or finished in the meantime.
    private func refreshSavedGame(_ state: inout State) {
        state.hasSavedGame = gameRepository.load() != nil
    }
}
