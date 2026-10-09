//
//  OnboardingView.swift
//  SudokuHelper
//

import SwiftUI

/// A swipeable introduction to the app. Shown on first launch and from "How to Play" in the menu.
struct OnboardingView: View {
    let store: Store<OnboardingFeature.State, OnboardingFeature.Action>

    private var pages: [OnboardingPage] { OnboardingPage.all }
    private var isLastPage: Bool { store.state.isLastPage }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: store.binding(\.page, send: OnboardingFeature.Action.pageChanged)) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            footer
        }
        .background { CalmBackdrop() }
    }

    /// Page dots, Next and Skip intro, pinned to the bottom with the same 24pt margins as the content.
    private var footer: some View {
        VStack(spacing: 0) {
            PageIndicator(count: pages.count, current: store.state.page)

            Button {
                store.send(.nextTapped, animation: .default)
            } label: {
                Text(isLastPage ? "Get Started" : "Next")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .glassEffect(.regular.tint(.accentColor).interactive(), in: .rect(cornerRadius: 16))
                    // The whole button is tappable, not just the label inside it.
                    .contentShape(.rect(cornerRadius: 16))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 20)

            // Hidden on the last page, but keeps its space so the layout doesn't jump.
            Button("Skip intro") { store.send(.skipTapped) }
                .font(.system(size: 15))
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.top, 12)
                .opacity(isLastPage ? 0 : 1)
                .disabled(isLastPage)
        }
        .padding(.horizontal, OnboardingLayout.margin)
        .padding(.bottom, 8)
    }

    /// The header sits 24pt below the safe area; the picture, demo or colour guide is centred
    /// in the space left between the header and the footer.
    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(page.text)
                    .font(.system(size: 17))
                    .foregroundStyle(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 24)

            GeometryReader { proxy in
                Group {
                    if let example = page.example {
                        ExampleBoard(example: example, available: proxy.size)
                    } else if page.showsColorGuide {
                        ColorGuide()
                    } else if let symbol = page.symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 96))
                            .foregroundStyle(.tint)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            // At least 32pt below the subtitle and 24pt above the page dots.
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, OnboardingLayout.margin)
    }
}

private enum OnboardingLayout {
    /// The one horizontal margin shared by the text, the demo and the footer.
    static let margin: CGFloat = 24
}

/// Dots for the pages; the current page is a wider blue capsule.
private struct PageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.accentColor : Color(.systemGray4))
                    .frame(width: index == current ? 18 : 6, height: 6)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: current)
        .accessibilityElement()
        .accessibilityLabel("Page \(current + 1) of \(count)")
    }
}

/// Explains the colours a square gets in number mode.
private struct ColorGuide: View {
    private let items: [(color: Color, opacity: Double, title: String, detail: String)] = [
        (.yellow, 0.55, "Must go here", "It's the only number that fits this square, or the only place left for it in its row, column or box."),
        (.green, 0.3, "Can go here", "The number fits, but it could also go somewhere else."),
        (.gray, 0.25, "Blocked", "The number would clash here, or the square already holds a different number."),
        (.accentColor, 0.35, "Already there", "The square already holds this number."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                HStack(alignment: .top, spacing: 16) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.color.opacity(item.opacity))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.3)))
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.headline)
                        Text(item.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

/// A non-interactive copy of the board and number pad showing the example puzzle being typed in or played.
/// It uses the full width it's given and only shrinks the board when there isn't enough height.
struct ExampleBoard: View {
    enum Example: Equatable {
        /// The puzzle is half typed in on New Game, with the next empty square selected.
        case typingIn
        /// A square is selected, so the pad only offers the numbers that fit it.
        case square(SudokuPosition)
        /// A number is picked, so the board shows where it can go.
        case number(Int)
    }

    let example: Example
    /// The space the demo has to fit in.
    let available: CGSize

    private var board: SudokuBoard {
        example == .typingIn ? Self.halfTypedIn : .sample
    }

    /// The example's first three rows and the start of the fourth, as typed in on New Game (not locked yet).
    private static let halfTypedIn: SudokuBoard = {
        var board = SudokuBoard()
        for row in 0..<4 {
            for column in 0..<SudokuBoard.size where row < 3 || column < 3 {
                board.setValue(SudokuBoard.sample[row, column], row: row, column: column)
            }
        }
        return board
    }()
    private static let boardToPad: CGFloat = 20
    private static let rowSpacing: CGFloat = 12
    private static let minColumnSpacing: CGFloat = 10
    private static let maxCircle: CGFloat = 56

    var body: some View {
        let side = boardSide
        let circle = circleSize(for: side)
        let columnSpacing = (side - 5 * circle) / 4

        VStack(spacing: Self.boardToPad) {
            SudokuBoardView(
                board: board,
                selection: .constant(selection),
                highlightedNumber: highlightedNumber,
                style: .onboarding
            )
            .frame(width: side, height: side)

            VStack(spacing: Self.rowSpacing) {
                HStack(spacing: columnSpacing) {
                    ForEach(1...5, id: \.self) { padKey(number: $0, size: circle) }
                }
                HStack(spacing: columnSpacing) {
                    ForEach(6...9, id: \.self) { padKey(number: $0, size: circle) }
                    eraseKey(size: circle)
                }
            }
            .frame(width: side)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// The full width, unless the board plus pad would be too tall; then the board shrinks and the gaps stay.
    private var boardSide: CGFloat {
        let width = available.width
        let height = available.height
        // With full-size circles the pad is two 56pt rows plus the row gap.
        var side = min(width, height - Self.boardToPad - 2 * Self.maxCircle - Self.rowSpacing)
        if circleSize(for: side) < Self.maxCircle {
            // Circles shrink with the board: side + 20 + 2 × (side − 40) / 5 + 12 ≤ height.
            side = min(width, (height - Self.boardToPad - Self.rowSpacing + 2 * 4 * Self.minColumnSpacing / 5) / 1.4)
        }
        return max(side, 0)
    }

    private func circleSize(for side: CGFloat) -> CGFloat {
        min((side - 4 * Self.minColumnSpacing) / 5, Self.maxCircle)
    }

    private func padKey(number: Int, size: CGFloat) -> some View {
        let isPicked = number == highlightedNumber
        let isAllowed = selection.map { board.allowedNumbers(row: $0.row, column: $0.column).contains(number) } ?? true
        return Text("\(number)")
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(isPicked ? Color.white : (isAllowed ? Color.accentColor : Color(.tertiaryLabel)))
            .frame(width: size, height: size)
            .glassEffect(isPicked ? .regular.tint(.accentColor) : .regular, in: .circle)
    }

    /// Erase isn't used in these examples, so it's drawn dimmed.
    private func eraseKey(size: CGFloat) -> some View {
        Image(systemName: "delete.left")
            .font(.system(size: 20))
            .foregroundStyle(Color(.secondaryLabel).opacity(0.5))
            .frame(width: size, height: size)
            .glassEffect(.regular, in: .circle)
    }

    private var selection: SudokuPosition? {
        switch example {
        case let .square(position): position
        case .typingIn: SudokuPosition(row: 3, column: 3)
        case .number: nil
        }
    }

    private var highlightedNumber: Int? {
        if case .number(let number) = example { return number }
        return nil
    }
}

#Preview {
    OnboardingView(store: Store(initialState: OnboardingFeature.State(), reducer: OnboardingFeature()))
}
