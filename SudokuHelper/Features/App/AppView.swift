//
//  AppView.swift
//  SudokuHelper
//
//  Created by Bartosz Jurczyk on 29/09/2026.
//

import SwiftUI

/// The main menu: continue the saved game, start a new puzzle, try the example, or read how to play.
struct AppView: View {
    let store: Store<AppFeature.State, AppFeature.Action>
    let dependencies: AppDependencies

    var body: some View {
        NavigationStack(path: store.binding(\.path, send: AppFeature.Action.pathChanged)) {
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.tint)

                Text("Sudoku Helper")
                    .font(.largeTitle.bold())

                Spacer()

                Button {
                    store.send(.continueTapped)
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!store.state.hasSavedGame)

                Button {
                    store.send(.newGameTapped)
                } label: {
                    Text("New Game")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)

                Button {
                    store.send(.exampleGameTapped)
                } label: {
                    Text("Example Game")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)

                HStack(spacing: 24) {
                    Button("How to Play", systemImage: "questionmark.circle") {
                        store.send(.howToPlayTapped)
                    }
                    Button("Watch It Solve", systemImage: "play.circle") {
                        store.send(.watchItSolveTapped)
                    }
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(.horizontal, 32)
            .onAppear { store.send(.onAppear) }
            .fullScreenCover(isPresented: store.binding(\.isShowingOnboarding) { $0 ? .howToPlayTapped : .onboarding(.finished) }) {
                OnboardingScreen { store.send(.onboarding($0)) }
            }
            .navigationDestination(for: AppFeature.Route.self) { route in
                switch route.destination {
                case let .game(game):
                    GameScreen(game: game, gameRepository: dependencies.gameRepository) { delegate in
                        store.send(.game(id: route.id, delegate))
                    }
                case .solverDemo:
                    SolverDemoScreen(time: dependencies.time)
                }
            }
        }
    }
}

/// Owns the store for one pushed game, so it lives exactly as long as the screen.
private struct GameScreen: View {
    @State private var store: Store<GameFeature.State, GameFeature.Action>

    init(game: GameFeature.State, gameRepository: GameRepository, onDelegate: @escaping (GameFeature.Action.Delegate) -> Void) {
        _store = State(initialValue: Store(
            initialState: game,
            reducer: GameFeature(gameRepository: gameRepository),
            onAction: { action in
                if case let .delegate(delegate) = action { onDelegate(delegate) }
            }
        ))
    }

    var body: some View {
        GameView(store: store)
    }
}

/// Owns the store for the solver demo while it's on screen.
private struct SolverDemoScreen: View {
    @State private var store: Store<SolverDemoFeature.State, SolverDemoFeature.Action>

    init(time: TimeSource) {
        _store = State(initialValue: Store(initialState: SolverDemoFeature.State(), reducer: SolverDemoFeature(time: time)))
    }

    var body: some View {
        SolverDemoView(store: store)
    }
}

/// Owns the store for the introduction while it's on screen.
private struct OnboardingScreen: View {
    @State private var store: Store<OnboardingFeature.State, OnboardingFeature.Action>

    init(onDelegate: @escaping (OnboardingFeature.Action.Delegate) -> Void) {
        _store = State(initialValue: Store(
            initialState: OnboardingFeature.State(),
            reducer: OnboardingFeature(),
            onAction: { action in
                if case let .delegate(delegate) = action { onDelegate(delegate) }
            }
        ))
    }

    var body: some View {
        OnboardingView(store: store)
    }
}

#Preview {
    let dependencies = AppDependencies.preview
    AppView(
        store: Store(
            initialState: AppFeature.State(),
            reducer: AppFeature(gameRepository: dependencies.gameRepository, settings: dependencies.settings)
        ),
        dependencies: dependencies
    )
}
