import Foundation
import Testing
@testable import PrismCore

@Test func disabledConfigurationResolvesToSolidDefaults() {
    let requested = PrismConfiguration(
        isEnabled: false,
        immersiveBackgroundEnabled: true,
        material: .liquid,
        noise: PrismNoise(isEnabled: true),
        outline: PrismOutline(isEnabled: true),
        highlightsEnabled: true
    )

    let result = requested.resolved()

    #expect(!result.immersiveBackgroundEnabled)
    #expect(result.material == .solid)
    #expect(!result.noise.isEnabled)
    #expect(!result.outline.isEnabled)
    #expect(!result.highlightsEnabled)
}

@Test func configurationClampsNumericInputs() {
    let requested = PrismConfiguration(
        isEnabled: true,
        cornerRadius: 200,
        noise: PrismNoise(isEnabled: true, opacity: -1),
        outline: PrismOutline(isEnabled: true, width: 12)
    )

    let result = requested.resolved()

    #expect(result.cornerRadius == 36)
    #expect(result.noise.opacity == 0)
    #expect(result.outline.width == 5)
}

@Test func reduceTransparencyForcesSolidMaterial() {
    let requested = PrismConfiguration(
        isEnabled: true,
        immersiveBackgroundEnabled: true,
        material: .liquid
    )

    let result = requested.resolved(
        for: PrismAccessibility(reduceTransparency: true)
    )

    #expect(result.material == .solid)
}

@Test func surfaceMaterialIsIndependentFromImmersiveBackground() {
    let requested = PrismConfiguration(
        isEnabled: true,
        immersiveBackgroundEnabled: false,
        material: .glass
    )

    #expect(requested.resolved().material == .glass)
}

@Test func removedMaterialValueDecodesToSolid() throws {
    let data = Data(
        #"{"isEnabled":true,"immersiveBackgroundEnabled":false,"material":"material","materialStyle":"ultraThin","intensity":"moderate","cornerRadius":26,"noise":{"isEnabled":false,"opacity":0.6},"outline":{"isEnabled":false,"width":1.3,"style":"solid"},"highlightsEnabled":false}"#.utf8
    )

    let configuration = try JSONDecoder().decode(PrismConfiguration.self, from: data)

    #expect(configuration.material == .solid)
}

@Test func liquidMaterialPreservesIndependentBackgroundAndOutlinePreferences() {
    let requested = PrismConfiguration(
        isEnabled: true,
        immersiveBackgroundEnabled: true,
        material: .liquid,
        noise: PrismNoise(isEnabled: true),
        outline: PrismOutline(isEnabled: true)
    )

    let result = requested.resolved()

    #expect(result.noise.isEnabled)
    #expect(result.outline.isEnabled)
}

@Test func legacyConfigurationUsesDefaultsForMissingKeys() throws {
    let data = Data(#"{"isEnabled":true,"material":"glass"}"#.utf8)

    let configuration = try JSONDecoder().decode(PrismConfiguration.self, from: data)

    #expect(configuration.isEnabled)
    #expect(configuration.material == .glass)
    #expect(configuration.intensity == .moderate)
    #expect(configuration.cornerRadius == 26)
    #expect(configuration.noise == PrismNoise())
    #expect(configuration.outline == PrismOutline())
}

@Test func unknownPersistedEnumValuesUseSafeDefaults() throws {
    let data = Data(
        #"{"material":"future-material","intensity":"future-intensity","outline":{"style":"future-outline"}}"#.utf8
    )

    let configuration = try JSONDecoder().decode(PrismConfiguration.self, from: data)

    #expect(configuration.material == .solid)
    #expect(configuration.intensity == .moderate)
    #expect(configuration.outline.style == .solid)
}

@Test func meshPaletteAlwaysBuildsACompleteField() {
    let palette = PrismMeshPalette(colors: [.red, .blue])
    let backdrop: PrismBackdrop = .mesh(palette)

    #expect(palette.colors.count == PrismMeshPalette.colorCount)
    #expect(palette.colors[0] == .red)
    #expect(palette.colors[1] == .blue)
    #expect(palette.colors[2] == .red)

    if case let .mesh(colors) = backdrop {
        #expect(colors == palette.colors)
    } else {
        Issue.record("Expected a mesh backdrop")
    }
}

@Test func accessibilityUsesSystemValuesWithoutAnOverride() {
    let accessibility = PrismAccessibility.resolving(
        override: nil,
        reduceMotion: true,
        reduceTransparency: true
    )

    #expect(accessibility.reduceMotion)
    #expect(accessibility.reduceTransparency)
}

@Test func accessibilityOverrideWinsOverSystemValues() {
    let accessibility = PrismAccessibility.resolving(
        override: .default,
        reduceMotion: true,
        reduceTransparency: true
    )

    #expect(!accessibility.reduceMotion)
    #expect(!accessibility.reduceTransparency)
}
