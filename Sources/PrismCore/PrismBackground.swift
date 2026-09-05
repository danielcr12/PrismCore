import PrismBackgroundFoundation
import SwiftUI
import UIKit

private struct PrismBackgroundIdentity: Equatable {
    let backdrop: PrismBackdrop
    let immersiveBackgroundEnabled: Bool
    let noiseEnabled: Bool
    let noiseOpacity: Double
}

private struct PrismScreenBackgroundModifier: ViewModifier {
    @Environment(\.prismConfiguration) private var requestedConfiguration
    @Environment(\.prismPalette) private var palette
    @Environment(\.prismAccessibility) private var accessibility

    func body(content: Content) -> some View {
        let configuration = requestedConfiguration.normalized(for: accessibility)
        let identity = PrismBackgroundIdentity(
            backdrop: palette.backdrop,
            immersiveBackgroundEnabled: configuration.immersiveBackgroundEnabled,
            noiseEnabled: configuration.noise.isEnabled,
            noiseOpacity: configuration.noise.opacity
        )

        content
            .background {
                PrismBackgroundLayer(
                    identity: identity
                )
                .equatable()
                .animation(
                    accessibility.reduceMotion ? nil : .easeInOut(duration: 0.42),
                    value: identity
                )
            }
    }
}

private struct PrismBackgroundLayer: View, Equatable {
    let identity: PrismBackgroundIdentity

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identity == rhs.identity
    }

    var body: some View {
        Group {
            if !identity.immersiveBackgroundEnabled {
                Color(uiColor: .systemGroupedBackground)
            } else {
                PrismBackdropView(backdrop: identity.backdrop)
                    .colorEffect(shaderLibrary.debandingDither())
                    .overlay {
                        if identity.noiseEnabled {
                            PrismNoiseLayer(opacity: identity.noiseOpacity)
                        }
                    }
            }
        }
        .ignoresSafeArea()
    }

    private var shaderLibrary: ShaderLibrary {
        .bundle(.module)
    }

}

/// Renders a Prism backdrop over a stable grouped-system base.
///
/// The complete solid, gradient, or mesh composition receives one shared wash
/// opacity so every backdrop kind has the same light- and dark-mode behavior.
public struct PrismBackdropView: View {
    private let backdrop: PrismBackdrop

    public init(backdrop: PrismBackdrop) {
        self.backdrop = backdrop
    }

    public var body: some View {
        PrismBackdropContent(backdrop: backdrop)
    }
}

private struct PrismBackdropContent: View {
    let backdrop: PrismBackdrop

    @ViewBuilder
    var body: some View {
        switch backdrop {
        case let .solid(color):
            PrismBackgroundWash {
                color
            }
        case let .gradient(gradient):
            PrismLayeredGradientBackground(
                colors: PrismLayeredGradientColors(
                    topColor: gradient.topColor,
                    middleColor: gradient.middleColor,
                    bottomColor: gradient.bottomColor,
                    highlightColor: gradient.highlightColor,
                    glowColor: gradient.glowColor
                )
            )
        case let .mesh(colors):
            PrismBackgroundWash {
                PrismMeshBackground(colors: colors)
            }
        }
    }
}

private struct PrismMeshBackground: View {
    let colors: [Color]

    @ViewBuilder
    var body: some View {
        if colors.count < 2 {
            colors.first ?? Color(uiColor: .systemGroupedBackground)
        } else {
            MeshGradient(
                width: 4,
                height: 4,
                points: Self.meshPoints,
                colors: Self.meshColors(from: colors),
                smoothsColors: true
            )
        }
    }

    private static let meshPoints: [SIMD2<Float>] = [
        [0, 0], [0.333, 0], [0.667, 0], [1, 0],
        [0, 0.333], [0.29, 0.27], [0.72, 0.38], [1, 0.333],
        [0, 0.667], [0.38, 0.73], [0.64, 0.61], [1, 0.667],
        [0, 1], [0.333, 1], [0.667, 1], [1, 1],
    ]

    private static func meshColors(from colors: [Color]) -> [Color] {
        (0..<16).map { colors[$0 % colors.count] }
    }
}

private struct PrismNoiseLayer: View, Equatable {
    let opacity: Double

    /// Keeps the original crisp hash visible without changing its character.
    private static let intensity: Float = 0.12

    var body: some View {
        Rectangle()
            .fill(Color(.sRGB, white: 0.5, opacity: 1))
            .colorEffect(
                ShaderLibrary.bundle(.module).parameterizedNoise(
                    .float(Self.intensity),
                    .float(effectiveFrequency),
                    .float(1)
                )
            )
            .blendMode(.softLight)
            .opacity(min(max(opacity * 0.85, 0), 1))
            .allowsHitTesting(false)
            .transaction { $0.animation = nil }
    }

    private var effectiveFrequency: Float {
        UIDevice.current.userInterfaceIdiom == .pad ? 0.36 : 0.18
    }
}

public extension View {
    func prismScreenBackground() -> some View {
        modifier(PrismScreenBackgroundModifier())
            .scrollEdgeEffectStyle(.soft, for: .all)
    }
}
