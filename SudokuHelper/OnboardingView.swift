//
//  OnboardingView.swift
//  SudokuHelper
//

import SwiftUI

/// A swipeable introduction to the app. Shown on first launch and from "How to Play" in the menu.
struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0

    private struct Page {
        let title: String
        let text: String
        var symbol: String? = nil
        /// A small copy of the game screen shown under the text.
        var example: ExampleBoard.Example? = nil
        /// Shows the guide to the number-mode colours under the text.
        var showsColorGuide = false
    }

    private let pages: [Page] = [
        Page(
            title: "Welcome to Sudoku Helper",
            text: "Type in any Sudoku puzzle and the app shows you where each number can still go.",
            symbol: "square.grid.3x3.fill"
        ),
        Page(
            title: "Enter Your Puzzle",
            text: "Tap New Game and type in the puzzle's starting numbers. Tap Start and they're locked, so you can't change them by accident.",
            symbol: "square.and.pencil"
        ),
        Page(
            title: "Fill In a Square",
            text: "Tap a square to select it. Only the numbers that fit its row, column and box stay active on the pad.",
            example: .square(SudokuPosition(row: 4, column: 3))
        ),
        Page(
            title: "Find Where a Number Goes",
            text: "With no square selected, tap a number. The board shows where it can go, then tap a square to place it.",
            example: .number(2)
        ),
        Page(
            title: "What the Colours Mean",
            text: "After you pick a number, every square gets a colour.",
            showsColorGuide: true
        ),
        Page(
            title: "Undo and Autosave",
            text: "Made a mistake? Tap undo to take back your last change. Your game is saved after every move, so tap Continue to pick up where you left off.",
            symbol: "arrow.uturn.backward.circle.fill"
        ),
    ]

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            footer
        }
        .background(Color(.systemBackground))
    }

    /// Page dots, Next and Skip intro, pinned to the bottom with the same 24pt margins as the content.
    private var footer: some View {
        VStack(spacing: 0) {
            PageIndicator(count: pages.count, current: page)

            Button {
                if isLastPage {
                    onFinish()
                } else {
                    withAnimation { page += 1 }
                }
            } label: {
                Text(isLastPage ? "Get Started" : "Next")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .padding(.top, 20)

            // Hidden on the last page, but keeps its space so the layout doesn't jump.
            Button("Skip intro", action: onFinish)
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
    private func pageView(_ page: Page) -> some View {
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

/// A non-interactive copy of the board and number pad showing one of the two modes on the example puzzle.
/// It uses the full width it's given and only shrinks the board when there isn't enough height.
struct ExampleBoard: View {
    enum Example {
        /// A square is selected, so the pad only offers the numbers that fit it.
        case square(SudokuPosition)
        /// A number is picked, so the board shows where it can go.
        case number(Int)
    }

    let example: Example
    /// The space the demo has to fit in.
    let available: CGSize

    private let board = SudokuBoard.sample
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
            .background(isPicked ? Color.accentColor : Color(.systemGray6), in: Circle())
    }

    /// Erase isn't used in these examples, so it's drawn dimmed.
    private func eraseKey(size: CGFloat) -> some View {
        Image(systemName: "delete.left")
            .font(.system(size: 20))
            .foregroundStyle(Color(.secondaryLabel).opacity(0.5))
            .frame(width: size, height: size)
            .background(Color(.systemGray6), in: Circle())
    }

    private var selection: SudokuPosition? {
        if case .square(let position) = example { return position }
        return nil
    }

    private var highlightedNumber: Int? {
        if case .number(let number) = example { return number }
        return nil
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
