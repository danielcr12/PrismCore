# PrismCore

PrismCore is a SwiftUI appearance and surface system for iOS 26 and later. It
provides a small, typed rendering contract for adaptive backgrounds, cards,
list rows, outlines, dividers, and Liquid Glass surfaces.

The package is designed around one shared configuration and palette so an app
can change its appearance without scattering rendering policy across feature
views.

## What it provides

- Solid, layered-gradient, and mesh backdrops.
- A shared background construction pipeline for screen and immersive artwork
  backgrounds.
- OKLCHKit-backed color rendering and adaptive light/dark palettes derived from
  semantic colors.
- A standard system-background wash that keeps translucent compositions
  consistent across appearances.
- Optional Metal debanding dither and parameterized noise.
- Configurable solid, glass, and Liquid Glass card treatments.
- Automatic and explicit card highlights.
- Solid, dotted, and segmented outlines.
- Prism list-row backgrounds and intensity-aware dividers.
- Accessibility-aware Liquid Glass surfaces with a solid fallback when Reduce
  Transparency is enabled.
- Swift 6 value types with `Equatable`, `Codable`, and `Sendable` conformances
  where they form part of the public configuration contract.

## Requirements

- iOS 26.0+
- Swift 6.4+
- Xcode 27+

PrismCore uses [OKLCHKit](https://github.com/danielcr12/OKLCHKit) for color
rendering, perceptual color conversion, and adaptive palette construction. The
package includes the shared
`PrismBackgroundFoundation` implementation as a local package dependency so a
GitHub checkout remains self-contained.

## Installation

In Xcode, choose **File > Add Package Dependencies**, then enter:

```text
https://github.com/danielcr12/PrismCore.git
```

Or add PrismCore to another `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/danielcr12/PrismCore.git",
        from: "0.1.0"
    )
]
```

Then add the `PrismCore` product to the target that uses it.

## Basic setup

Inject one configuration, palette, and accessibility snapshot at the root of
the view hierarchy:

```swift
import SwiftUI
import PrismCore

struct ExampleView: View {
    private let configuration = PrismConfiguration(
        isEnabled: true,
        immersiveBackgroundEnabled: true,
        material: .glass,
        intensity: .moderate,
        highlightsEnabled: true
    )

    private let palette = PrismPalette(
        accentColor: .blue,
        backdrop: .gradient(
            PrismGradientBackdrop(
                topColor: .blue,
                middleColor: .indigo,
                bottomColor: .purple,
                highlightColor: .white.opacity(0.30),
                glowColor: .cyan
            )
        )
    )

    var body: some View {
        VStack(spacing: 16) {
            Text("Prism surface")
                .padding()
                .prismCard(.glass, highlight: .whenEnabled(.blue))

            Text("Liquid Glass surface")
                .padding()
                .prismSurface(style: .regular, interactive: true)
        }
        .padding()
        .prismEnvironment(
            configuration: configuration,
            palette: palette,
            accessibility: .default
        )
        .prismScreenBackground()
    }
}
```

`prismScreenBackground()` is intended for a screen or scroll-container root.
The modifier paints the system grouped background first, then applies the
configured backdrop and optional shader effects while ignoring the safe area.

## Background processing model

Prism separates palette construction from rendering:

1. A caller supplies a semantic base color or an already-resolved palette.
2. `PrismAdaptiveBackgroundPalette` resolves the color for the active
   appearance and derives lightness/chroma-adjusted colors in OKLCH.
3. `PrismLayeredGradientBackground` or `PrismAdaptiveMeshBackground` composes
   the top, middle, bottom, highlight, and glow fields.
4. `PrismBackgroundWash` blends the complete composition over the system
   background at one shared opacity.
5. PrismCore can apply a debanding dither to the backdrop and parameterized
   noise as a separate, non-interactive overlay.

This keeps solid, gradient, and mesh backgrounds on the same visual contract.
On platforms where mesh gradients are unavailable, the adaptive background
uses a layered gradient transition instead.

## Configuration and accessibility

`PrismConfiguration.normalized(for:)` is the policy boundary used by the
renderers. It clamps numeric values and resolves incompatible combinations:

- Disabling Prism forces a solid material and turns off immersive background,
  noise, outlines, and highlights.
- Glass requires an enabled immersive background.
- Reduce Transparency forces solid rendering.
- Liquid Glass disables noise and outlines.
- Corner radius is clamped to 16...36, noise opacity to 0...1, and outline
  width to 1...5.

The normalization step lets callers persist user-facing settings while keeping
renderers safe when accessibility settings or older persisted values change.

## Public modifiers

```swift
content.prismCard(
    .automatic,
    highlight: .none,
    outline: .automatic
)

content.prismOutline(.always, style: .segmented)
content.prismListRow()
content.prismSurface(
    style: .clear,
    tint: .blue,
    interactive: true,
    shape: .capsule
)
```

Use `PrismCardStyle.automatic` when the card should follow the injected
configuration. Use `.clear`, `.solid`, `.glass`, or `.liquid(...)` for a
specific surface treatment. `PrismHighlightStyle.whenEnabled` follows the
configuration's `highlightsEnabled` value; `.always` is useful for semantic
emphasis that should not depend on the global toggle.

## Package layout

```text
Sources/PrismCore/                         Public PrismCore API and modifiers
Sources/PrismCore/Resources/Noise.metal    Debanding and noise shaders
PrismBackgroundFoundation/                 Shared background construction
Tests/PrismCoreTests/                      Configuration policy tests
```

`PrismBackgroundFoundation` is also used by the companion ImmersiveKit
package to keep screen and artwork background construction aligned.

## Development

From the package directory:

```sh
swift package dump-package
swift test
```

Open the package in Xcode for SwiftUI previews and platform-specific rendering
inspection. Runtime appearance, accessibility, and shader behavior should be
validated on a supported iOS device or simulator in addition to source and
test checks.

## License

PrismCore is released under the MIT License. See [LICENSE](LICENSE).
