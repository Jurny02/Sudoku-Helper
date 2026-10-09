//
//  UserDefaultsGameRepository.swift
//  SudokuHelper
//

import Foundation

/// Stores the game in progress as JSON in UserDefaults.
final class UserDefaultsGameRepository: GameRepository {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "savedGame") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> SudokuBoard? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SudokuBoard.self, from: data)
    }

    func save(_ board: SudokuBoard) {
        guard let data = try? JSONEncoder().encode(board) else { return }
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

/// Keeps the app's settings in UserDefaults.
final class UserDefaultsAppSettings: AppSettings {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var hasSeenOnboarding: Bool {
        get { defaults.bool(forKey: "hasSeenOnboarding") }
        set { defaults.set(newValue, forKey: "hasSeenOnboarding") }
    }
}
