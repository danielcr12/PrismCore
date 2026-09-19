import SwiftUI

private enum PrismSurfaceMode: Equatable {
    case clear
    case solid
    case translucent
    case glass(PrismGlassStyle)
}

private struct PrismSurfaceModifier: ViewModifier {
    @Environment(\.prismConfiguration) private var requestedConfiguration
    @Environment(\.prismAccessibilityOverride) private var accessibilityOverride
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    let style: PrismSurfaceStyle
    let automaticGlassStyle: PrismGlassStyle
    let tint: Color?
    let interactive: Bool
    let shape: PrismSurfaceShape

    func body(content: Content) -> some View {
        let accessibility = PrismAccessibility.resolving(
            override: accessibilityOverride,
            reduceMotion: false,
            reduceTransparency: reduceTransparency
        )
        let configuration = requestedConfiguration.resolved(for: accessibility)
        let mode = resolvedMode(configuration: configuration)

        content
            .background(shape.fill(fill(for: mode, intensity: configuration.intensity)))
            .overlay {
                if mode.displaysBorder {
                    shape
                        .stroke(Color.secondary.opacity(0.22), lineWidth: 1)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .glassEffect(glass(for: mode), in: shape)
    }

    private func resolvedMode(
        configuration: PrismResolvedConfiguration
    ) -> PrismSurfaceMode {
        switch style {
        case .automatic:
            switch configuration.material {
            case .solid: .solid
            case .glass: .translucent
            case .liquid: .glass(automaticGlassStyle)
            }
        case .clear:
            .clear
        case .solid:
            .solid
        case .glass:
            configuration.accessibility.reduceTransparency ? .solid : .translucent
        case let .liquid(style):
            configuration.accessibility.reduceTransparency ? .solid : .glass(style)
        }
    }

    private func glass(for mode: PrismSurfaceMode) -> Glass {
        guard case let .glass(style) = mode else { return .identity }

        var result: Glass = switch style {
        case .clear: .clear
        case .regular: .regular
        }
        if let tint {
            result = result.tint(tint)
        }
        return result.interactive(interactive)
    }

    private func fill(for mode: PrismSurfaceMode, intensity: PrismIntensity) -> Color {
        switch mode {
        case .clear, .glass:
            .clear
        case .solid:
            tint?.opacity(0.18) ?? PrismPlatformColors.secondaryBackground
        case .translucent:
            if let tint {
                tint.opacity(0.18)
            } else {
                PrismPlatformColors.background.opacity(fillOpacity(for: intensity))
            }
        }
    }

    private func fillOpacity(for intensity: PrismIntensity) -> Double {
        switch intensity {
        case .verySubtle: 0.80
        case .subtle: 0.72
        case .moderate: 0.65
        case .strong: 0.58
        case .intense: 0.52
        }
    }
}

private extension PrismSurfaceMode {
    var displaysBorder: Bool {
        switch self {
        case .solid, .translucent: true
        case .clear, .glass: false
        }
    }
}

public extension View {
    /// Applies a Prism surface while preserving the identity of the modified view.
    ///
    /// Automatic surfaces use the same solid, translucent, and Liquid Glass mapping
    /// as Prism cards. Reduce Transparency always resolves translucent and Liquid
    /// Glass styles to the solid fallback.
    func prismSurface(
        _ style: PrismSurfaceStyle = .automatic,
        tint: Color? = nil,
        interactive: Bool = false,
        shape: PrismSurfaceShape = .roundedRectangle(cornerRadius: 16)
    ) -> some View {
        modifier(
            PrismSurfaceModifier(
                style: style,
                automaticGlassStyle: .clear,
                tint: tint,
                interactive: interactive,
                shape: shape
            )
        )
    }

    @available(*, deprecated, message: "Pass PrismSurfaceStyle as the first argument instead.")
    func prismSurface(
        style: PrismGlassStyle,
        tint: Color? = nil,
        interactive: Bool = false,
        shape: PrismSurfaceShape = .roundedRectangle(cornerRadius: 16),
        forceGlass: Bool = false
    ) -> some View {
        modifier(
            PrismSurfaceModifier(
                style: forceGlass ? .liquid(style) : .automatic,
                automaticGlassStyle: style,
                tint: tint,
                interactive: interactive,
                shape: shape
            )
        )
    }

    @available(*, deprecated, message: "Pass .liquid(.regular) to prismSurface(_:) instead.")
    func prismSurface(
        tint: Color? = nil,
        interactive: Bool = false,
        shape: PrismSurfaceShape = .roundedRectangle(cornerRadius: 16),
        forceGlass: Bool
    ) -> some View {
        prismSurface(
            forceGlass ? .liquid(.regular) : .automatic,
            tint: tint,
            interactive: interactive,
            shape: shape
        )
    }
}
