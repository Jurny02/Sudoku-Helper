//
//  SolverDemoFeatureTests.swift
//  SudokuHelperTests
//

import Foundation
import Testing
@testable import SudokuHelper

@MainActor
struct SolverDemoFeatureTests {
    /// A clock that only moves when the test says so, and doesn't really wait.
    final class TestClock {
        var now = Date(timeIntervalSince1970: 0)
        var sleeps: [Duration] = []

        var timeSource: TimeSource {
            TimeSource(
                now: { self.now },
                sleep: { self.sleeps.append($0) },
                measure: { work in work(); return .milliseconds(5) }
            )
        }
    }

    let clock = TestClock()
    var feature: SolverDemoFeature { SolverDemoFeature(time: clock.timeSource) }

    @Test func playStepsThroughThePuzzleAtTheChosenSpeed() async {
        var state = SolverDemoFeature.State()
        await feature.send(.stepDelayChanged(0.5), to: &state)

        let sent = await feature.send(.playTapped, to: &state)
        #expect(state.isRunning)
        #expect(clock.sleeps == [.seconds(0.5)])
        #expect(sent == [.stepTimerFired(runID: state.runID)])

        await feature.send(sent[0], to: &state)
        #expect(state.progress.steps == 1)
        #expect(state.lastStep != nil)
    }

    @Test func pauseStopsTheClockAndIgnoresTheStepAlreadyScheduled() async {
        var state = SolverDemoFeature.State()
        let scheduled = await feature.send(.playTapped, to: &state)

        clock.now += 2
        await feature.send(.pauseTapped, to: &state)
        #expect(!state.isRunning)
        #expect(state.elapsed(at: clock.now + 10) == 2)

        await feature.send(scheduled[0], to: &state)
        #expect(state.progress.steps == 0)
    }

    @Test func runningToTheEndSolvesTheExample() async {
        var state = SolverDemoFeature.State()
        var next = await feature.send(.playTapped, to: &state)
        while let action = next.first {
            next = await feature.send(action, to: &state)
        }
        #expect(state.outcome == .solved)
        #expect(!state.isRunning)
        #expect(state.status.hasPrefix("Solved!"))
    }

    @Test func runInstantlyFinishesAndShowsHowLongItTook() async {
        var state = SolverDemoFeature.State()
        await feature.send(.runInstantlyTapped, to: &state)
        #expect(state.outcome == .solved)
        #expect(state.instantDuration == .milliseconds(5))
        #expect(state.progress.filled == 52)
    }

    @Test func resetPutsTheStartingBoardBackButKeepsTheSpeed() async {
        var state = SolverDemoFeature.State()
        await feature.send(.stepDelayChanged(0.1), to: &state)
        await feature.send(.runInstantlyTapped, to: &state)

        await feature.send(.resetTapped, to: &state)
        #expect(state.board == .sample)
        #expect(state.progress == SimpleSolver.Progress())
        #expect(state.stepDelay == 0.1)
        #expect(state.instantDuration == nil)
    }

    @Test func aPuzzleTheMethodCannotFinishSaysSo() async {
        var state = SolverDemoFeature.State(startBoard: SudokuBoard(), board: SudokuBoard())
        await feature.send(.runInstantlyTapped, to: &state)
        #expect(state.outcome == .stuck)
        #expect(state.status.contains("can't finish"))
    }
}
