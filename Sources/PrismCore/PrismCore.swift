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
        // Fall back to .solid when the persisted value is the removed "material" case.
        let rawMaterial = try container.decode(String.self, forKey: .material)
        let decodedMaterial = PrismMaterial(rawValue: rawMaterial) ?? .solid
        self.init(
            isEnabled: try container.decode(Bool.self, forKey: .isEnabled),
            immersiveBackgroundEnabled: try container.decode(
                Bool.self,
                forKey: .immersiveBackgroundEnabled
            ),
            material: decodedMaterial,
            intensity: try container.decode(PrismIntensity.self, forKey: .intensity),
            cornerRadius: try container.decode(Double.self, forKey: .cornerRadius),
            noise: try container.decode(PrismNoise.self, forKey: .noise),
            outline: try container.decode(PrismOutline.self, forKey: .outline),
            highlightsEnabled: try container.decode(Bool.self, forKey: .highlightsEnabled)
        )
    }

    public func normalized(for accessibility: PrismAccessibility = .default) -> Self {
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
        if !result.immersiveBackgroundEnabled, result.material == .glass {
            result.material = .solid
        }
        if result.material == .liquid {
            result.noise.isEnabled = false
            result.outline.isEnabled = false
        }
        return result
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

public enum PrismLiquidStyle: String, CaseIterable, Codable, Equatable, Sendable {
    case clear
    case regular
}

public enum PrismCardStyle: Equatable, Sendable {
    case automatic
    case clear
    case solid
    case glass
    case liquid(PrismLiquidStyle)
}

public enum PrismHighlightStyle: Equatable, Sendable {
    case none
    case whenEnabled(Color)
    case always(Color)
}

/// The geometric shape used by a Prism surface that needs a glass treatment.
public enum PrismSurfaceShape: Equatable, Sendable {
    case capsule
    case rectangle
    case roundedRectangle(cornerRadius: Double)
}

private struct PrismConfigurationKey: EnvironmentKey {
    static let defaultValue = PrismConfiguration.default
}

private struct PrismPaletteKey: EnvironmentKey {
    static let defaultValue = PrismPalette.default
}

private struct PrismAccessibilityKey: EnvironmentKey {
    static let defaultValue = PrismAccessibility.default
}

public extension EnvironmentValues {
    var prismConfiguration: PrismConfiguration {
        get { self[PrismConfigurationKey.self] }
        set { self[PrismConfigurationKey.self] = newValue }
    }

    var prismPalette: PrismPalette {
        get { self[PrismPaletteKey.self] }
        set { self[PrismPaletteKey.self] = newValue }
    }

    var prismAccessibility: PrismAccessibility {
        get { self[PrismAccessibilityKey.self] }
        set { self[PrismAccessibilityKey.self] = newValue }
    }
}

public extension View {
    func prismEnvironment(
        configuration: PrismConfiguration,
        palette: PrismPalette,
        accessibility: PrismAccessibility
    ) -> some View {
        environment(\.prismConfiguration, configuration)
            .environment(\.prismPalette, palette)
            .environment(\.prismAccessibility, accessibility)
    }
}
