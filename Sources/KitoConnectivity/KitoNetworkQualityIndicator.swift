//
//  KitoNetworkQualityIndicator.swift
//  KitoConnectivity
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import SwiftUI
import KitoCore

/// How a network-quality indicator looks.
public enum KitoNetworkQualityIndicatorStyle: String, CaseIterable, Sendable {
    /// Four signal bars.
    case bars
    /// Bars and a label in a capsule.
    case pill
    /// A half-circle gauge with a needle.
    case gauge
}

/// Signal bars, a labelled pill or a gauge for a `KitoNetworkQuality`, coloured red to green.
public struct KitoNetworkQualityIndicator: View {
    @Environment(\.kitoTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let quality: KitoNetworkQuality
    let style: KitoNetworkQualityIndicatorStyle
    let latency: TimeInterval?

    public init(_ quality: KitoNetworkQuality, style: KitoNetworkQualityIndicatorStyle = .bars, latency: TimeInterval? = nil) {
        self.quality = quality
        self.style = style
        self.latency = latency
    }

    /// The monitor's current quality and latency.
    public init(monitor: KitoConnectivityMonitor, style: KitoNetworkQualityIndicatorStyle = .bars) {
        self.init(monitor.quality, style: style, latency: monitor.latency)
    }

    private var color: Color {
        switch quality {
        case .offline: return theme.colors.onSurface.opacity(0.35)
        case .poor: return theme.colors.danger
        case .fair: return theme.colors.warning
        case .good, .excellent: return theme.colors.success
        }
    }

    private var latencyText: String? {
        guard let latency, quality != .offline else { return nil }
        return "\(Int((latency * 1000).rounded())) ms"
    }

    public var body: some View {
        Group {
            switch style {
            case .bars: bars(height: 18)
            case .pill: pill
            case .gauge: gauge
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.75), value: quality)
        .accessibilityElement()
        .accessibilityLabel("Connection \(quality.label)\(latencyText.map { ", \($0)" } ?? "")")
    }

    private func bars(height: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: height * 0.16) {
            ForEach(1...4, id: \.self) { index in
                RoundedRectangle(cornerRadius: height * 0.1, style: .continuous)
                    .fill(index <= quality.bars ? color : theme.colors.onSurface.opacity(0.12))
                    .frame(width: height * 0.26, height: height * (0.25 + 0.25 * CGFloat(index - 1)))
            }
        }
        .frame(height: height, alignment: .bottom)
        .overlay(alignment: .bottomTrailing) {
            if quality == .offline {
                Image(systemName: "xmark")
                    .font(.system(size: height * 0.42, weight: .heavy))
                    .foregroundStyle(theme.colors.danger)
                    .offset(x: height * 0.2)
            }
        }
    }

    private var pill: some View {
        HStack(spacing: 8) {
            bars(height: 13)
            Text(quality.label).font(.system(size: 13, weight: .semibold)).foregroundStyle(theme.colors.onSurface)
            if let latencyText {
                Text(latencyText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.colors.onSurface.opacity(0.55))
                    .contentTransition(.numericText())
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(Capsule().fill(color.opacity(0.12)))
        .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 1))
    }

    private var gauge: some View {
        let fraction = Double(quality.rawValue) / Double(KitoNetworkQuality.excellent.rawValue)
        return VStack(spacing: 4) {
            ZStack {
                KitoGaugeArc()
                    .stroke(theme.colors.onSurface.opacity(0.1), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                KitoGaugeArc()
                    .trim(from: 0, to: max(fraction, 0.02))
                    .stroke(AngularGradient(colors: [theme.colors.danger, theme.colors.warning, theme.colors.success], center: .bottom, startAngle: .degrees(180), endAngle: .degrees(360)), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                Capsule()
                    .fill(theme.colors.onSurface)
                    .frame(width: 3, height: 52)
                    .frame(width: 140, height: 76, alignment: .bottom)
                    .rotationEffect(.degrees(-90 + 180 * fraction), anchor: .bottom)
                Circle().fill(theme.colors.onSurface).frame(width: 12, height: 12)
                    .frame(width: 140, height: 76, alignment: .bottom)
                    .offset(y: 6)
            }
            .frame(width: 140, height: 76)
            Text(quality.label)
                .font(theme.typography.titleMedium)
                .foregroundStyle(theme.colors.onSurface)
                .contentTransition(.opacity)
            if let latencyText {
                Text(latencyText)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(theme.colors.onSurface.opacity(0.55))
                    .contentTransition(.numericText())
            }
        }
    }
}

/// The top half of a circle, left to right.
struct KitoGaugeArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.maxY), radius: min(rect.width / 2, rect.height) - 6, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        return path
    }
}
