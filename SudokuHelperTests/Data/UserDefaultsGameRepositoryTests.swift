//
//  UserDefaultsGameRepositoryTests.swift
//  SudokuHelperTests
//

import Foundation
import Testing
@testable import SudokuHelper
@MainActor
struct UserDefaultsGameRepositoryTests {

    @Test func savedGameComesBackWithItsLockedNumbers() throws {
        let suite = "UserDefaultsGameRepositoryTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsGameRepository(defaults: defaults)

        var board = SudokuBoard.sample
        board.setValue(8, row: 0, column: 0)
        repository.save(board)

        let loaded = try #require(repository.load())
        #expect(loaded == board)
        #expect(loaded.isGiven(row: 0, column: 1))
        #expect(!loaded.isGiven(row: 0, column: 0))

        repository.clear()
        #expect(repository.load() == nil)
    }
}
