import OKLCHKit
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Stable construction values shared by Prism screen and immersive artwork backgrounds.
public enum PrismBackgroundConstruction {
    public static let washOpacity = 0.30
    public static let middleStopLocation = 0.48
    public static let highlightFadeOpacity = 0.38
    public static let highlightRadiusScale = 0.82
    public static let glowOpacity = 0.82
    public static let glowRadiusScale = 0.64

    public static var systemBackgroundColor: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.clear
        #endif
    }

    /// Resolves the standard translucent wash to an opaque color for transitions.
    @MainActor
    public static func washedColor(
        _ color: Color,
        colorScheme: ColorScheme
    ) -> Color {
        guard let foreground = resolvedComponents(
            from: color,
            colorScheme: colorScheme
        ), let background = resolvedSystemBackgroundComponents(
            colorScheme: colorScheme
        ) else {
            return color
        }

        let foregroundAlpha = foreground.opacity * washOpacity
        let backgroundWeight = 1 - foregroundAlpha
        return Color(
            .sRGB,
            red: foreground.red * foregroundAlpha + background.red * backgroundWeight,
            green: foreground.green * foregroundAlpha + background.green * backgroundWeight,
            blue: foreground.blue * foregroundAlpha + background.blue * backgroundWeight,
            opacity: 1
        )
    }

    @MainActor
    private static func resolvedSystemBackgroundComponents(
        colorScheme: ColorScheme
    ) -> ColorComponents? {
        resolvedComponents(
            from: systemBackgroundColor,
            colorScheme: colorScheme
        )
    }

    @MainActor
    fileprivate static func resolvedComponents(
        from color: Color,
        colorScheme: ColorScheme
    ) -> ColorComponents? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var opacity: CGFloat = 0

        #if canImport(UIKit)
        let traits = UITraitCollection(
            userInterfaceStyle: colorScheme == .dark ? .dark : .light
        )
        let resolvedColor = UIColor(color).resolvedColor(with: traits)
        guard resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: &opacity) else {
            return nil
        }
        #elseif canImport(AppKit)
        let appearanceName: NSAppearance.Name = colorScheme == .dark ? .darkAqua : .aqua
        guard let appearance = NSAppearance(named: appearanceName) else {
            return nil
        }
        var resolvedColor: NSColor?
        appearance.performAsCurrentDrawingAppearance {
            resolvedColor = NSColor(color).usingColorSpace(.sRGB)
        }
        guard let resolvedColor else { return nil }
        resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: &opacity)
        #else
        return nil
        #endif

        return ColorComponents(
            red: Double(red),
            green: Double(green),
            blue: Double(blue),
            opacity: Double(opacity)
        )
    }

    fileprivate struct ColorComponents {
        let red: Double
        let green: Double
        let blue: Double
        let opacity: Double
    }
}

/// A light- and dark-mode palette derived from one semantic or extracted color.
public struct PrismAdaptiveBackgroundPalette: Equatable, Sendable {
    public let topColor: Color
    public let middleColor: Color
    public let bottomColor: Color
    public let solidColor: Color
    public let highlightColor: Color
    public let glowColor: Color

    @MainActor
    public init(baseColor: Color, colorScheme: ColorScheme) {
        let baseOKLCH = Self.resolvedOKLCH(
            from: baseColor,
            colorScheme: colorScheme
        )
        let targets = Self.targets(for: colorScheme)

        topColor = Self.adjustedColor(
            from: baseOKLCH,
            lightness: targets.topLightness,
            chromaScale: targets.topChromaScale
        )
        middleColor = Self.adjustedColor(
            from: baseOKLCH,
            lightness: targets.middleLightness,
            chromaScale: targets.middleChromaScale
        )
        bottomColor = Self.adjustedColor(
            from: baseOKLCH,
            lightness: targets.bottomLightness,
            chromaScale: targets.bottomChromaScale
        )
        solidColor = Self.adjustedColor(
            from: baseOKLCH,
            lightness: targets.solidLightness,
            chromaScale: targets.solidChromaScale
        )
        highlightColor = colorScheme == .dark
            ? Color.white.opacity(0.18)
            : Color.white.opacity(0.34)
        glowColor = Self.adjustedColor(
            from: baseOKLCH,
            lightness: targets.glowLightness,
            chromaScale: targets.glowChromaScale
        )
    }

    public var layeredColors: PrismLayeredGradientColors {
        PrismLayeredGradientColors(
            topColor: topColor,
            middleColor: middleColor,
            bottomColor: bottomColor,
            highlightColor: highlightColor,
            glowColor: glowColor
        )
    }

    public func layeredColors(
        startingAt sourceColor: Color
    ) -> PrismLayeredGradientColors {
        PrismLayeredGradientColors(
            topColor: sourceColor,
            middleColor: middleColor,
            bottomColor: bottomColor,
            highlightColor: highlightColor,
            glowColor: glowColor
        )
    }

    private struct Targets {
        let topLightness: Double
        let middleLightness: Double
        let bottomLightness: Double
        let solidLightness: Double
        let glowLightness: Double
        let topChromaScale: Double
        let middleChromaScale: Double
        let bottomChromaScale: Double
        let solidChromaScale: Double
        let glowChromaScale: Double
    }

