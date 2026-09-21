// swift-tools-version: 5.9
//
//  Package.swift
//  KitoConnectivity
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "KitoConnectivity",
    platforms: [.iOS(.v17)],
    products: [.library(name: "KitoConnectivity", targets: ["KitoConnectivity"])],
    dependencies: [
        .package(url: "https://github.com/WykSofts-Inc/KitoCore.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "KitoConnectivity", dependencies: [.product(name: "KitoCore", package: "KitoCore")]),
        .testTarget(name: "KitoConnectivityTests", dependencies: ["KitoConnectivity"]),
    ]
)
