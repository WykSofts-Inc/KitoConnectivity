# KitoConnectivity

A real, on-device online/offline signal via `NWPathMonitor` — the production
counterpart to [KitoNetKit](https://github.com/WykSofts-Inc/KitoNetKit),
which only *simulates* network conditions in DEBUG builds. Use this one in
release code.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoConnectivity.git", from: "1.1.0"),
```

## Banners: offline, back online, slow

```swift
@State private var connectivity = KitoConnectivityMonitor()

RootView()
    .kitoConnectivityBanner(connectivity, style: .floating) { Task { await reload() } }
```

"You're offline" while offline, "Back online" for a moment after reconnecting,
"Slow connection" when the measured quality is poor. Styles: `.bar`, `.floating`
(with Retry) and `.pill`. Drive one yourself with `.kitoConnectivityBanner(state:style:)`
or place `KitoConnectivityBanner(.offline, style: .pill)` anywhere.

## Network quality

```swift
await connectivity.measureQuality()          // times a small HEAD request
KitoNetworkQualityIndicator(monitor: connectivity, style: .pill)   // .bars, .pill, .gauge
```

`quality` is `.offline`, `.poor`, `.fair`, `.good` or `.excellent`; Low Data Mode
caps it at fair. The monitor also reports `isExpensive` and `isConstrained`.

## Retry when online

```swift
let feed = try await connectivity.retryWhenOnline(policy: .standard) {
    try await api.fetchFeed()
}
```

Waits for the network before every attempt and backs off 1 s, 2 s, 4 s
between failures (`KitoRetryPolicy(maxAttempts:initialDelay:multiplier:maxDelay:)`).
`await connectivity.waitUntilOnline()` on its own just waits.

## Previews and demos

`KitoConnectivityMonitor(simulatedOnline: false)` never watches the real network;
call `simulate(isOnline:connectionType:latency:)` on any monitor to show a state
and `stopSimulating()` to go back to the real signal.

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
