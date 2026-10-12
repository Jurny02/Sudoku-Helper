//
//  Store.swift
//  SudokuHelper
//

import Observation
import SwiftUI

/// Holds a feature's state, runs its reducer for every action and starts the returned effects.
/// Views read `state` and call `send`; SwiftUI redraws when the state they read changes.
@MainActor
@Observable
final class Store<State, Action> {
    private(set) var state: State
    @ObservationIgnored private let reduce: (inout State, Action) -> Effect<Action>
    /// Sees every action after the reducer has run. A parent uses it to react to its child's delegate actions.
    @ObservationIgnored private let onAction: ((Action) -> Void)?

    init<R: Reducer>(
        initialState: State,
        reducer: R,
        onAction: ((Action) -> Void)? = nil
    ) where R.State == State, R.Action == Action {
        self.state = initialState
        self.reduce = reducer.reduce(into:action:)
        self.onAction = onAction
    }

    func send(_ action: Action) {
        let effect = reduce(&state, action)
        onAction?(action)
        for operation in effect.operations {
            Task { [weak self] in
                await operation { action in self?.send(action) }
            }
        }
    }

    /// Sends the action inside a SwiftUI animation.
    func send(_ action: Action, animation: Animation?) {
        withAnimation(animation) { send(action) }
    }

    /// A binding that reads from the state and sends an action when SwiftUI writes to it.
    func binding<Value>(_ keyPath: KeyPath<State, Value>, send action: @escaping (Value) -> Action) -> Binding<Value> {
        Binding(
            get: { self.state[keyPath: keyPath] },
            set: { self.send(action($0)) }
        )
    }
}
