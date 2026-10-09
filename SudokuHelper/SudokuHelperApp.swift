//
//  SudokuHelperApp.swift
//  SudokuHelper
//
//  Created by Bartosz Jurczyk on 29/09/2026.
//

import SwiftUI

/// The composition root: the one place that picks the real storage and builds the root store.
@main
struct SudokuHelperApp: App {
    private let dependencies: AppDependencies
    @State private var store: Store<AppFeature.State, AppFeature.Action>

    init() {
        let dependencies = AppDependencies.live
        self.dependencies = dependencies
        _store = State(initialValue: Store(
            initialState: AppFeature.State(),
            reducer: AppFeature(gameRepository: dependencies.gameRepository, settings: dependencies.settings)
        ))
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store, dependencies: dependencies)
        }
    }
}
