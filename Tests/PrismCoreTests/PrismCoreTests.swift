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

    let result = requested.normalized()

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

    let result = requested.normalized()

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

    let result = requested.normalized(
        for: PrismAccessibility(reduceTransparency: true)
    )

    #expect(result.material == .solid)
}

@Test func glassRequiresImmersiveBackground() {
    let requested = PrismConfiguration(
        isEnabled: true,
        immersiveBackgroundEnabled: false,
        material: .glass
    )

    #expect(requested.normalized().material == .solid)
}

@Test func removedMaterialValueDecodesToSolid() throws {
    let data = Data(
        #"{"isEnabled":true,"immersiveBackgroundEnabled":false,"material":"material","materialStyle":"ultraThin","intensity":"moderate","cornerRadius":26,"noise":{"isEnabled":false,"opacity":0.6},"outline":{"isEnabled":false,"width":1.3,"style":"solid"},"highlightsEnabled":false}"#.utf8
    )

    let configuration = try JSONDecoder().decode(PrismConfiguration.self, from: data)

    #expect(configuration.material == .solid)
}

@Test func liquidDisablesOutlineAndNoise() {
    let requested = PrismConfiguration(
        isEnabled: true,
        immersiveBackgroundEnabled: true,
        material: .liquid,
        noise: PrismNoise(isEnabled: true),
        outline: PrismOutline(isEnabled: true)
    )

    let result = requested.normalized()

    #expect(!result.noise.isEnabled)
    #expect(!result.outline.isEnabled)
}
