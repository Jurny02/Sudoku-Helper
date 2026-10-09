//
//  TimeSource.swift
//  SudokuHelper
//

import Foundation

/// The current time, waiting and timing, passed in so tests can run instantly with a fixed clock.
struct TimeSource {
    var now: () -> Date
    var sleep: (Duration) async -> Void
    /// How long `work` takes to run.
    var measure: (_ work: () -> Void) -> Duration

    static let live = TimeSource(
        now: { Date() },
        sleep: { duration in try? await Task.sleep(for: duration) },
        measure: { work in ContinuousClock().measure(work) }
    )
}
