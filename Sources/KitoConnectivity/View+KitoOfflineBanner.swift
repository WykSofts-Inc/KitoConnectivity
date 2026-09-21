//
//  View+KitoOfflineBanner.swift
//  KitoConnectivity
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

private struct KitoOfflineBannerModifier: ViewModifier {
    @Bindable var monitor: KitoConnectivityMonitor

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if !monitor.isOnline {
                OfflineBanner()
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: monitor.isOnline)
    }
}

private struct OfflineBanner: View {
    @Environment(\.kitoTheme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.xs) {
            Image(systemName: "wifi.slash")
            Text("You're offline")
        }
        .font(theme.typography.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.xs)
        .frame(maxWidth: .infinity)
        .background(theme.colors.danger)
    }
}

public extension View {
    /// A thin "You're offline" banner that appears/disappears automatically
    /// as `monitor.isOnline` changes — attach once near your app's root.
    func kitoOfflineBanner(_ monitor: KitoConnectivityMonitor) -> some View {
        modifier(KitoOfflineBannerModifier(monitor: monitor))
    }
}
