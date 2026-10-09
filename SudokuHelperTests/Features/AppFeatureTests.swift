//
//  AppFeatureTests.swift
//  SudokuHelperTests
//

import Testing
@testable import SudokuHelper
@MainActor
struct AppFeatureTests {
    let repository = InMemoryGameRepository()
    let settings = InMemoryAppSettings()
    var feature: AppFeature { AppFeature(gameRepository: repository, settings: settings) }

    @Test func firstLaunchShowsTheIntroductionAndRemembersIt() async {
        var state = AppFeature.State()

        await feature.send(.onAppear, to: &state)
        #expect(state.isShowingOnboarding)

        await feature.send(.onboarding(.finished), to: &state)
        #expect(!state.isShowingOnboarding)
        #expect(settings.hasSeenOnboarding)

        // On the next launch it stays closed.
        var nextLaunch = AppFeature.State()
        await feature.send(.onAppear, to: &nextLaunch)
        #expect(!nextLaunch.isShowingOnboarding)
    }

    @Test func continueOpensTheSavedGame() async {
        var saved = SudokuBoard.sample
        saved.setValue(8, row: 0, column: 0)
        repository.save(saved)
        var state = AppFeature.State()

        await feature.send(.onAppear, to: &state)
        #expect(state.hasSavedGame)

        await feature.send(.continueTapped, to: &state)
        #expect(state.path.map(\.destination) == [.game(GameFeature.State(board: saved, mode: .play))])
    }

    @Test func exampleGameOpensWithoutSaving() async {
        var state = AppFeature.State()
        await feature.send(.exampleGameTapped, to: &state)
        #expect(state.path.map(\.destination) == [.game(GameFeature.State(board: .sample, mode: .play, savesProgress: false))])
    }

    @Test func newGameOpensAnEmptyBoardForTypingIn() async {
        var state = AppFeature.State()
        await feature.send(.newGameTapped, to: &state)
        #expect(state.path.map(\.destination) == [.game(GameFeature.State(board: SudokuBoard(), mode: .setup))])
    }

    @Test func goingBackToTheMenuChecksForASavedGameAgain() async {
        var state = AppFeature.State()
        await feature.send(.newGameTapped, to: &state)
        #expect(!state.hasSavedGame)

        // The game was started and saved while it was open.
        repository.save(.sample)
        await feature.send(.pathChanged([]), to: &state)
        #expect(state.path.isEmpty)
        #expect(state.hasSavedGame)
    }

    @Test func backToMenuFromAGameClosesIt() async {
        var state = AppFeature.State()
        await feature.send(.exampleGameTapped, to: &state)
        let id = state.path[0].id

        await feature.send(.game(id: id, .backToMenu), to: &state)
        #expect(state.path.isEmpty)
    }

    @Test func onboardingNextGoesThroughThePagesThenFinishes() async {
        let onboarding = OnboardingFeature()
        var state = OnboardingFeature.State(page: OnboardingPage.all.count - 2)

        await onboarding.send(.nextTapped, to: &state)
        #expect(state.page == OnboardingPage.all.count - 1)

        let sent = await onboarding.send(.nextTapped, to: &state)
        #expect(sent == [.delegate(.finished)])
    }
}
