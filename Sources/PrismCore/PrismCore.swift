import SwiftUI

public enum PrismMaterial: String, CaseIterable, Codable, Equatable, Sendable {
    case solid
    case glass
    case liquid
}

public enum PrismIntensity: String, CaseIterable, Codable, Equatable, Sendable {
    case verySubtle
    case subtle
    case moderate
    case strong
    case intense
}

public enum PrismOutlineStyle: String, CaseIterable, Codable, Equatable, Identifiable, Sendable {
    case solid
    case dotted
    case segmented

    public var id: Self { self }
}

public struct PrismOutline: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var width: Double
    public var style: PrismOutlineStyle

    public init(
        isEnabled: Bool = false,
        width: Double = 1.3,
        style: PrismOutlineStyle = .solid
    ) {
        self.isEnabled = isEnabled
        self.width = width
        self.style = style
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled
        case width
        case style
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
        width = try container.decodeIfPresent(Double.self, forKey: .width) ?? 1.3

        let rawStyle = try container.decodeIfPresent(String.self, forKey: .style)
        style = rawStyle.flatMap(PrismOutlineStyle.init(rawValue:)) ?? .solid
    }
}

public enum PrismOutlineVisibility: Equatable, Sendable {
    /// Uses the configured outline toggle.
    case automatic

    /// Draws the configured outline even when the global outline toggle is off.
    case always

    /// Suppresses the configured outline.
    case never
}

public struct PrismNoise: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var opacity: Double

    public init(isEnabled: Bool = false, opacity: Double = 0.6) {
        self.isEnabled = isEnabled
        self.opacity = opacity
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled
        case opacity
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
        opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 0.6
    }
}

public struct PrismConfiguration: Codable, Equatable, Sendable {
    public static let `default` = Self()

    public var isEnabled: Bool
    public var immersiveBackgroundEnabled: Bool
    public var material: PrismMaterial
    public var intensity: PrismIntensity
    public var cornerRadius: Double
    public var noise: PrismNoise
    public var outline: PrismOutline
    public var highlightsEnabled: Bool

    public init(
        isEnabled: Bool = false,
        immersiveBackgroundEnabled: Bool = false,
        material: PrismMaterial = .solid,
        intensity: PrismIntensity = .moderate,
        cornerRadius: Double = 26,
        noise: PrismNoise = PrismNoise(),
        outline: PrismOutline = PrismOutline(),
        highlightsEnabled: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.immersiveBackgroundEnabled = immersiveBackgroundEnabled
        self.material = material
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.noise = noise
        self.outline = outline
        self.highlightsEnabled = highlightsEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled
        case immersiveBackgroundEnabled
        case material
        case intensity
        case cornerRadius
        case noise
        case outline
        case highlightsEnabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = Self.default
        let rawMaterial = try container.decodeIfPresent(String.self, forKey: .material)
        let rawIntensity = try container.decodeIfPresent(String.self, forKey: .intensity)
        self.init(
            isEnabled: try container.decodeIfPresent(Bool.self, forKey: .isEnabled)
                ?? defaults.isEnabled,
            immersiveBackgroundEnabled: try container.decodeIfPresent(
                Bool.self,
                forKey: .immersiveBackgroundEnabled
            ) ?? defaults.immersiveBackgroundEnabled,
            material: rawMaterial.flatMap(PrismMaterial.init(rawValue:)) ?? defaults.material,
            intensity: rawIntensity.flatMap(PrismIntensity.init(rawValue:)) ?? defaults.intensity,
            cornerRadius: try container.decodeIfPresent(Double.self, forKey: .cornerRadius)
                ?? defaults.cornerRadius,
            noise: try container.decodeIfPresent(PrismNoise.self, forKey: .noise)
                ?? defaults.noise,
            outline: try container.decodeIfPresent(PrismOutline.self, forKey: .outline)
                ?? defaults.outline,
            highlightsEnabled: try container.decodeIfPresent(
                Bool.self,
                forKey: .highlightsEnabled
            ) ?? defaults.highlightsEnabled
        )
    }

