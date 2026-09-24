# ``KitoConnectivity``

A real, on-device online and offline signal with banners, quality indicators, and retry helpers.

## Overview

KitoConnectivity wraps `NWPathMonitor` in an observable ``KitoConnectivityMonitor``
that reports whether the device is online, the ``KitoConnectionType`` in use,
and whether the path is expensive or in Low Data Mode. It is the production
counterpart to KitoNetKit, which only simulates network conditions in DEBUG
builds — use this package in release code.

Attach a banner once near the root of your app. It shows "You're offline" while
offline, "Back online" for a moment after reconnecting, and "Slow connection"
when the measured quality is poor:

```swift
@State private var connectivity = KitoConnectivityMonitor()

RootView()
    .kitoConnectivityBanner(connectivity, style: .floating) {
        Task { await reload() }
    }
```

Call `measureQuality()` to time a small HEAD request and grade the connection as
a ``KitoNetworkQuality``, then show it with ``KitoNetworkQualityIndicator``. For
network work, `retryWhenOnline(policy:onAttempt:_:)` waits for the network before
each attempt and backs off between failures according to a ``KitoRetryPolicy``.

For previews and demos, `KitoConnectivityMonitor(simulatedOnline:)` never watches
the real network, and `simulate(isOnline:connectionType:latency:isConstrained:)`
shows any state on an existing monitor until `stopSimulating()` is called.

## Topics

### Essentials

- ``KitoConnectivityMonitor``
- ``KitoConnectionType``

### Banners

- ``KitoConnectivityBanner``
- ``KitoConnectivityBannerState``
- ``KitoConnectivityBannerStyle``

### Network Quality

- ``KitoNetworkQuality``
- ``KitoNetworkQualityIndicator``
- ``KitoNetworkQualityIndicatorStyle``

### Retrying

- ``KitoRetryPolicy``
