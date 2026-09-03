# PrismBackgroundFoundation

PrismBackgroundFoundation contains the shared SwiftUI background construction
used by PrismCore and ImmersiveKit. It keeps adaptive palettes, layered
gradients, mesh transitions, and the standard system-background wash visually
consistent across screens and artwork backgrounds.

## Requirements

- iOS 18.0+
- macOS 14.0+
- Swift 6.3+

The package uses [OKLCHKit](https://github.com/danielcr12/OKLCHKit) for
perceptual color conversion and adaptive palette generation.

## Installation

Add the package repository to your Swift package or Xcode project:

```text
https://github.com/danielcr12/PrismBackgroundFoundation.git
```

Then import the product:

```swift
import PrismBackgroundFoundation
```

## Development

```sh
swift package dump-package
swift test
```

## License

PrismBackgroundFoundation is released under the MIT License. See [LICENSE](LICENSE).
