//
//  GameRepository.swift
//  SudokuHelper
//

import Foundation

/// Where the game in progress is kept. Features depend on this protocol only; the app passes in
/// `UserDefaultsGameRepository`, while tests and previews use `InMemoryGameRepository`.
protocol GameRepository: AnyObject {
    func load() -> SudokuBoard?
    func save(_ board: SudokuBoard)
    func clear()
}

/// Settings that outlive a single game.
protocol AppSettings: AnyObject {
    /// Whether the introduction has been seen, so it only opens by itself on the first launch.
    var hasSeenOnboarding: Bool { get set }
}
