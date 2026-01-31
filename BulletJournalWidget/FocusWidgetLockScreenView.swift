//
//  FocusWidgetLockScreenView.swift
//  BulletJournalWidget
//

import SwiftUI
import WidgetKit

// MARK: - Circular Lock Screen Widget

struct FocusWidgetLockScreenCircularView: View {
    let entry: FocusWidgetEntry

    var body: some View {
        if entry.isEmpty {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "clock")
                    .font(.system(size: 20))
            }
        } else {
            Gauge(value: entry.progressPercentage) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 12))
            } currentValueLabel: {
                Text("\(Int(entry.progressPercentage * 100))")
                    .font(.system(size: 14, weight: .semibold))
            }
            .gaugeStyle(.accessoryCircular)
        }
    }
}

// MARK: - Rectangular Lock Screen Widget

struct FocusWidgetLockScreenRectangularView: View {
    let entry: FocusWidgetEntry

    private enum Layout {
        static let progressBarHeight: CGFloat = 4
        static let progressBarCornerRadius: CGFloat = 2
        static let percentageWidth: CGFloat = 30
    }

    var body: some View {
        if entry.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                Text("widget.noTask")
                    .font(.system(size: 13))
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.taskTitle ?? "")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: Layout.progressBarCornerRadius)
                                .fill(.secondary.opacity(0.3))
                                .frame(height: Layout.progressBarHeight)
                            RoundedRectangle(cornerRadius: Layout.progressBarCornerRadius)
                                .fill(.primary)
                                .frame(width: geometry.size.width * entry.progressPercentage, height: Layout.progressBarHeight)
                        }
                    }
                    .frame(height: Layout.progressBarHeight)

                    Text("\(Int(entry.progressPercentage * 100))%")
                        .font(.system(size: 11))
                        .frame(width: Layout.percentageWidth, alignment: .trailing)
                }

                if let timeSlot = entry.timeSlot {
                    Text(timeSlot)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
