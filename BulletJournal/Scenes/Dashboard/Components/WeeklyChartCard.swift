//
//  WeeklyChartCard.swift
//  BulletJournal
//

import SwiftUI

struct WeeklyChartCard: View {
    let viewModel: Dashboard.WeeklyChartViewModel

    private let maxBarHeight: CGFloat = 120
    private let barWidth: CGFloat = 5
    private let barCornerRadius: CGFloat = 20

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.bars.isEmpty {
                emptyStateView
            } else {
                chartContent
            }
        }
        .padding(20)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
    }

    private var chartContent: some View {
        VStack(spacing: 8) {
            // Time labels row
            HStack(spacing: 0) {
                ForEach(viewModel.bars) { bar in
                    Text(bar.timeLabel)
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }

            // Bars row
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(viewModel.bars) { bar in
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: barCornerRadius)
                            .fill(AppColors.dashboardGreen)
                            .frame(width: barWidth, height: barHeight(for: bar))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: maxBarHeight)
                }
            }

            // Weekday labels row
            HStack(spacing: 0) {
                ForEach(viewModel.bars) { bar in
                    Text(bar.weekday)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppColors.primaryText)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var emptyStateView: some View {
        Text("dashboard.noData")
            .font(.system(size: 14))
            .foregroundStyle(AppColors.secondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: maxBarHeight)
    }

    private func barHeight(for bar: Dashboard.WeeklyChartViewModel.BarData) -> CGFloat {
        let minHeight: CGFloat = 4
        let calculatedHeight = maxBarHeight * bar.heightRatio
        return bar.seconds > 0 ? max(calculatedHeight, minHeight) : minHeight
    }
}

#Preview("With Data") {
    let bars = [
        Dashboard.WeeklyChartViewModel.BarData(weekday: "Mon", timeLabel: "2h", heightRatio: 0.8, seconds: 7200),
        Dashboard.WeeklyChartViewModel.BarData(weekday: "Tue", timeLabel: "1h 45m", heightRatio: 0.7, seconds: 6300),
        Dashboard.WeeklyChartViewModel.BarData(weekday: "Wed", timeLabel: "1h", heightRatio: 0.4, seconds: 3600),
        Dashboard.WeeklyChartViewModel.BarData(weekday: "Thu", timeLabel: "2h 20m", heightRatio: 1.0, seconds: 8400),
        Dashboard.WeeklyChartViewModel.BarData(weekday: "Fri", timeLabel: "30m", heightRatio: 0.2, seconds: 1800),
        Dashboard.WeeklyChartViewModel.BarData(weekday: "Sat", timeLabel: "-", heightRatio: 0.0, seconds: 0),
        Dashboard.WeeklyChartViewModel.BarData(weekday: "Sun", timeLabel: "-", heightRatio: 0.0, seconds: 0)
    ]

    WeeklyChartCard(viewModel: Dashboard.WeeklyChartViewModel(bars: bars))
        .padding()
        .background(AppColors.background)
}

#Preview("Empty") {
    WeeklyChartCard(viewModel: .empty)
        .padding()
        .background(AppColors.background)
}