    public func resolved(for accessibility: PrismAccessibility = .default) -> PrismResolvedConfiguration {
        var result = self
        result.immersiveBackgroundEnabled = result.isEnabled && result.immersiveBackgroundEnabled
        result.cornerRadius = min(max(result.cornerRadius, 16), 36)
        result.noise.opacity = min(max(result.noise.opacity, 0), 1)
        result.outline.width = min(max(result.outline.width, 1), 5)

        if !result.isEnabled {
            result.immersiveBackgroundEnabled = false
            result.material = .solid
            result.noise.isEnabled = false
            result.outline.isEnabled = false
            result.highlightsEnabled = false
        }
        if accessibility.reduceTransparency {
            result.material = .solid
        }

        return PrismResolvedConfiguration(
            configuration: result,
            accessibility: accessibility
        )
    }

    @available(*, deprecated, message: "Use resolved(for:) to keep requested and render-ready state distinct.")
    public func normalized(for accessibility: PrismAccessibility = .default) -> Self {
        resolved(for: accessibility).configuration
    }
}

/// Immutable, render-ready Prism state derived from user configuration and accessibility.
public struct PrismResolvedConfiguration: Equatable, Sendable {
    public let isEnabled: Bool
    public let immersiveBackgroundEnabled: Bool
    public let material: PrismMaterial
    public let intensity: PrismIntensity
    public let cornerRadius: Double
    public let noise: PrismNoise
    public let outline: PrismOutline
    public let highlightsEnabled: Bool
    public let accessibility: PrismAccessibility

    fileprivate init(
        configuration: PrismConfiguration,
        accessibility: PrismAccessibility
    ) {
        isEnabled = configuration.isEnabled
        immersiveBackgroundEnabled = configuration.immersiveBackgroundEnabled
        material = configuration.material
        intensity = configuration.intensity
        cornerRadius = configuration.cornerRadius
        noise = configuration.noise
        outline = configuration.outline
        highlightsEnabled = configuration.highlightsEnabled
        self.accessibility = accessibility
    }

    fileprivate var configuration: PrismConfiguration {
        PrismConfiguration(
            isEnabled: isEnabled,
            immersiveBackgroundEnabled: immersiveBackgroundEnabled,
            material: material,
            intensity: intensity,
            cornerRadius: cornerRadius,
            noise: noise,
            outline: outline,
            highlightsEnabled: highlightsEnabled
        )
    }
}

public struct PrismAccessibility: Equatable, Sendable {
    public static let `default` = Self()

    public var reduceMotion: Bool
    public var reduceTransparency: Bool

    public init(reduceMotion: Bool = false, reduceTransparency: Bool = false) {
        self.reduceMotion = reduceMotion
        self.reduceTransparency = reduceTransparency
    }

    static func resolving(
        override: Self?,
        reduceMotion: Bool,
        reduceTransparency: Bool
    ) -> Self {
        override ?? Self(
            reduceMotion: reduceMotion,
            reduceTransparency: reduceTransparency
        )
    }
}

/// A layered backdrop composed from a directional gradient, highlight, and glow.
public struct PrismGradientBackdrop: Equatable, Sendable {
    public let topColor: Color
    public let middleColor: Color
    public let bottomColor: Color
    public let highlightColor: Color
    public let glowColor: Color

    public init(
        topColor: Color,
        middleColor: Color,
        bottomColor: Color,
        highlightColor: Color,
        glowColor: Color
    ) {
        self.topColor = topColor
        self.middleColor = middleColor
        self.bottomColor = bottomColor
        self.highlightColor = highlightColor
        self.glowColor = glowColor
    }
}

public enum PrismBackdrop: Equatable, Sendable {
    case solid(Color)
    case gradient(PrismGradientBackdrop)
    case mesh([Color])

    public static func mesh(_ palette: PrismMeshPalette) -> Self {
        .mesh(palette.colors)
    }
}

/// A canonical 4-by-4 color field for a Prism mesh backdrop.
public struct PrismMeshPalette: Equatable, Sendable, ExpressibleByArrayLiteral {
    public static let colorCount = 16

