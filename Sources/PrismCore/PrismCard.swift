import SwiftUI

private struct PrismCardInputs: Equatable {
    enum Mode: Equatable {
        case clear
        case solid
        case glass
        case liquid(PrismLiquidStyle)
    }

    let mode: Mode
    let cornerRadius: CGFloat
    let outlineEnabled: Bool
    let outlineStyle: PrismOutlineStyle
    let outlineWidth: Double
    let intensity: PrismIntensity
    let highlightEnabled: Bool
    let highlightSignature: Int
    let outlineColorSignature: Int
}

private struct PrismCardBackground: View, Equatable {
    let inputs: PrismCardInputs
    let highlightColor: Color?
    let outlineColor: Color

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.inputs == rhs.inputs
    }

    private var highlightOpacity: Double {
        switch inputs.intensity {
        case .verySubtle: 0.05
        case .subtle: 0.06
        case .moderate: 0.07
        case .strong: 0.085
        case .intense: 0.10
        }
    }

    @ViewBuilder private var highlightOverlay: some View {
        if inputs.highlightEnabled, let highlightColor {
            RoundedRectangle(cornerRadius: inputs.cornerRadius, style: .continuous)
                .fill(highlightColor.opacity(highlightOpacity))
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder private var outlineOverlay: some View {
        if inputs.outlineEnabled {
            RoundedRectangle(cornerRadius: inputs.cornerRadius, style: .continuous)
                .strokeBorder(
                    outlineColor.opacity(PrismOutlineRenderer.opacity(for: inputs.intensity)),
                    style: PrismOutlineRenderer.strokeStyle(
                        for: inputs.outlineStyle,
                        lineWidth: inputs.outlineWidth
                    )
                )
        }
    }

    var body: some View {
        switch inputs.mode {
        case .clear:
            roundedRectangle
                .fill(.clear)
                .overlay(outlineOverlay)
        case .solid:
            roundedRectangle
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .overlay(highlightOverlay)
                .overlay(outlineOverlay)
        case .glass:
            roundedRectangle
                .fill(Self.fillColor(for: inputs.intensity))
                .overlay(highlightOverlay)
                .overlay(outlineOverlay)
        case .liquid(.regular):
            roundedRectangle
                .fill(.clear)
                .glassEffect(
                    .regular,
                    in: RoundedRectangle(cornerRadius: inputs.cornerRadius, style: .continuous)
                )
                .overlay(highlightOverlay)
                .overlay(outlineOverlay)
        case .liquid(.clear):
            roundedRectangle
                .fill(.clear)
                .glassEffect(
                    .clear,
                    in: RoundedRectangle(cornerRadius: inputs.cornerRadius, style: .continuous)
                )
                .overlay(highlightOverlay)
                .overlay(outlineOverlay)
        }
    }

    private var roundedRectangle: RoundedRectangle {
        RoundedRectangle(cornerRadius: inputs.cornerRadius, style: .continuous)
    }

    private static func fillColor(for intensity: PrismIntensity) -> Color {
        switch intensity {
        case .verySubtle: Color(uiColor: .systemBackground).opacity(0.80)
        case .subtle: Color(uiColor: .systemBackground).opacity(0.72)
        case .moderate: Color(uiColor: .systemBackground).opacity(0.65)
        case .strong: Color(uiColor: .systemBackground).opacity(0.58)
        case .intense: Color(uiColor: .systemBackground).opacity(0.52)
        }
    }

}

private enum PrismOutlineRenderer {
    static func opacity(for intensity: PrismIntensity) -> Double {
        switch intensity {
        case .verySubtle: 0.85
        case .subtle: 0.75
        case .moderate: 0.65
        case .strong: 0.55
        case .intense: 0.45
        }
    }

    static func strokeStyle(
        for style: PrismOutlineStyle,
        lineWidth: Double
    ) -> StrokeStyle {
        let width = CGFloat(max(1, lineWidth))
        return switch style {
        case .solid:
            StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
        case .dotted:
            StrokeStyle(
                lineWidth: width,
                lineCap: .round,
                lineJoin: .round,
                dash: [0, width * 2.4]
            )
        case .segmented:
            StrokeStyle(
                lineWidth: width,
                lineCap: .round,
                lineJoin: .round,
                dash: [width * 3.2, width * 2.2]
            )
        }
    }
}

private struct PrismCardModifier: ViewModifier {
    @Environment(\.prismConfiguration) private var requestedConfiguration
    @Environment(\.prismPalette) private var palette
    @Environment(\.prismAccessibility) private var accessibility

    let style: PrismCardStyle
    let highlight: PrismHighlightStyle
    let outlineVisibility: PrismOutlineVisibility
    let outlineStyleOverride: PrismOutlineStyle?

    func body(content: Content) -> some View {
        let configuration = requestedConfiguration.normalized(for: accessibility)
        let mode = resolvedMode(configuration: configuration)
        let highlightColor = resolvedHighlight(configuration: configuration)
        let outlineStyle = outlineStyleOverride ?? configuration.outline.style
        let outlineEnabled = switch outlineVisibility {
        case .automatic:
            configuration.outline.isEnabled && mode.supportsOutline
        case .always:
            true
        case .never:
            false
        }
        let inputs = PrismCardInputs(
            mode: mode,
            cornerRadius: CGFloat(configuration.cornerRadius),
            outlineEnabled: outlineEnabled,
            outlineStyle: outlineStyle,
            outlineWidth: configuration.outline.width,
            intensity: configuration.isEnabled ? configuration.intensity : .moderate,
            highlightEnabled: highlightColor != nil,
            highlightSignature: colorSignature(highlightColor),
            outlineColorSignature: outlineEnabled ? colorSignature(palette.accentColor) : 0
        )

        content.background {
            PrismCardBackground(
                inputs: inputs,
                highlightColor: highlightColor,
                outlineColor: palette.accentColor
            )
            .equatable()
        }
    }

    private func resolvedMode(configuration: PrismConfiguration) -> PrismCardInputs.Mode {
        switch style {
        case .automatic:
            switch configuration.material {
            case .solid: .solid
            case .glass: .glass
            case .liquid: .liquid(.clear)
            }
        case .clear:
            .clear
        case .solid:
            .solid
        case .glass:
            accessibility.reduceTransparency ? .solid : .glass
        case let .liquid(style):
            accessibility.reduceTransparency ? .solid : .liquid(style)
        }
    }

    private func resolvedHighlight(
        configuration: PrismConfiguration
    ) -> Color? {
        switch highlight {
        case .none:
            nil
        case let .whenEnabled(color):
            configuration.highlightsEnabled ? color : nil
        case let .always(color):
            color
        }
    }
}

private struct PrismOutlineModifier: ViewModifier {
    @Environment(\.prismConfiguration) private var requestedConfiguration
    @Environment(\.prismPalette) private var palette
    @Environment(\.prismAccessibility) private var accessibility

    let visibility: PrismOutlineVisibility
    let styleOverride: PrismOutlineStyle?
    let cornerRadius: CGFloat?

    func body(content: Content) -> some View {
        let configuration = requestedConfiguration.normalized(for: accessibility)
        let isVisible = switch visibility {
        case .automatic:
            configuration.outline.isEnabled
        case .always:
            true
        case .never:
            false
        }

        return content.overlay {
            RoundedRectangle(
                cornerRadius: cornerRadius ?? CGFloat(configuration.cornerRadius),
                style: .continuous
            )
            .strokeBorder(
                palette.accentColor.opacity(
                    PrismOutlineRenderer.opacity(for: configuration.intensity)
                ),
                style: PrismOutlineRenderer.strokeStyle(
                    for: styleOverride ?? configuration.outline.style,
                    lineWidth: configuration.outline.width
                )
            )
            .opacity(isVisible ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

private extension PrismCardInputs.Mode {
    var supportsOutline: Bool {
        switch self {
        case .solid, .glass: true
        case .clear, .liquid: false
        }
    }
}

private struct PrismListRowModifier: ViewModifier {
    @Environment(\.prismConfiguration) private var requestedConfiguration
    @Environment(\.prismPalette) private var palette
    @Environment(\.prismAccessibility) private var accessibility

    func body(content: Content) -> some View {
        let configuration = requestedConfiguration.normalized(for: accessibility)
        let mode: PrismCardInputs.Mode = switch configuration.material {
        case .solid: .solid
        case .glass: .glass
        case .liquid: .liquid(.clear)
        }
        let outlineEnabled = configuration.outline.isEnabled && mode.supportsOutline
        let inputs = PrismCardInputs(
            mode: mode,
            cornerRadius: CGFloat(configuration.cornerRadius),
            outlineEnabled: outlineEnabled,
            outlineStyle: configuration.outline.style,
            outlineWidth: configuration.outline.width,
            intensity: configuration.isEnabled ? configuration.intensity : .moderate,
            highlightEnabled: false,
            highlightSignature: 0,
            outlineColorSignature: outlineEnabled ? colorSignature(palette.accentColor) : 0
        )

        content
            .listRowBackground(
                PrismCardBackground(
                    inputs: inputs,
                    highlightColor: nil,
                    outlineColor: palette.accentColor
                )
                .equatable()
            )
            .listRowSeparatorTint(separatorColor(for: configuration.intensity))
    }
}

public struct PrismDivider: View {
    @Environment(\.prismConfiguration) private var configuration

    private let axis: Axis

    public init(_ axis: Axis = .horizontal) {
        self.axis = axis
    }

    public var body: some View {
        let strokeStyle = separatorStrokeStyle(for: configuration.intensity)
        PrismDividerLine(axis: axis)
            .stroke(separatorColor(for: configuration.intensity), style: strokeStyle)
            .frame(
                width: axis == .vertical ? strokeStyle.lineWidth : nil,
                height: axis == .horizontal ? strokeStyle.lineWidth : nil
            )
            .frame(
                maxWidth: axis == .horizontal ? .infinity : nil,
                maxHeight: axis == .vertical ? .infinity : nil
            )
            .accessibilityHidden(true)
    }
}

private struct PrismDividerLine: Shape {
    let axis: Axis

    func path(in rect: CGRect) -> Path {
        Path { path in
            switch axis {
            case .horizontal:
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            case .vertical:
                path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            }
        }
    }
}

public extension View {
    /// Applies Prism's card treatment and optionally overrides the configured
    /// outline visibility while retaining its width and intensity.
    func prismCard(
        _ style: PrismCardStyle = .automatic,
        highlight: PrismHighlightStyle = .none,
        outline: PrismOutlineVisibility = .automatic,
        outlineStyle: PrismOutlineStyle? = nil
    ) -> some View {
        modifier(
            PrismCardModifier(
                style: style,
                highlight: highlight,
                outlineVisibility: outline,
                outlineStyleOverride: outlineStyle
            )
        )
    }

    /// Draws Prism's configured outline around a custom view shape.
    func prismOutline(
        _ visibility: PrismOutlineVisibility = .automatic,
        style: PrismOutlineStyle? = nil,
        cornerRadius: CGFloat? = nil
    ) -> some View {
        modifier(
            PrismOutlineModifier(
                visibility: visibility,
                styleOverride: style,
                cornerRadius: cornerRadius
            )
        )
    }

    func prismListRow() -> some View {
        modifier(PrismListRowModifier())
    }
}

@MainActor
private func colorSignature(_ color: Color?) -> Int {
    guard let color else { return 0 }
    let resolved = UIColor(color)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    guard resolved.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
        return resolved.hash
    }
    var hasher = Hasher()
    hasher.combine(Int((red * 255).rounded()))
    hasher.combine(Int((green * 255).rounded()))
    hasher.combine(Int((blue * 255).rounded()))
    hasher.combine(Int((alpha * 255).rounded()))
    return hasher.finalize()
}

private func separatorColor(for intensity: PrismIntensity) -> Color {
    switch intensity {
    case .verySubtle: .secondary.opacity(0.25)
    case .subtle: .secondary.opacity(0.30)
    case .moderate: .secondary.opacity(0.40)
    case .strong: .secondary.opacity(0.45)
    case .intense: .secondary.opacity(0.50)
    }
}

private func separatorStrokeStyle(for intensity: PrismIntensity) -> StrokeStyle {
    switch intensity {
    case .verySubtle: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 4.5])
    case .subtle: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3.5, 4])
    case .moderate: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [4, 4])
    case .strong: StrokeStyle(lineWidth: 1.25, lineCap: .round, dash: [4.5, 3.5])
    case .intense: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 3])
    }
}
