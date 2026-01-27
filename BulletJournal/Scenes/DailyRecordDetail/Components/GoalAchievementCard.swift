//
//  GoalAchievementCard.swift
//  BulletJournal
//

import SwiftUI

struct GoalAchievementCard: View {
    let viewModel: DailyRecordDetail.GoalAchievementViewModel

    private enum Layout {
        static let cardPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let percentageFontSize: CGFloat = 36
        static let timeFontSize: CGFloat = 12
    }

    var body: some View {
        VStack(spacing: 12) {
            // Title
            Text("dailyRecord.goalAchievement")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Percentage
            Text(viewModel.percentageString)
                .font(.system(size: Layout.percentageFontSize, weight: .bold))
                .foregroundStyle(AppColors.dashboardGreen)

            // Time details (compact)
            Text("\(viewModel.focusTimeString) / \(viewModel.plannedTimeString)")
                .font(.system(size: Layout.timeFontSize))
                .foregroundStyle(AppColors.secondaryText)
        }
        .padding(Layout.cardPadding)
        .frame(maxWidth: .infinity, minHeight: 130)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 4)
    }
}

#Preview {
    HStack(spacing: 12) {
        GoalAchievementCard(
            viewModel: DailyRecordDetail.GoalAchievementViewModel(
                percentageString: "75%",
                focusTimeString: "3h 45m",
                plannedTimeString: "5h"
            )
        )
        GoalAchievementCard(
            viewModel: DailyRecordDetail.GoalAchievementViewModel(
                percentageString: "0%",
                focusTimeString: "-",
                plannedTimeString: "-"
            )
        )
    }
    .padding()
    .background(AppColors.background)
}
