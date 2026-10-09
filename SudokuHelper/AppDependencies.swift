//
//  AppDependencies.swift
//  SudokuHelper
//

import Foundation

/// Everything the features need from the outside world, created once at launch and passed down.
/// Swapping these out is how previews and tests run without touching real storage.
struct AppDependencies {
    let gameRepository: GameRepository
    let settings: AppSettings
    let time: TimeSource

    static let live = AppDependencies(
        gameRepository: UserDefaultsGameRepository(),
        settings: UserDefaultsAppSettings(),
        time: .live
    )

    static var preview: AppDependencies {
        AppDependencies(
            gameRepository: InMemoryGameRepository(),
            settings: InMemoryAppSettings(hasSeenOnboarding: true),
            time: .live
        )
    }
}
