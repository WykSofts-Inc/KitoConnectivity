//
//  KitoConnectionType.swift
//  KitoConnectivity
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Network

public enum KitoConnectionType: Sendable {
    case wifi
    case cellular
    case wiredEthernet
    case unknown

    init(path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            self = .wifi
        } else if path.usesInterfaceType(.cellular) {
            self = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            self = .wiredEthernet
        } else {
            self = .unknown
        }
    }
}
