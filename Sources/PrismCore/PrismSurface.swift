import SwiftUI

private struct PrismSurfaceModifier: ViewModifier {
    @Environment(\.prismConfiguration) private var requestedConfiguration
    @Environment(\.prismAccessibility) private var accessibility

    let style: PrismLiquidStyle
    let tint: Color?
    let interactive: Bool
    let forceGlass: Bool
    let shape: PrismSurfaceShape

    func body(content: Content) -> some View {
        let configuration = requestedConfiguration.normalized(for: accessibility)

        if !accessibility.reduceTransparency,
           forceGlass || (configuration.isEnabled && configuration.material != .solid) {
            content.glassEffect(glass, in: resolvedShape)
        } else {
            content
                .background(resolvedShape.fill(fallbackFill))
                .overlay {
                    resolvedShape.stroke(
                        Color.secondary.opacity(0.22),
                        lineWidth: 1
                    )
                }
        }
    }

    private var glass: Glass {
        var result: Glass = switch style {
        case .clear: .clear
        case .regular: .regular
        }
        if let tint {
            result = result.tint(tint)
        }
        return result.interactive(interactive)
    }

    private var resolvedShape: AnyShape {
        switch shape {
        case .capsule:
            AnyShape(Capsule())
        case .rectangle:
            AnyShape(Rectangle())
        case let .roundedRectangle(cornerRadius):
            AnyShape(
                RoundedRectangle(
                    cornerRadius: CGFloat(cornerRadius),
                    style: .continuous
                )
            )
        }
    }

    private var fallbackFill: Color {
        if let tint {
            return tint.opacity(0.18)
        }
        return Color(uiColor: .secondarySystemGroupedBackground)
    }
}

public extension View {
    /// Applies Prism's accessibility-aware glass surface or its solid fallback.
    ///
    /// The surface follows the injected Prism configuration. It uses Liquid Glass
    /// when Prism is enabled or `forceGlass` is requested. Reduce Transparency
    /// always keeps the solid fallback for accessibility.
    func prismSurface(
        style: PrismLiquidStyle = .regular,
        tint: Color? = nil,
        interactive: Bool = false,
        shape: PrismSurfaceShape = .roundedRectangle(cornerRadius: 16),
        forceGlass: Bool = false
    ) -> some View {
        modifier(
            PrismSurfaceModifier(
                style: style,
                tint: tint,
                interactive: interactive,
                forceGlass: forceGlass,
                shape: shape
            )
        )
    }
}
