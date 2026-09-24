//
//  KitoConnectivityMonitor.swift
//  KitoConnectivity
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation
import Network
import Observation
import KitoCore

/// A real, on-device online/offline signal via `NWPathMonitor` — the
/// production counterpart to KitoNetKit, which only *simulates* network
/// conditions in DEBUG. Pairs naturally with
/// `KitoEmptyStates.noConnection` for the "you're offline" screen.
///
/// Beyond online/offline it reports Low Data Mode, expensive (cellular or
/// hotspot) paths, a measured round-trip `latency` and the resulting
/// `quality`, and can wait for — or retry an operation once — the network
/// is back (`waitUntilOnline()`, `retryWhenOnline(policy:_:)`).
@Observable
public final class KitoConnectivityMonitor: KitoViewModel {
    public private(set) var isOnline = true
    public private(set) var connectionType: KitoConnectionType = .unknown
    /// Cellular, or Wi-Fi from a phone's hotspot.
    public private(set) var isExpensive = false
    /// Low Data Mode is on.
    public private(set) var isConstrained = false
    /// The last measured round trip, from `measureQuality()`; `nil` until measured.
    public private(set) var latency: TimeInterval?
    public private(set) var quality: KitoNetworkQuality = .good
    /// When the connection last came back — drives "Back online".
    public private(set) var lastReconnectedAt: Date?
    /// True after `simulate(…)`, until `stopSimulating()`: real path updates are ignored.
    public private(set) var isSimulating = false

    @ObservationIgnored private let monitor: NWPathMonitor?
    @ObservationIgnored private let queue = DispatchQueue(label: "com.wyksoftsinc.kitoconnectivity.monitor")
    @ObservationIgnored private var waiters: [CheckedContinuation<Void, Never>] = []
    @ObservationIgnored private var lastReal: (online: Bool, type: KitoConnectionType, expensive: Bool, constrained: Bool) = (true, .unknown, false, false)

    public init() {
        let monitor = NWPathMonitor()
        self.monitor = monitor
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            let type = KitoConnectionType(path: path)
            let expensive = path.isExpensive
            let constrained = path.isConstrained
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.lastReal = (online, type, expensive, constrained)
                guard !self.isSimulating else { return }
                self.apply(online: online, type: type, expensive: expensive, constrained: constrained)
            }
        }
        monitor.start(queue: queue)
    }

    /// A monitor that never watches the real network — for previews and demos. Drive it with
    /// `simulate(…)`.
    public init(simulatedOnline isOnline: Bool, connectionType: KitoConnectionType = .wifi, latency: TimeInterval? = 0.06) {
        monitor = nil
        self.isOnline = isOnline
        self.connectionType = isOnline ? connectionType : .unknown
        self.isExpensive = isOnline && connectionType == .cellular
        self.latency = latency
        self.isSimulating = true
        self.quality = KitoNetworkQuality(isOnline: isOnline, latency: latency, isConstrained: false)
    }

    deinit {
        monitor?.cancel()
    }

    /// Pretends the network is in this state (the real signal is ignored until
    /// `stopSimulating()`), so you can see every banner and indicator on demand.
    @MainActor
    public func simulate(isOnline: Bool, connectionType: KitoConnectionType = .wifi, latency: TimeInterval? = 0.06, isConstrained: Bool = false) {
        isSimulating = true
        self.latency = isOnline ? latency : nil
        apply(online: isOnline, type: isOnline ? connectionType : .unknown, expensive: connectionType == .cellular, constrained: isConstrained)
    }

    /// Goes back to the real signal.
    @MainActor
    public func stopSimulating() {
        guard monitor != nil else { return }
        isSimulating = false
        latency = nil
        apply(online: lastReal.online, type: lastReal.type, expensive: lastReal.expensive, constrained: lastReal.constrained)
    }

    /// Times a small HEAD request and updates `latency` and `quality`.
    @MainActor
    public func measureQuality(
        using url: URL = URL(string: "https://www.apple.com/library/test/success.html")!,
        timeout: TimeInterval = 5
    ) async {
        guard !isSimulating else { return }
        guard isOnline else {
            latency = nil
            quality = .offline
            return
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: timeout)
        request.httpMethod = "HEAD"
        let clock = ContinuousClock()
        let start = clock.now
        do {
            _ = try await URLSession.shared.data(for: request)
            let elapsed = start.duration(to: clock.now)
            latency = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
        } catch {
            latency = timeout
        }
        quality = KitoNetworkQuality(isOnline: isOnline, latency: latency, isConstrained: isConstrained)
    }

    /// Returns as soon as the device is online (immediately if it already is).
    @MainActor
    public func waitUntilOnline() async {
        guard !isOnline else { return }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    /// Runs `operation`, and if it throws, waits until the device is online, backs off per
    /// `policy`, and tries again — up to `policy.maxAttempts` times. Rethrows the last error.
    @MainActor
    public func retryWhenOnline<T>(
        policy: KitoRetryPolicy = .standard,
        onAttempt: ((Int) -> Void)? = nil,
        _ operation: () async throws -> T
    ) async throws -> T {
        var attempt = 1
        while true {
            await waitUntilOnline()
            onAttempt?(attempt)
            do {
                return try await operation()
            } catch {
                guard attempt < policy.maxAttempts else { throw error }
                try await Task.sleep(for: policy.delay(afterAttempt: attempt))
                attempt += 1
            }
        }
    }

    @MainActor
    private func apply(online: Bool, type: KitoConnectionType, expensive: Bool, constrained: Bool) {
        if online && !isOnline { lastReconnectedAt = Date() }
        isOnline = online
        connectionType = type
        isExpensive = expensive
        isConstrained = constrained
        quality = KitoNetworkQuality(isOnline: online, latency: latency, isConstrained: constrained)
        if online && !waiters.isEmpty {
            let ready = waiters
            waiters.removeAll()
            ready.forEach { $0.resume() }
        }
    }
}
