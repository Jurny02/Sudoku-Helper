//
//  Reducer.swift
//  SudokuHelper
//

import Foundation

/// A feature's logic in the style of The Composable Architecture: given the current state and an action,
/// change the state and describe any side effect to run. Reducers stay free of UI and are tested directly.
protocol Reducer<State, Action> {
    associatedtype State
    associatedtype Action

    func reduce(into state: inout State, action: Action) -> Effect<Action>
}

/// Work that runs after a reducer returns, such as saving. It can feed actions back into the store.
struct Effect<Action> {
    typealias Send = (Action) -> Void
    typealias Operation = (_ send: @escaping Send) async -> Void

    let operations: [Operation]

    /// No side effect.
    static var none: Effect { Effect(operations: []) }

    /// Runs `operation`; it may send further actions.
    static func run(_ operation: @escaping Operation) -> Effect {
        Effect(operations: [operation])
    }

    /// Sends another action straight away, e.g. a delegate action for the parent.
    static func send(_ action: Action) -> Effect {
        Effect(operations: [{ send in send(action) }])
    }

    static func merge(_ effects: Effect...) -> Effect {
        Effect(operations: effects.flatMap(\.operations))
    }
}
