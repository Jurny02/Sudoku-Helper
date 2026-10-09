//
//  GameFeatureTests.swift
//  SudokuHelperTests
//

import Testing
@testable import SudokuHelper
@MainActor
struct GameFeatureTests {
    /// The example puzzle's top-left square is empty and can take 2, 3, 7 or 8 (the solution is 8).
    let topLeft = SudokuPosition(row: 0, column: 0)
    let repository = InMemoryGameRepository()
    var feature: GameFeature { GameFeature(gameRepository: repository) }

    @Test func selectingASquareThenANumberPlacesItAndDeselects() async {
        var state = GameFeature.State(board: .sample, mode: .play)

        await feature.send(.squareTapped(topLeft), to: &state)
        #expect(state.selection == topLeft)

        await feature.send(.numberTapped(8), to: &state)
        #expect(state.selection == nil)
        #expect(state.board[0, 0] == 8)
        #expect(state.history == [.sample])
        #expect(repository.savedBoard?[0, 0] == 8)
    }

    @Test func pickingANumberThenTappingASquareWhereItFitsPlacesIt() async {
        var state = GameFeature.State(board: .sample, mode: .play)

        await feature.send(.numberTapped(8), to: &state)
        #expect(state.highlightedNumber == 8)

        await feature.send(.squareTapped(topLeft), to: &state)
        #expect(state.highlightedNumber == nil)
        #expect(state.board[0, 0] == 8)
    }

    @Test func tappingASquareWhereThePickedNumberDoesNotFitDoesNothing() async {
        var state = GameFeature.State(board: .sample, mode: .play)
        await feature.send(.numberTapped(9), to: &state)
        let before = state

        // Row 1 already has a 9.
        await feature.send(.squareTapped(topLeft), to: &state)
        #expect(state == before)
        #expect(repository.saveCount == 0)
    }

    @Test func startingNumbersCannotBeSelected() async {
        var state = GameFeature.State(board: .sample, mode: .play)
        await feature.send(.squareTapped(SudokuPosition(row: 0, column: 1)), to: &state)
        #expect(state.selection == nil)
    }

    @Test func undoPutsTheBoardBack() async {
        var state = GameFeature.State(board: .sample, mode: .play)
        await feature.send(.squareTapped(topLeft), to: &state)
        await feature.send(.numberTapped(8), to: &state)

        await feature.send(.undoTapped, to: &state)
        #expect(state.board == .sample)
        #expect(state.history.isEmpty)
        #expect(repository.savedBoard == .sample)
    }

    @Test func theExampleGameIsNeverSaved() async {
        var state = GameFeature.State(board: .sample, mode: .play, savesProgress: false)
        await feature.send(.squareTapped(topLeft), to: &state)
        await feature.send(.numberTapped(8), to: &state)

        #expect(state.board[0, 0] == 8)
        #expect(repository.saveCount == 0)
    }

    @Test func aPuzzleBeingTypedInIsNeverSaved() async {
        var state = GameFeature.State(board: SudokuBoard(), mode: .setup)
        await feature.send(.squareTapped(topLeft), to: &state)
        await feature.send(.numberTapped(5), to: &state)

        #expect(state.board[0, 0] == 5)
        #expect(repository.saveCount == 0)
    }

    @Test func startingAPuzzleWithSeveralSolutionsAsksFirst() async throws {
        let board = try #require(SudokuBoard(string: "5" + String(repeating: ".", count: 80)))
        var state = GameFeature.State(board: board, mode: .setup)

        await feature.send(.startTapped, to: &state)
        #expect(state.puzzleProblem == .severalSolutions)
        #expect(state.mode == .setup)

        await feature.send(.startAnywayTapped, to: &state)
        #expect(state.puzzleProblem == nil)
        #expect(state.mode == .play)
        #expect(state.board.isGiven(row: 0, column: 0))
        #expect(repository.savedBoard == state.board)
    }

    @Test func startingAPuzzleWithNoSolutionExplainsWhy() async throws {
        let board = try #require(SudokuBoard(string:
            ".12345678" + "........." + "........." + "9........" + String(repeating: ".", count: 45)))
        var state = GameFeature.State(board: board, mode: .setup)

        await feature.send(.startTapped, to: &state)
        #expect(state.puzzleProblem == .noSolution)
        #expect(state.mode == .setup)
    }

    @Test func startingTheExamplePuzzleStartsStraightAway() async {
        var state = GameFeature.State(board: .sample, mode: .setup)
        await feature.send(.startTapped, to: &state)
        #expect(state.puzzleProblem == nil)
        #expect(state.mode == .play)
    }

    @Test func fillingTheLastSquareShowsSuccessAndClearsTheSave() async throws {
        let solution = TestPuzzles.sampleSolution
        // The solution with the top-left 8 removed, everything else locked.
        var board = try #require(SudokuBoard(string: "." + solution.dropFirst()))
        board.lockNumbersAsGivens()
        repository.save(board)
        var state = GameFeature.State(board: board, mode: .play)

        await feature.send(.squareTapped(topLeft), to: &state)
        await feature.send(.numberTapped(8), to: &state)

        #expect(state.isSolved)
        #expect(state.showsSuccess)
        #expect(repository.savedBoard == nil)
        #expect(!state.canUndo)
        #expect(!state.isPadEnabled)
    }

    @Test func backToMenuAsksTheParent() async {
        var state = GameFeature.State(board: .sample, mode: .play)
        let sent = await feature.send(.backToMenuTapped, to: &state)
        #expect(sent == [.delegate(.backToMenu)])
    }

    @Test func clearingInSetupEmptiesTheBoardAfterConfirming() async throws {
        let board = try #require(SudokuBoard(string: "5" + String(repeating: ".", count: 80)))
        var state = GameFeature.State(board: board, mode: .setup)

        await feature.send(.clearTapped, to: &state)
        #expect(state.isConfirmingClear)
        #expect(state.board == board)

        await feature.send(.clearConfirmed, to: &state)
        #expect(!state.isConfirmingClear)
        #expect(state.board == SudokuBoard())
    }

    @Test func padOnlyOffersNumbersThatFitTheSelectedSquare() {
        var state = GameFeature.State(board: .sample, mode: .play)
        state.selection = topLeft
        #expect(state.allowedNumbers == [2, 3, 7, 8])
        #expect(state.isPadEnabled)
        #expect(!state.canErase)
    }
}
