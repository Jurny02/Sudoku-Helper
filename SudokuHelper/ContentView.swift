//
//  ContentView.swift
//  SudokuHelper
//
//  Created by Bartosz Jurczyk on 29/09/2026.
//

import SwiftUI

/// The main menu: continue the saved game, start a new puzzle, try the example, or read how to play.
struct ContentView: View {
    private enum Route: Hashable {
        case newGame
        case continueGame
        case exampleGame
    }

    @State private var path: [Route] = []
    @State private var hasSavedGame = GameStorage.hasSavedGame
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showsOnboarding = false

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.tint)

                Text("Sudoku Helper")
                    .font(.largeTitle.bold())

                Spacer()

                Button {
                    path.append(.continueGame)
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasSavedGame)

                Button {
                    path.append(.newGame)
                } label: {
                    Text("New Game")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)

                Button {
                    path.append(.exampleGame)
                } label: {
                    Text("Example Game")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.bordered)

                Button("How to Play", systemImage: "questionmark.circle") {
                    showsOnboarding = true
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(.horizontal, 32)
            .fullScreenCover(isPresented: $showsOnboarding) {
                OnboardingView {
                    hasSeenOnboarding = true
                    showsOnboarding = false
                }
            }
            .onAppear {
                if !hasSeenOnboarding { showsOnboarding = true }
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .newGame:
                    GameView(board: SudokuBoard(), mode: .setup)
                case .continueGame:
                    GameView(board: GameStorage.load() ?? SudokuBoard(), mode: .play)
                case .exampleGame:
                    // The example is never saved, so it can't replace the player's own game.
                    GameView(board: .sample, mode: .play, savesProgress: false)
                }
            }
            .onChange(of: path) {
                // Coming back to the menu, a game may have been saved in the meantime.
                if path.isEmpty { hasSavedGame = GameStorage.hasSavedGame }
            }
        }
    }
}

#Preview {
    ContentView()
}
