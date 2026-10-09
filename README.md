<p align="center">
  <img src="SudokuHelper/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="120" alt="Sudoku Helper icon">
</p>

# Sudoku Helper

An iPhone app that helps you solve a Sudoku you're playing on paper or in another app.
Type in the puzzle, and the app shows which numbers can still go in each square and where each number must go.

## Features

- **Enter any puzzle.** Type in the starting numbers, then tap Start. The app checks that the puzzle has exactly one solution and locks the starting numbers.
- **Square mode.** Tap a square and the number pad only offers the numbers that fit its row, column and 3×3 box.
- **Number mode.** With no square selected, tap a number to colour the whole board for it:
  - yellow: the number must go here (it's the only one that fits, or the only place left in its row, column or box)
  - green: the number can go here
  - grey: blocked, or the square holds a different number
  - blue: the square already holds this number

  Then tap a green or yellow square to place it.
- **Undo** any change, one step at a time.
- **Autosave** after every move. Continue picks up where you left off.
- **Example game** to try the app without typing in a puzzle.
- **Watch It Solve** shows the yellow-square method solving the example step by step: Play and Pause, a speed slider, a timer, and an Instant run that shows how long the whole solve takes. If the method gets stuck (three rounds of 1–9 without placing anything), it says so.
- **How to Play** introduction on first launch, available again from the menu.
- Light and dark mode.

## Requirements

- Xcode 26.2 or newer
- iOS 26.2 or newer (iPhone)
- No third-party dependencies

## Getting started

1. Clone the repository and open `SudokuHelper.xcodeproj` in Xcode.
2. Choose an iPhone simulator, or your own iPhone, and press **Run** (⌘R).

To run the tests, press **Test** (⌘U) in Xcode, or from the command line:

```bash
xcodebuild test -project SudokuHelper.xcodeproj -scheme SudokuHelper -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' -only-testing:SudokuHelperTests
```

## Architecture

The app follows the pattern of [The Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture), implemented in a few small types of its own instead of the library, and keeps the layers of clean architecture apart.

- **Store, Reducer, Effect** (`Architecture/`). Each feature is a `Reducer` with plain `State` and `Action` types. A `Store` holds the state, runs the reducer for every action and starts the returned `Effect`s, such as saving. Views only read `store.state` and call `store.send(...)`.
- **Delegate actions.** A child feature asks its parent to do something by sending a delegate action, for example the game asking to go back to the menu.
- **Dependency injection.** Features get their dependencies through their initialisers. `AppDependencies` is built once at launch. Tests and previews pass in in-memory versions, so they never touch real storage.

```
SudokuHelper/
├── Architecture/   Store, Reducer and Effect
├── Domain/         Board model and rules, solver, placement hints, repository protocols
├── Data/           UserDefaults and in-memory repositories
├── Features/
│   ├── App/        Main menu and navigation
│   ├── Game/       Board, number pad, undo, start check, success screen
│   ├── Onboarding/ The How to Play introduction
│   └── SolverDemo/ Watch It Solve
├── UI/             Board and number pad views shared by the features
└── AppDependencies.swift, SudokuHelperApp.swift (composition root)
```

## Tests

`SudokuHelperTests` mirrors the app's layers:

- **Domain:** board rules, the solvers, and the number-mode hints
- **Data:** saving and loading with UserDefaults
- **Features:** the app, game, onboarding and solver demo reducers, tested by sending actions and checking the resulting state and effects

## Continuous integration

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) builds the app and runs the unit tests on GitHub Actions for every push to `main` and every pull request.

## Privacy

The app collects no data and does no tracking. The game in progress and the "seen the introduction" setting are stored on the device in UserDefaults, as declared in `PrivacyInfo.xcprivacy`.
