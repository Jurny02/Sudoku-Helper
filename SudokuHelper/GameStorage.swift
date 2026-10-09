//
//  GameStorage.swift
//  SudokuHelper
//

import Foundation

/// Saves and loads the game in progress using UserDefaults.
enum GameStorage {
    private static let key = "savedGame"

    static var hasSavedGame: Bool {
        UserDefaults.standard.data(forKey: key) != nil
    }

    static func save(_ board: SudokuBoard) {
        guard let data = try? JSONEncoder().encode(board) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    static func load() -> SudokuBoard? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SudokuBoard.self, from: data)
    }
}