    public let colors: [Color]

    public init(colors: [Color], fallback: Color = Color(uiColor: .systemGroupedBackground)) {
        let source = colors.isEmpty ? [fallback] : colors
        self.colors = (0..<Self.colorCount).map { source[$0 % source.count] }
    }

    public init(arrayLiteral elements: Color...) {
        self.init(colors: elements)
    }
}

public struct PrismPalette: Equatable, Sendable {
    public static let `default` = Self(
        accentColor: .accentColor,
        backdrop: .solid(Color(uiColor: .systemGroupedBackground))
    )

    public var accentColor: Color
    public var backdrop: PrismBackdrop

    public init(accentColor: Color, backdrop: PrismBackdrop) {
        self.accentColor = accentColor
        self.backdrop = backdrop
    }
}

public enum PrismGlassStyle: String, CaseIterable, Codable, Equatable, Sendable {
    case clear
    case regular
}

@available(*, deprecated, renamed: "PrismGlassStyle")
public typealias PrismLiquidStyle = PrismGlassStyle

public enum PrismSurfaceStyle: Equatable, Sendable {
    case automatic
    case clear
    case solid
    case glass
    case liquid(PrismGlassStyle)
}

/// Compatibility name for the shared style used by Prism cards and surfaces.
public typealias PrismCardStyle = PrismSurfaceStyle

public enum PrismHighlightStyle: Equatable, Sendable {
    case none
    case whenEnabled(Color)
    case always(Color)
}

/// The geometric shape used by a Prism surface that needs a glass treatment.
public enum PrismSurfaceShape: Shape, Equatable, Sendable {
    case capsule
    case rectangle
    case roundedRectangle(cornerRadius: Double)

    nonisolated public func path(in rect: CGRect) -> Path {
        switch self {
        case .capsule:
            Capsule().path(in: rect)
        case .rectangle:
            Rectangle().path(in: rect)
        case let .roundedRectangle(cornerRadius):
            RoundedRectangle(
                cornerRadius: CGFloat(cornerRadius),
                style: .continuous
            )
            .path(in: rect)
        }
    }
}

public enum PrismRenderingQuality: String, CaseIterable, Codable, Equatable, Sendable {
    /// Uses debanding only where gradients benefit from it and honors configured noise.
    case automatic

    /// Disables optional full-screen shader work.
    case reduced

    /// Enables debanding for every immersive backdrop and honors configured noise.
    case full
}

public extension EnvironmentValues {
    @Entry var prismConfiguration = PrismConfiguration.default
    @Entry var prismPalette = PrismPalette.default
    @Entry var prismAccessibilityOverride: PrismAccessibility?
    @Entry var prismRenderingQuality = PrismRenderingQuality.automatic

    @available(*, deprecated, message: "Use prismAccessibilityOverride; nil follows system accessibility settings.")
    var prismAccessibility: PrismAccessibility {
        get { prismAccessibilityOverride ?? .default }
        set { prismAccessibilityOverride = newValue }
    }
}

private struct PrismEnvironmentModifier: ViewModifier {
    let configuration: PrismConfiguration
    let palette: PrismPalette
    let accessibilityOverride: PrismAccessibility?
    let renderingQuality: PrismRenderingQuality

    func body(content: Content) -> some View {
        content
            .environment(\.prismConfiguration, configuration)
            .environment(\.prismPalette, palette)
            .environment(\.prismAccessibilityOverride, accessibilityOverride)
            .environment(\.prismRenderingQuality, renderingQuality)
    }
}

public extension View {
    func prismEnvironment(
        configuration: PrismConfiguration,
        palette: PrismPalette,
        accessibility: PrismAccessibility? = nil,
        renderingQuality: PrismRenderingQuality = .automatic
    ) -> some View {
        modifier(
            PrismEnvironmentModifier(
                configuration: configuration,
                palette: palette,
                accessibilityOverride: accessibility,
                renderingQuality: renderingQuality
            )
        )
    }
}
