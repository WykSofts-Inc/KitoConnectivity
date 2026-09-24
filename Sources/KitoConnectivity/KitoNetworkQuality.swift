//
//  KitoNetworkQuality.swift
//  KitoConnectivity
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// How usable the connection is, from offline to excellent.
public enum KitoNetworkQuality: Int, CaseIterable, Comparable, Sendable {
    case offline, poor, fair, good, excellent

    /// Grades a connection by its round trip. Unmeasured counts as good; Low Data Mode caps it
    /// at fair, since apps should hold back either way.
    public init(isOnline: Bool, latency: TimeInterval?, isConstrained: Bool = false) {
        guard isOnline else { self = .offline; return }
        let graded: KitoNetworkQuality
        switch latency {
        case .none: graded = .good
        case .some(let value) where value < 0.08: graded = .excellent
        case .some(let value) where value < 0.2: graded = .good
        case .some(let value) where value < 0.6: graded = .fair
        case .some: graded = .poor
        }
        self = isConstrained ? min(graded, .fair) : graded
    }

    /// Signal bars out of four.
    public var bars: Int { rawValue }

    public var label: String {
        switch self {
        case .offline: return "Offline"
        case .poor: return "Poor"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }

    public static func < (lhs: KitoNetworkQuality, rhs: KitoNetworkQuality) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// How long to wait between attempts: `initialDelay`, then multiplied each time, capped.
public struct KitoRetryPolicy: Equatable, Sendable {
    public var maxAttempts: Int
    public var initialDelay: Duration
    public var multiplier: Double
    public var maxDelay: Duration

    public init(maxAttempts: Int = 4, initialDelay: Duration = .seconds(1), multiplier: Double = 2, maxDelay: Duration = .seconds(30)) {
        self.maxAttempts = max(maxAttempts, 1)
        self.initialDelay = initialDelay
        self.multiplier = max(multiplier, 1)
        self.maxDelay = maxDelay
    }

    /// Four attempts: 1 s, 2 s, 4 s apart.
    public static let standard = KitoRetryPolicy()

    /// The pause after attempt number `attempt` (1-based) fails.
    public func delay(afterAttempt attempt: Int) -> Duration {
        let factor = pow(multiplier, Double(max(attempt - 1, 0)))
        return min(initialDelay * factor, maxDelay)
    }
}

/// Which connectivity banner to show, if any.
public enum KitoConnectivityBannerState: Equatable, Sendable, CaseIterable {
    case offline, backOnline, slow

    /// Offline wins; then a short "back online" after a reconnect; then "slow" on a poor line.
    public static func resolve(isOnline: Bool, recentlyReconnected: Bool, quality: KitoNetworkQuality, showsSlow: Bool = true) -> KitoConnectivityBannerState? {
        if !isOnline { return .offline }
        if recentlyReconnected { return .backOnline }
        if showsSlow && quality == .poor { return .slow }
        return nil
    }
}

public extension KitoConnectionType {
    var displayName: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Mobile data"
        case .wiredEthernet: return "Ethernet"
        case .unknown: return "Unknown"
        }
    }

    var systemImage: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .wiredEthernet: return "cable.connector"
        case .unknown: return "network"
        }
    }
}
