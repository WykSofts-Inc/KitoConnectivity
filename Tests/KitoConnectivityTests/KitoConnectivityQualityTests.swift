//
//  KitoConnectivityQualityTests.swift
//  KitoConnectivity
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoConnectivity

final class KitoConnectivityQualityTests: XCTestCase {
    func testQualityGrading() {
        XCTAssertEqual(KitoNetworkQuality(isOnline: false, latency: 0.01), .offline)
        XCTAssertEqual(KitoNetworkQuality(isOnline: true, latency: nil), .good)
        XCTAssertEqual(KitoNetworkQuality(isOnline: true, latency: 0.03), .excellent)
        XCTAssertEqual(KitoNetworkQuality(isOnline: true, latency: 0.15), .good)
        XCTAssertEqual(KitoNetworkQuality(isOnline: true, latency: 0.4), .fair)
        XCTAssertEqual(KitoNetworkQuality(isOnline: true, latency: 1.8), .poor)
    }

    func testLowDataModeCapsAtFair() {
        XCTAssertEqual(KitoNetworkQuality(isOnline: true, latency: 0.03, isConstrained: true), .fair)
        XCTAssertEqual(KitoNetworkQuality(isOnline: true, latency: 1.8, isConstrained: true), .poor)
    }

    func testBarsAndOrdering() {
        XCTAssertEqual(KitoNetworkQuality.excellent.bars, 4)
        XCTAssertEqual(KitoNetworkQuality.offline.bars, 0)
        XCTAssertLessThan(KitoNetworkQuality.poor, .good)
    }

    func testRetryBackoff() {
        let policy = KitoRetryPolicy(maxAttempts: 5, initialDelay: .seconds(1), multiplier: 2, maxDelay: .seconds(5))
        XCTAssertEqual(policy.delay(afterAttempt: 1), .seconds(1))
        XCTAssertEqual(policy.delay(afterAttempt: 2), .seconds(2))
        XCTAssertEqual(policy.delay(afterAttempt: 3), .seconds(4))
        XCTAssertEqual(policy.delay(afterAttempt: 4), .seconds(5), "capped at maxDelay")
        XCTAssertEqual(KitoRetryPolicy(maxAttempts: 0).maxAttempts, 1)
    }

    func testBannerStateResolution() {
        XCTAssertEqual(KitoConnectivityBannerState.resolve(isOnline: false, recentlyReconnected: true, quality: .poor), .offline)
        XCTAssertEqual(KitoConnectivityBannerState.resolve(isOnline: true, recentlyReconnected: true, quality: .poor), .backOnline)
        XCTAssertEqual(KitoConnectivityBannerState.resolve(isOnline: true, recentlyReconnected: false, quality: .poor), .slow)
        XCTAssertNil(KitoConnectivityBannerState.resolve(isOnline: true, recentlyReconnected: false, quality: .poor, showsSlow: false))
        XCTAssertNil(KitoConnectivityBannerState.resolve(isOnline: true, recentlyReconnected: false, quality: .good))
    }
}

@MainActor
final class KitoConnectivitySimulationTests: XCTestCase {
    func testSimulatedMonitorReportsWhatItIsTold() {
        let monitor = KitoConnectivityMonitor(simulatedOnline: false)
        XCTAssertFalse(monitor.isOnline)
        XCTAssertEqual(monitor.quality, .offline)

        monitor.simulate(isOnline: true, connectionType: .cellular, latency: 1.2)
        XCTAssertTrue(monitor.isOnline)
        XCTAssertEqual(monitor.connectionType, .cellular)
        XCTAssertEqual(monitor.quality, .poor)
        XCTAssertNotNil(monitor.lastReconnectedAt)
    }

    func testRetryWhenOnlineWaitsForTheNetworkThenRetries() async throws {
        let monitor = KitoConnectivityMonitor(simulatedOnline: false)
        var calls = 0
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(50))
            monitor.simulate(isOnline: true)
        }
        let value = try await monitor.retryWhenOnline(policy: KitoRetryPolicy(maxAttempts: 3, initialDelay: .milliseconds(10))) { () async throws -> String in
            calls += 1
            if calls < 2 { throw URLError(.timedOut) }
            return "synced"
        }
        XCTAssertEqual(value, "synced")
        XCTAssertEqual(calls, 2)
    }
}
