//
//  GlassStyle.swift
//  SudokuHelper
//

import SwiftUI

/// A calm, single-colour backdrop for the Liquid Glass screens: two soft blurred washes of the accent
/// colour on the system background. The main menu uses its own livelier backdrop.
struct CalmBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let strength = colorScheme == .dark ? 0.35 : 1.0
            ZStack {
                Color(.systemBackground)

                Circle()
                    .fill(Color.accentColor.opacity(0.22 * strength))
                    .frame(width: size.width * 0.9)
                    .offset(x: -size.width * 0.4, y: -size.height * 0.3)

                Circle()
                    .fill(Color.accentColor.opacity(0.14 * strength))
                    .frame(width: size.width * 0.8)
                    .offset(x: size.width * 0.45, y: size.height * 0.4)
            }
            .blur(radius: 70)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

extension View {
    /// Puts the view on a Liquid Glass card, e.g. the board or a group of statistics.
    /// The glass sits behind the content, so the content keeps its own colours.
    func glassCard(cornerRadius: CGFloat = 20, padding: CGFloat = 0) -> some View {
        self
            .padding(padding)
            .background {
                let shape = RoundedRectangle(cornerRadius: cornerRadius)
                shape
                    .fill(.clear)
                    .glassEffect(.regular, in: shape)
                    .overlay { shape.strokeBorder(Color.primary.opacity(0.1), lineWidth: 1) }
            }
    }
}

/// Clear Liquid Glass with a faint grey tint and a thin outline in light mode, so buttons stand out
/// from a pale backdrop. In dark mode the glass is left untinted and only the outline is added.
struct GlassOutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration)
    }

    private struct StyledLabel: View {
        let configuration: Configuration
        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            let isLight = colorScheme == .light
            configuration.label
                .foregroundStyle(isEnabled ? Color.primary : Color.secondary)
                // Matches the height the system's prominent glass button gives the same label.
                .padding(.vertical, 6)
                .glassEffect(
                    .regular.tint(isLight ? Color.black.opacity(0.07) : nil).interactive(isEnabled),
                    in: .capsule
                )
                .overlay {
                    Capsule().strokeBorder(Color.primary.opacity(isLight ? 0.16 : 0.15), lineWidth: 1)
                }
                .opacity(isEnabled ? 1 : 0.6)
                .scaleEffect(configuration.isPressed ? 0.98 : 1)
                .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
        }
    }
}

/// A number-pad key: clear glass, or glass tinted in `tint` when it's the picked number.
struct GlassKeyStyle: ButtonStyle {
    var isPicked = false
    var tint: Color = .accentColor

    func makeBody(configuration: Configuration) -> some View {
        Key(configuration: configuration, isPicked: isPicked, tint: tint)
    }

    private struct Key: View {
        let configuration: Configuration
        let isPicked: Bool
        let tint: Color
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            let isLight = colorScheme == .light
            configuration.label
                .foregroundStyle(isPicked ? Color.white : isEnabled ? tint : Color(.tertiaryLabel))
                .glassEffect(
                    isPicked
                        ? .regular.tint(tint).interactive(isEnabled)
                        : .regular.tint(isLight ? Color.black.opacity(0.06) : nil).interactive(isEnabled),
                    in: .capsule
                )
                .overlay {
                    if !isPicked {
                        Capsule().strokeBorder(Color.primary.opacity(isEnabled ? 0.18 : 0.08), lineWidth: 1)
                    }
                }
                .opacity(isEnabled || isPicked ? 1 : 0.7)
        }
    }
}
