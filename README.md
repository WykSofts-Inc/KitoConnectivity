# KitoConnectivity

A real, on-device online/offline signal via `NWPathMonitor` — the production
counterpart to [KitoNetKit](https://github.com/WykSofts-Inc/KitoNetKit),
which only *simulates* network conditions in DEBUG builds. Use this one in
release code.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoConnectivity.git", from: "1.0.0"),
```

## Samples

**A thin offline banner, wired in once:**
```swift
@State private var connectivity = KitoConnectivityMonitor()

RootView()
    .kitoOfflineBanner(connectivity)
```

**Gate a screen's content on connectivity, using KitoEmptyStates:**
```swift
struct FeedScreen: View {
    @State private var connectivity = KitoConnectivityMonitor()
    @State private var viewModel = FeedViewModel()

    var body: some View {
        if connectivity.isOnline {
            FeedList(viewModel: viewModel)
        } else {
            KitoEmptyStateView.noConnection { Task { await viewModel.reload() } }
        }
    }
}
```

**React to connection type (e.g. defer large downloads on cellular):**
```swift
if connectivity.connectionType == .cellular {
    showLowDataWarning = true
}
```

## License

MIT