    private static func targets(for colorScheme: ColorScheme) -> Targets {
        if colorScheme == .dark {
            return Targets(
                topLightness: 0.43,
                middleLightness: 0.32,
                bottomLightness: 0.38,
                solidLightness: 0.34,
                glowLightness: 0.46,
                topChromaScale: 1.10,
                middleChromaScale: 1.16,
                bottomChromaScale: 1.08,
                solidChromaScale: 1.12,
                glowChromaScale: 1.02
            )
        }

        return Targets(
            topLightness: 0.86,
            middleLightness: 0.74,
            bottomLightness: 0.80,
            solidLightness: 0.78,
            glowLightness: 0.88,
            topChromaScale: 0.72,
            middleChromaScale: 0.84,
            bottomChromaScale: 0.78,
            solidChromaScale: 0.78,
            glowChromaScale: 0.60
        )
    }

    private static func adjustedColor(
        from color: OKLCH,
        lightness: Double,
        chromaScale: Double
    ) -> Color {
        Color(
            oklch: OKLCH(
                l: lightness,
                c: min(color.c * chromaScale, 0.32),
                h: color.h,
                alpha: color.alpha
            )
        )
    }

    @MainActor
    private static func resolvedOKLCH(
        from color: Color,
        colorScheme: ColorScheme
    ) -> OKLCH {
        guard let components = PrismBackgroundConstruction.resolvedComponents(
            from: color,
            colorScheme: colorScheme
        ) else {
            return colorScheme == .dark
                ? OKLCH(l: 0.34, c: 0.16, h: 250)
                : OKLCH(l: 0.78, c: 0.14, h: 250)
        }

        return ColorConversion.srgbToOKLCH(
            SRGB(
                r: components.red,
                g: components.green,
                b: components.blue,
                alpha: components.opacity
            )
        )
    }
}

/// Colors used by the standard Prism linear, highlight, and glow composition.
public struct PrismLayeredGradientColors: Equatable, Sendable {
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

/// Applies Prism's standard wash to any supplied background content.
public struct PrismBackgroundWash<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ZStack {
            PrismBackgroundConstruction.systemBackgroundColor

            content
                .opacity(PrismBackgroundConstruction.washOpacity)
        }
    }
}

/// Renders the shared Prism directional gradient, highlight, and glow construction.
public struct PrismLayeredGradientBackground: View {
    private let colors: PrismLayeredGradientColors

    public init(colors: PrismLayeredGradientColors) {
        self.colors = colors
    }

    public var body: some View {
        PrismBackgroundWash {
            GeometryReader { geometry in
                PrismLayeredGradientContent(
                    colors: colors,
                    radiusBasis: max(geometry.size.width, geometry.size.height)
                )
            }
        }
    }
}

/// Begins with a source color and transitions into its adaptive Prism palette.
public struct PrismAdaptiveMeshBackground: View {
    private let sourceColor: Color
    private let palette: PrismAdaptiveBackgroundPalette
    private let transitionStart: CGFloat

    public init(
        sourceColor: Color,
        palette: PrismAdaptiveBackgroundPalette,
        transitionStart: CGFloat = 0.333
    ) {
        self.sourceColor = sourceColor
        self.palette = palette
        self.transitionStart = transitionStart
    }

    @ViewBuilder
    public var body: some View {
        PrismBackgroundWash {
            PrismAdaptiveMeshField(
                sourceColor: sourceColor,
                palette: palette,
                transitionStart: transitionStart
            )
        }
    }
}

private struct PrismAdaptiveMeshField: View {
    let sourceColor: Color
    let palette: PrismAdaptiveBackgroundPalette
    let transitionStart: CGFloat

    @ViewBuilder
    var body: some View {
        if transitionStart >= 1 {
            sourceColor
        } else {
            MeshGradient(
                width: 4,
                height: 4,
                points: points,
                colors: [
                    sourceColor, sourceColor, sourceColor, sourceColor,
                    sourceColor, sourceColor, sourceColor, sourceColor,
                    palette.middleColor, palette.topColor, palette.glowColor, palette.middleColor,
                    palette.bottomColor, palette.middleColor, palette.bottomColor, palette.solidColor,
                ],
                smoothsColors: true
            )
        }
    }

    private var points: [SIMD2<Float>] {
        let start = Float(min(max(transitionStart, 0.001), 0.96))
        let lowerMiddle = start + (1 - start) * 0.52

        return [
            [0, 0], [0.333, 0], [0.667, 0], [1, 0],
            [0, start], [0.333, start], [0.667, start], [1, start],
            [0, lowerMiddle], [0.38, lowerMiddle], [0.64, lowerMiddle], [1, lowerMiddle],
            [0, 1], [0.333, 1], [0.667, 1], [1, 1],
        ]
    }
}

private struct PrismLayeredGradientContent: View {
    let colors: PrismLayeredGradientColors
    let radiusBasis: CGFloat

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: colors.topColor, location: 0),
                        .init(
                            color: colors.middleColor,
                            location: PrismBackgroundConstruction.middleStopLocation
                        ),
                        .init(color: colors.bottomColor, location: 1),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RadialGradient(
                    colors: [
                        colors.highlightColor,
                        colors.highlightColor.opacity(
                            PrismBackgroundConstruction.highlightFadeOpacity
                        ),
                        .clear,
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: radiusBasis
                        * PrismBackgroundConstruction.highlightRadiusScale
                )
            }
            .overlay {
                RadialGradient(
                    colors: [
                        colors.glowColor.opacity(
                            PrismBackgroundConstruction.glowOpacity
                        ),
                        .clear,
                    ],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: radiusBasis * PrismBackgroundConstruction.glowRadiusScale
                )
            }
    }
}
