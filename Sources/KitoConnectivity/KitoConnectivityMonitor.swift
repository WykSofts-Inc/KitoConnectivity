//
//  KitoConnectivityMonitor.swift
//  KitoConnectivity
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Network
import Observation
import KitoCore

/// A real, on-device online/offline signal via `NWPathMonitor` — the
/// production counterpart to KitoNetKit, which only *simulates* network
/// conditions in DEBUG. Pairs naturally with
/// `KitoEmptyStates.noConnection` for the "you're offline" screen.
@Observable
public final class KitoConnectivityMonitor: KitoViewModel {
    public private(set) var isOnline = true
    public private(set) var connectionType: KitoConnectionType = .unknown

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.wyksoftsinc.kitoconnectivity.monitor")

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            let type = KitoConnectionType(path: path)
            Task { @MainActor [weak self] in
                self?.isOnline = online
                self?.connectionType = type
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
