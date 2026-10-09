//
//  SolverDemoFeature.swift
//  SudokuHelper
//

import Foundation

/// Shows `SimpleSolver` working through the example puzzle step by step, with play/pause,
/// a speed slider and a timer, or all at once with the time it took.
struct SolverDemoFeature: Reducer {
    struct State: Equatable {
        var startBoard: SudokuBoard = .sample
        var board: SudokuBoard = .sample
        var progress = SimpleSolver.Progress()
        var outcome = SimpleSolver.Outcome.running
        var lastStep: SimpleSolver.Step?
        var isRunning = false
        /// Seconds between steps. Smaller is faster.
        var stepDelay: Double = 0.3
        /// Time spent running before the current stretch (pausing stops the clock).
        var elapsedBeforeCurrentRun: TimeInterval = 0
        /// When the current stretch started, while running.
        var runStartedAt: Date?
        /// How long "Run Instantly" took, when it was used.
        var instantDuration: Duration?
        /// Changes every time a run starts or stops, so a step scheduled by an earlier run is ignored.
        var runID = 0

        static let stepDelayRange: ClosedRange<Double> = 0.02...1.0

        var isFinished: Bool { outcome != .running }

        /// The number the solver checks next, shown picked on the pad and coloured on the board,
        /// so you can see its yellow squares before one gets filled.
        var currentNumber: Int? {
            guard !isFinished, isRunning || lastStep != nil else { return nil }
            return progress.number
        }

        /// The time to show, given the current time.
        func elapsed(at now: Date) -> TimeInterval {
            elapsedBeforeCurrentRun + (runStartedAt.map { now.timeIntervalSince($0) } ?? 0)
        }

        var status: String {
            switch outcome {
            case .solved:
                return "Solved! \(progress.filled) numbers placed in \(progress.steps) checks."
            case .stuck:
                return "Stuck after \(progress.filled) numbers. This simple method can't finish the puzzle."
            case .running:
                switch lastStep {
                case let .placed(number, position)?:
                    return "Placed \(number) in row \(position.row + 1), column \(position.column + 1)."
                case let .nothingFor(number)?:
                    return "No yellow square for \(number), trying the next number."
                case nil:
                    return "Tap Play to watch the puzzle get solved one yellow square at a time."
                }
            }
        }
    }

    enum Action: Equatable {
        case playTapped
        case pauseTapped
        case resetTapped
        case runInstantlyTapped
        case stepDelayChanged(Double)
        case stepTimerFired(runID: Int)
    }

    let time: TimeSource

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .playTapped:
            guard !state.isRunning, !state.isFinished else { return .none }
            state.isRunning = true
            state.instantDuration = nil
            state.runStartedAt = time.now()
            state.runID += 1
            return scheduleStep(state)

        case .pauseTapped:
            guard state.isRunning else { return .none }
            stopClock(&state)
            return .none

        case .resetTapped:
            state = State(startBoard: state.startBoard, board: state.startBoard, stepDelay: state.stepDelay, runID: state.runID + 1)
            return .none

        case .runInstantlyTapped:
            var result: (board: SudokuBoard, progress: SimpleSolver.Progress, outcome: SimpleSolver.Outcome)?
            let startBoard = state.startBoard
            let duration = time.measure { result = SimpleSolver.run(startBoard) }
            guard let result else { return .none }
            state = State(startBoard: startBoard, board: result.board, stepDelay: state.stepDelay, runID: state.runID + 1)
            state.progress = result.progress
            state.outcome = result.outcome
            state.instantDuration = duration
            state.elapsedBeforeCurrentRun = duration.timeInterval
            return .none

        case let .stepDelayChanged(delay):
            state.stepDelay = min(max(delay, State.stepDelayRange.lowerBound), State.stepDelayRange.upperBound)
            return .none

        case let .stepTimerFired(runID):
            // A step from a run that was paused or reset in the meantime.
            guard state.isRunning, runID == state.runID else { return .none }
            state.lastStep = SimpleSolver.step(&state.board, &state.progress)
            state.outcome = SimpleSolver.outcome(of: state.board, state.progress)
            if state.isFinished {
                stopClock(&state)
                return .none
            }
            return scheduleStep(state)
        }
    }

    private func scheduleStep(_ state: State) -> Effect<Action> {
        let runID = state.runID
        let delay = Duration.seconds(state.stepDelay)
        return .run { [time] send in
            await time.sleep(delay)
            send(.stepTimerFired(runID: runID))
        }
    }

    private func stopClock(_ state: inout State) {
        state.elapsedBeforeCurrentRun = state.elapsed(at: time.now())
        state.runStartedAt = nil
        state.isRunning = false
        state.runID += 1
    }
}

extension Duration {
    var timeInterval: TimeInterval {
        let (seconds, attoseconds) = components
        return TimeInterval(seconds) + TimeInterval(attoseconds) / 1e18
    }
}
