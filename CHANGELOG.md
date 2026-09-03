# Changelog

All notable changes to PrismCore will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses semantic versioning.

## [Unreleased]

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
