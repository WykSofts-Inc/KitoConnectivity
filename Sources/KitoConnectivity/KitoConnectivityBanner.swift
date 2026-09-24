//
//  KitoConnectivityBanner.swift
//  KitoConnectivity
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// How a connectivity banner looks.
public enum KitoConnectivityBannerStyle: String, CaseIterable, Sendable {
    /// A full-width strip across the top.
    case bar
    /// A floating card with a message and, when offline, a Retry button.
    case floating
    /// A small dark capsule, like the Dynamic Island.
    case pill
}

/// "You're offline", "Back online" or "Slow connection", in one of three looks, with an
/// animated icon for each (still under Reduce Motion).
public struct KitoConnectivityBanner: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let state: KitoConnectivityBannerState
    let style: KitoConnectivityBannerStyle
    let onRetry: (() -> Void)?

    @State private var pulse = false

    public init(_ state: KitoConnectivityBannerState, style: KitoConnectivityBannerStyle = .floating, onRetry: (() -> Void)? = nil) {
        self.state = state
        self.style = style
        self.onRetry = onRetry
    }

    private var color: Color {
        switch state {
        case .offline: return theme.colors.danger
        case .backOnline: return theme.colors.success
        case .slow: return theme.colors.warning
        }
    }

    private var title: String {
        switch state {
        case .offline: return "You're offline"
        case .backOnline: return "Back online"
        case .slow: return "Slow connection"
        }
    }

    private var message: String {
        switch state {
        case .offline: return "Showing saved data. We'll sync when you're back."
        case .backOnline: return "You're connected. Everything's up to date."
        case .slow: return "Photos may take a moment to load."
        }
    }

    private var symbol: String {
        switch state {
        case .offline: return "wifi.slash"
        case .backOnline: return "wifi"
        case .slow: return "tortoise.fill"
        }
    }

    public var body: some View {
        Group {
            switch style {
            case .bar: bar
            case .floating: floating
            case .pill: pill
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
        .accessibilityAddTraits(.updatesFrequently)
        .onAppear { pulse = !reduceMotion }
    }

    @ViewBuilder
    private var icon: some View {
        let image = Image(systemName: symbol)
        switch state {
        case .offline:
            image.symbolEffect(.pulse, options: .repeating, isActive: pulse)
        case .backOnline:
            image.symbolEffect(.bounce, value: pulse)
        case .slow:
            image.symbolEffect(.variableColor.iterative, options: .repeating, isActive: pulse)
        }
    }

    private var bar: some View {
        HStack(spacing: theme.spacing.sm) {
            icon.font(.system(size: 13, weight: .bold))
            Text(title).font(.system(size: 13, weight: .semibold))
            if state == .offline, let onRetry {
                Spacer(minLength: 0)
                Button("Retry", action: onRetry)
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.white.opacity(0.22)))
                    .buttonStyle(.plain)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, theme.spacing.lg)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background(color.gradient)
    }

    private var floating: some View {
        HStack(spacing: theme.spacing.md) {
            ZStack {
                Circle().fill(color.opacity(0.16)).frame(width: 42, height: 42)
                Circle().stroke(color.opacity(0.35), lineWidth: 1).frame(width: 42, height: 42)
                    .scaleEffect(pulse && state == .offline ? 1.25 : 1)
                    .opacity(pulse && state == .offline ? 0 : 1)
                    .animation(pulse && state == .offline ? .easeOut(duration: 1.4).repeatForever(autoreverses: false) : .default, value: pulse)
                icon.font(.system(size: 17, weight: .semibold)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(theme.typography.bodyEmphasized).foregroundStyle(theme.colors.onSurface)
                Text(message).font(theme.typography.caption).foregroundStyle(theme.colors.onSurface.opacity(0.62)).lineLimit(2)
            }
            Spacer(minLength: 0)
            if state == .offline, let onRetry {
                Button("Retry", action: onRetry)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.colors.surface)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 34)
                    .background(Capsule().fill(theme.colors.onSurface))
                    .buttonStyle(.plain)
            }
        }
        .padding(theme.spacing.md)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(color.opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
    }

    private var pill: some View {
        HStack(spacing: 8) {
            icon.font(.system(size: 13, weight: .bold)).foregroundStyle(color)
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
            if state == .offline {
                Circle().fill(color).frame(width: 6, height: 6)
                    .opacity(pulse ? 0.3 : 1)
                    .animation(pulse ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: pulse)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 36)
        .background(Capsule().fill(Color.black))
        .overlay(Capsule().strokeBorder(.white.opacity(0.08), lineWidth: 1))
        .shadow(color: color.opacity(0.35), radius: 12, y: 4)
    }
}

// MARK: - Modifiers

private struct KitoConnectivityBannerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let state: KitoConnectivityBannerState?
    let style: KitoConnectivityBannerStyle
    let onRetry: (() -> Void)?

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            ZStack {
                if let state {
                    KitoConnectivityBanner(state, style: style, onRetry: onRetry)
                        .padding(.horizontal, style == .bar ? 0 : 16)
                        .padding(.top, style == .bar ? 0 : 8)
                        .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
                        .id(state)
                }
            }
            .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.45, dampingFraction: 0.82), value: state)
        }
    }
}

private struct KitoLiveConnectivityBannerModifier: ViewModifier {
    @Bindable var monitor: KitoConnectivityMonitor
    let style: KitoConnectivityBannerStyle
    let showsSlow: Bool
    let backOnlineDuration: Duration
    let onRetry: (() -> Void)?

    @State private var recentlyReconnected = false

    func body(content: Content) -> some View {
        content
            .modifier(KitoConnectivityBannerModifier(
                state: KitoConnectivityBannerState.resolve(isOnline: monitor.isOnline, recentlyReconnected: recentlyReconnected, quality: monitor.quality, showsSlow: showsSlow),
                style: style,
                onRetry: onRetry
            ))
            .onChange(of: monitor.isOnline) { wasOnline, isOnline in
                guard isOnline && !wasOnline else { return }
                recentlyReconnected = true
                Task {
                    try? await Task.sleep(for: backOnlineDuration)
                    recentlyReconnected = false
                }
            }
    }
}

public extension View {
    /// Shows "You're offline" while the monitor is offline, "Back online" for a moment after it
    /// reconnects, and "Slow connection" when the measured quality is poor.
    func kitoConnectivityBanner(
        _ monitor: KitoConnectivityMonitor,
        style: KitoConnectivityBannerStyle = .floating,
        showsSlow: Bool = true,
        backOnlineDuration: Duration = .seconds(2.5),
        onRetry: (() -> Void)? = nil
    ) -> some View {
        modifier(KitoLiveConnectivityBannerModifier(monitor: monitor, style: style, showsSlow: showsSlow, backOnlineDuration: backOnlineDuration, onRetry: onRetry))
    }

    /// Shows a banner for a state you drive yourself; `nil` hides it.
    func kitoConnectivityBanner(
        state: KitoConnectivityBannerState?,
        style: KitoConnectivityBannerStyle = .floating,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        modifier(KitoConnectivityBannerModifier(state: state, style: style, onRetry: onRetry))
    }
}
