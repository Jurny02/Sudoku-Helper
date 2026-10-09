//
//  InMemoryRepositories.swift
//  SudokuHelper
//

import Foundation

/// Keeps the game only in memory, for previews and tests, so they never touch the real saved game.
final class InMemoryGameRepository: GameRepository {
    private(set) var savedBoard: SudokuBoard?
    /// How many times `save` was called, so tests can check that nothing was saved.
    private(set) var saveCount = 0

    init(savedBoard: SudokuBoard? = nil) {
        self.savedBoard = savedBoard
    }

    func load() -> SudokuBoard? { savedBoard }

    func save(_ board: SudokuBoard) {
        savedBoard = board
        saveCount += 1
    }

    func clear() { savedBoard = nil }
}

/// Settings kept only in memory, for previews and tests.
final class InMemoryAppSettings: AppSettings {
    var hasSeenOnboarding: Bool

    init(hasSeenOnboarding: Bool = false) {
        self.hasSeenOnboarding = hasSeenOnboarding
    }
}
