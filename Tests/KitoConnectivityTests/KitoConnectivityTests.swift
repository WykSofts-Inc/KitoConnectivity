//
//  KitoConnectivityTests.swift
//  KitoConnectivity
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoConnectivity

@MainActor
final class KitoConnectivityTests: XCTestCase {
    func testMonitorDefaultsToOnlineBeforeFirstCallback() {
        // NWPathMonitor's first callback is asynchronous; the monitor must
        // report a sane default (online) rather than nil/undefined in the
        // gap before that first callback arrives.
        let monitor = KitoConnectivityMonitor()
        XCTAssertTrue(monitor.isOnline)
    }

    func testMonitorDefaultsToUnknownConnectionType() {
        let monitor = KitoConnectivityMonitor()
        XCTAssertEqual(monitor.connectionType, .unknown)
    }
}
