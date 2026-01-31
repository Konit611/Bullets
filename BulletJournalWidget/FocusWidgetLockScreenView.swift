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

    var body: some View {
        if entry.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                Text("No task")
                    .font(.system(size: 13))
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.taskTitle ?? "")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    // Mini progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.secondary.opacity(0.3))
                                .frame(height: 4)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.primary)
                                .frame(width: geometry.size.width * entry.progressPercentage, height: 4)
                        }
                    }
                    .frame(height: 4)

                    Text("\(Int(entry.progressPercentage * 100))%")
                        .font(.system(size: 11))
                        .frame(width: 30, alignment: .trailing)
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
