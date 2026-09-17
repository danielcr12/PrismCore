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
- Quality-controlled Metal debanding dither and parameterized noise.
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
- Swift 6.3+
- Xcode 26+

PrismCore uses [OKLCHKit](https://github.com/danielcr12/OKLCHKit) for color
rendering, perceptual color conversion, and adaptive palette construction. Its
shared background construction is provided by the versioned
[PrismBackgroundFoundation](https://github.com/danielcr12/PrismBackgroundFoundation)
package.

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
        from: "1.0.2"
    )
]
```

Then add the `PrismCore` product to the target that uses it.

## Basic setup

Inject one configuration and palette at the root of the view hierarchy.
Prism follows the system Reduce Motion and Reduce Transparency settings by
default:

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
                .prismSurface(.liquid(.regular), interactive: true)
        }
        .padding()
        .prismEnvironment(
            configuration: configuration,
            palette: palette
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

`PrismConfiguration.resolved(for:)` creates immutable, render-ready state. It
clamps numeric values while keeping persisted user choices separate from the
values consumed by renderers:

- Disabling Prism forces a solid material and turns off immersive background,
  noise, outlines, and highlights.
- Reduce Transparency forces solid rendering.
- Corner radius is clamped to 16...36, noise opacity to 0...1, and outline
  width to 1...5.

Surface material and immersive-background preferences are independent. A caller
can therefore use translucent or Liquid Glass surfaces without enabling an
immersive screen background. Prism also tolerates missing and unknown values in
older persisted configuration payloads by falling back to safe defaults.

Pass an explicit `PrismAccessibility` value to `prismEnvironment` only when a
preview or test needs to override the system settings.

## Rendering quality

`PrismRenderingQuality.automatic` applies debanding only to layered gradients
and honors the configured noise toggle. Use `.reduced` to disable optional
full-screen shader work, or `.full` to apply debanding to every immersive
backdrop. Configure it at the environment boundary:

```swift
.prismEnvironment(
    configuration: configuration,
    palette: palette,
    renderingQuality: .reduced
)
```

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
    .liquid(.clear),
    tint: .blue,
    interactive: true,
    shape: .capsule
)
```

Use `PrismSurfaceStyle.automatic` when a card or surface should follow the injected
configuration. Use `.clear`, `.solid`, `.glass`, or `.liquid(...)` for a
specific treatment. `.glass` is Prism's translucent fill, while `.liquid(...)`
uses SwiftUI Liquid Glass. `PrismHighlightStyle.whenEnabled` follows the
configuration's `highlightsEnabled` value; `.always` is useful for semantic
emphasis that should not depend on the global toggle.

Use `PrismMeshPalette` to canonicalize a mesh's colors once instead of rebuilding
its 16-color field during view updates:

```swift
let mesh = PrismMeshPalette(colors: [.blue, .indigo, .purple])
let palette = PrismPalette(accentColor: .blue, backdrop: .mesh(mesh))
```

## Package layout

```text
Sources/PrismCore/                         Public PrismCore API and modifiers
Sources/PrismCore/Resources/Noise.metal    Debanding and noise shaders
Tests/PrismCoreTests/                      Configuration policy tests
```

`PrismBackgroundFoundation` is also used by the companion ImmersiveKit
package to keep screen and artwork background construction aligned.

## Development

Because PrismCore is iOS-only, run its tests against an iOS simulator rather
than using the macOS-hosted `swift test` command:

```sh
swift package dump-package
xcodebuild \
  -scheme PrismCore \
  -destination 'platform=iOS Simulator,name=iPhone 17e' \
  test
```

Open the package in Xcode for SwiftUI previews and platform-specific rendering
inspection. Runtime appearance, accessibility, and shader behavior should be
validated on a supported iOS device or simulator in addition to source and
test checks.

## License

PrismCore is released under the MIT License. See [LICENSE](LICENSE).
