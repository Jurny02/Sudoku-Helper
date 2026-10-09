//
//  SolverDemoView.swift
//  SudokuHelper
//

import SwiftUI

/// Shows a `SolverDemoFeature`: the board being filled, the number being checked, the timer and the controls.
struct SolverDemoView: View {
    let store: Store<SolverDemoFeature.State, SolverDemoFeature.Action>

    private var state: SolverDemoFeature.State { store.state }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SudokuBoardView(
                    board: state.board,
                    selection: .constant(nil),
                    highlightedNumber: state.currentNumber,
                    onSquareTapped: { _ in }
                )
                .allowsHitTesting(false)

                NumberStrip(current: state.currentNumber)

                Text(state.status)
                    .font(.subheadline)
                    .foregroundStyle(state.outcome == .stuck ? Color.orange : Color.secondary)
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 40)

                stats

                speedSlider

                controls
            }
            .padding()
        }
        .navigationTitle("Watch It Solve")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.easeInOut(duration: 0.15), value: state.board)
    }

    private var stats: some View {
        HStack {
            stat(title: "Time") {
                if let duration = state.instantDuration {
                    Text(Self.format(duration))
                } else {
                    TimelineView(.periodic(from: .now, by: 0.1)) { context in
                        Text(Self.format(seconds: state.elapsed(at: context.date)))
                    }
                }
            }
            Divider().frame(height: 32)
            stat(title: "Placed") { Text("\(state.progress.filled)") }
            Divider().frame(height: 32)
            stat(title: "Checks") { Text("\(state.progress.steps)") }
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func stat<Value: View>(title: String, @ViewBuilder value: () -> Value) -> some View {
        VStack(spacing: 2) {
            value()
                .font(.title3.monospacedDigit().weight(.semibold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var speedSlider: some View {
        HStack(spacing: 12) {
            Image(systemName: "tortoise.fill")
                .foregroundStyle(.secondary)
            // The slider runs from slow (left) to fast (right), so it moves against the step delay.
            Slider(
                value: store.binding(\.stepDelay.speed) { .stepDelayChanged(Double.delay(forSpeed: $0)) },
                in: 0...1
            )
            .accessibilityLabel("Speed")
            Image(systemName: "hare.fill")
                .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                store.send(.resetTapped)
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .disabled(!state.isRunning && state.progress.steps == 0 && state.instantDuration == nil)

            Button {
                store.send(state.isRunning ? .pauseTapped : .playTapped)
            } label: {
                Label(state.isRunning ? "Pause" : "Play", systemImage: state.isRunning ? "pause.fill" : "play.fill")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(state.isFinished)

            Button {
                store.send(.runInstantlyTapped)
            } label: {
                Label("Instant", systemImage: "bolt.fill")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .disabled(state.isRunning)
        }
        .labelStyle(.titleAndIcon)
        .font(.subheadline.weight(.semibold))
    }

    /// Short runs in milliseconds, longer ones in seconds.
    static func format(_ duration: Duration) -> String {
        let seconds = duration.timeInterval
        return seconds < 1 ? String(format: "%.2f ms", seconds * 1000) : format(seconds: seconds)
    }

    static func format(seconds: TimeInterval) -> String {
        String(format: "%.1f s", seconds)
    }
}

/// The numbers 1–9 in a row, with the one being checked filled in.
private struct NumberStrip: View {
    let current: Int?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...9, id: \.self) { number in
                Text("\(number)")
                    .font(.headline)
                    .foregroundStyle(number == current ? Color.white : Color.accentColor)
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .background(number == current ? Color.accentColor : Color(.systemGray6), in: Circle())
            }
        }
        .animation(.easeInOut(duration: 0.1), value: current)
        .accessibilityElement()
        .accessibilityLabel(current.map { "Checking \($0)" } ?? "Not running")
    }
}

private extension Double {
    /// Maps a step delay to 0 (slowest) ... 1 (fastest) for the slider.
    var speed: Double {
        let range = SolverDemoFeature.State.stepDelayRange
        return 1 - (self - range.lowerBound) / (range.upperBound - range.lowerBound)
    }

    static func delay(forSpeed speed: Double) -> Double {
        let range = SolverDemoFeature.State.stepDelayRange
        return range.upperBound - speed * (range.upperBound - range.lowerBound)
    }
}

#Preview {
    NavigationStack {
        SolverDemoView(store: Store(initialState: SolverDemoFeature.State(), reducer: SolverDemoFeature(time: .live)))
    }
}
