//
//  FocusWidgetMediumView.swift
//  BulletJournalWidget
//

import SwiftUI
import WidgetKit

struct FocusWidgetMediumView: View {
    let entry: FocusWidgetEntry

    private enum Layout {
        static let padding: CGFloat = 16
        static let progressBarHeight: CGFloat = 6
        static let progressBarCornerRadius: CGFloat = 3
        static let spacing: CGFloat = 10
    }

    var body: some View {
        if entry.isEmpty {
            emptyView
        } else {
            taskView
        }
    }

    private var taskView: some View {
        HStack(spacing: 16) {
            // Left: Task info
            VStack(alignment: .leading, spacing: Layout.spacing) {
                // Task title
                Text(entry.taskTitle ?? "")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(2)

                // Time slot
                if let timeSlot = entry.timeSlot {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(timeSlot)
                            .font(.system(size: 12))
                    }
                    .foregroundColor(AppColors.secondaryText)
                }

                Spacer()

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: Layout.progressBarCornerRadius)
                            .fill(AppColors.progressGreen.opacity(0.3))
                            .frame(height: Layout.progressBarHeight)

                        RoundedRectangle(cornerRadius: Layout.progressBarCornerRadius)
                            .fill(AppColors.progressGreen)
                            .frame(width: geometry.size.width * entry.progressPercentage, height: Layout.progressBarHeight)
                    }
                }
                .frame(height: Layout.progressBarHeight)
            }

            // Right: Stats
            VStack(spacing: 6) {
                // Progress percentage
                Text("\(Int(entry.progressPercentage * 100))%")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.primaryText)

                // Focused time
                Text(formatFocused(entry.totalFocusedSeconds))
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.progressGreen)

                // Remaining time
                Text(formatRemaining(entry.remainingSeconds))
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.secondaryText)
            }
            .frame(width: 90)
        }
        .padding(Layout.padding)
    }

    private var emptyView: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 32))
                .foregroundColor(AppColors.secondaryText.opacity(0.5))
            VStack(alignment: .leading, spacing: 4) {
                Text("No task scheduled")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
                Text("Create a task to get started")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.secondaryText.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func formatFocused(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m focused"
        } else {
            return "\(minutes)m focused"
        }
    }

    private func formatRemaining(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(minutes)m left"
        }
    }
}
