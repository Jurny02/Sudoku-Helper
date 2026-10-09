//
//  ReducerTestHelpers.swift
//  SudokuHelperTests
//

@testable import SudokuHelper

@MainActor
extension Effect {
    /// Runs the effect and returns the actions it sent back, in order.
    func actions() async -> [Action] {
        var sent: [Action] = []
        for operation in operations {
            await operation { sent.append($0) }
        }
        return sent
    }
}

@MainActor
extension Reducer {
    /// Sends `action`, runs its effect, and returns the actions the effect sent back.
    @discardableResult
    func send(_ action: Action, to state: inout State) async -> [Action] {
        await reduce(into: &state, action: action).actions()
    }
}
