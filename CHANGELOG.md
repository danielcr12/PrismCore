# Changelog

All notable changes to PrismCore will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses semantic versioning.

## [1.0.2] - 2026-09-17

### Added

- Added immutable resolved configuration, a shared `PrismSurfaceStyle`, validated
  mesh palettes, and rendering quality controls for optional full-screen shader
  work.

### Changed

- Prism now follows system Reduce Motion and Reduce Transparency settings unless
  a preview or test explicitly overrides them.
- Prism surfaces share the same automatic style mapping as cards and retain
  structural identity when their treatment changes.
- Configuration decoding now supplies safe defaults for missing or unknown
  persisted values.
- Limited automatic debanding to layered gradients while retaining the
  original procedural-noise treatment.

### Deprecated

- Deprecated `PrismLiquidStyle` in favor of `PrismGlassStyle`,
  `normalized(for:)` in favor of immutable `resolved(for:)`, and the former
  labeled `prismSurface` overloads.

## [1.0.1] - 2026-09-04

### Fixed

- Lowered the package manifest requirement from Swift tools 6.4 to 6.3 so
  PrismCore can resolve in Xcode installations using Swift 6.3.3.

## [1.0.0] - 2026-09-03

### Added

- Documented the public PrismCore API and background-processing model.
- Added a GitHub-ready package dependency declaration for OKLCHKit.

### Changed

- PrismCore now resolves `PrismBackgroundFoundation` from its versioned GitHub
  package so stable Swift Package Manager releases can be consumed directly.
- Shared background construction now has one documented contract across solid,
  layered-gradient, and mesh rendering.
- Adaptive palette generation, the standard system-background wash, and the
  Metal debanding/noise stages are documented as separate processing steps.
