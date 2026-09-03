# Contributing

PrismCore is a focused SwiftUI package. Keep public APIs small, prefer typed
value semantics, and preserve Swift 6 strict-concurrency compatibility.

Before opening a change:

```sh
swift package dump-package
swift test
```

Changes to rendering behavior should include focused tests for configuration
normalization where possible and should describe any required device or
simulator visual validation. Avoid changing persisted configuration values or
public symbols without documenting the migration path.
