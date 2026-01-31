//
//  FocusWidgetSmallView.swift
//  BulletJournalWidget
//

import SwiftUI
import WidgetKit

struct FocusWidgetSmallView: View {
    let entry: FocusWidgetEntry

    private enum Layout {
        static let padding: CGFloat = 14
        static let progressBarHeight: CGFloat = 6
        static let progressBarCornerRadius: CGFloat = 3
        static let spacing: CGFloat = 8
    }

    var body: some View {
        if entry.isEmpty {
            emptyView
        } else {
            taskView
        }
    }

    private var taskView: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            Text(entry.taskTitle ?? "")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.primaryText)
                .lineLimit(2)

            Spacer()

            Text("\(Int(entry.progressPercentage * 100))%")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.primaryText)

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

            Text(entry.formattedRemainingTime)
                .font(.system(size: 12))
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(Layout.padding)
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 28))
                .foregroundColor(AppColors.secondaryText.opacity(0.5))
            Text("widget.noTask")
                .font(.system(size: 13))
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
