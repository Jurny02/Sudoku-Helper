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
            menu
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

    /// Liquid Glass buttons floating over a soft, colourful backdrop that the glass picks up.
    private var menu: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .frame(width: 112, height: 112)
                .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 32))

            Text("Sudoku Helper")
                .font(.largeTitle.bold())
                .padding(.top, 8)

            Spacer()

            GlassEffectContainer(spacing: 16) {
                VStack(spacing: 14) {
                    // The tinted button is the one most likely wanted: Continue when there's a saved game,
                    // otherwise New Game.
                    menuButton("Continue", systemImage: "play.fill", prominent: store.state.hasSavedGame) {
                        store.send(.continueTapped)
                    }
                    .disabled(!store.state.hasSavedGame)

                    menuButton("New Game", systemImage: "square.and.pencil", prominent: !store.state.hasSavedGame) {
                        store.send(.newGameTapped)
                    }

                    menuButton("Example Game", systemImage: "square.grid.3x3") {
                        store.send(.exampleGameTapped)
                    }

                    HStack(spacing: 14) {
                        Button {
                            store.send(.howToPlayTapped)
                        } label: {
                            Label("How to Play", systemImage: "questionmark.circle")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        Button {
                            store.send(.watchItSolveTapped)
                        } label: {
                            Label("Watch It Solve", systemImage: "play.circle")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                    }
                    .buttonStyle(GlassOutlineButtonStyle())
                }
            }

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { MenuBackdrop() }
    }

    private func menuButton(
        _ title: String,
        systemImage: String,
        prominent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        let button = Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 50)
                .contentShape(Capsule())
        }
        return Group {
            if prominent {
                button.buttonStyle(.glassProminent)
            } else {
                button.buttonStyle(GlassOutlineButtonStyle())
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

/// Soft blurred shapes in the app's colours (blue, mint and the hint yellow) behind the menu's glass.
private struct MenuBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                Color(.systemBackground)

                Circle()
                    .fill(Color.blue.opacity(0.55))
                    .frame(width: size.width * 0.9)
                    .offset(x: -size.width * 0.35, y: -size.height * 0.28)

                Circle()
                    .fill(Color.mint.opacity(0.45))
                    .frame(width: size.width * 0.8)
                    .offset(x: size.width * 0.4, y: size.height * 0.05)

                Circle()
                    .fill(Color(red: 1, green: 0.84, blue: 0.04).opacity(0.45))
                    .frame(width: size.width * 0.7)
                    .offset(x: -size.width * 0.25, y: size.height * 0.38)
            }
            .blur(radius: 70)
            .opacity(colorScheme == .dark ? 0.6 : 1)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}
