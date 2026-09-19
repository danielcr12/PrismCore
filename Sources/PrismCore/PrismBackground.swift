import PrismCoreBackgrounds
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

private struct PrismBackgroundIdentity: Equatable {
    let backdrop: PrismBackdrop
    let immersiveBackgroundEnabled: Bool
    let ditherEnabled: Bool
    let noiseEnabled: Bool
    let noiseOpacity: Double
}

private struct PrismScreenBackgroundModifier: ViewModifier {
    @Environment(\.prismConfiguration) private var requestedConfiguration
    @Environment(\.prismBackdrop) private var backdrop
    @Environment(\.prismAccessibilityOverride) private var accessibilityOverride
    @Environment(\.prismRenderingQuality) private var renderingQuality
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let accessibility = PrismAccessibility.resolving(
            override: accessibilityOverride,
            reduceMotion: reduceMotion,
            reduceTransparency: reduceTransparency
        )
        let configuration = requestedConfiguration.resolved(for: accessibility)
        let identity = PrismBackgroundIdentity(
            backdrop: backdrop,
            immersiveBackgroundEnabled: configuration.immersiveBackgroundEnabled,
            ditherEnabled: ditherEnabled(for: backdrop),
            noiseEnabled: configuration.noise.isEnabled && renderingQuality != .reduced,
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

    private func ditherEnabled(for backdrop: PrismBackdrop) -> Bool {
        switch renderingQuality {
        case .reduced:
            false
        case .automatic:
            if case .gradient = backdrop { true } else { false }
        case .full:
            true
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
                PrismBackgroundConstruction.systemBackgroundColor
            } else {
                PrismBackdropView(backdrop: identity.backdrop)
                    .colorEffect(
                        shaderLibrary.debandingDither(),
                        isEnabled: identity.ditherEnabled
                    )
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
            colors.first ?? PrismBackgroundConstruction.systemBackgroundColor
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
        if colors.count == PrismMeshPalette.colorCount {
            colors
        } else {
            PrismMeshPalette(colors: colors).colors
        }
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
        #if canImport(UIKit)
        UIDevice.current.userInterfaceIdiom == .pad ? 0.36 : 0.18
        #else
        0.18
        #endif
    }
}

public extension View {
    func prismScreenBackground() -> some View {
        modifier(PrismScreenBackgroundModifier())
            .scrollEdgeEffectStyle(.soft, for: .all)
    }
}
