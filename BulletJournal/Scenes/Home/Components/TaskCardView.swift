//
//  TaskCardView.swift
//  BulletJournal
//

import SwiftUI

struct TaskCardView: View {
    let viewModel: Home.TaskCardViewModel
    let hasTask: Bool
    let onChevronTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("home.task.label")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.secondaryText)

                Spacer()

                if hasTask {
                    Button(action: onChevronTapped) {
                        ZStack {
                            Circle()
                                .fill(AppColors.chevronBackground)
                                .frame(width: 30, height: 30)

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }
                }
            }

            if hasTask {
                taskContent
            } else {
                emptyState
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var taskContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.primaryText)

            // Time range row
            HStack {
                Text(viewModel.startTime)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.secondaryText)

                Spacer()

                Text(viewModel.endTime)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.secondaryText)

                Text(viewModel.duration)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.secondaryText)
                    .padding(.leading, 8)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.white)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 30)
                        .fill(AppColors.progressGreen)
                        .frame(
                            width: geometry.size.width * viewModel.progressPercentage,
                            height: 8
                        )
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progressPercentage)
                }
            }
            .frame(height: 8)
        }
    }

    private var emptyState: some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .font(.title2)
                .foregroundStyle(AppColors.progressGreen)

            Text("home.noTask")
                .font(.body)
                .foregroundStyle(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 20)
    }
}

#Preview("With Task") {
    TaskCardView(
        viewModel: Home.TaskCardViewModel(
            id: UUID(),
            title: "회사 일 (오후)",
            startTime: "13:00",
            endTime: "17:00",
            duration: "4h",
            progressPercentage: 0.5,
            focusedTimeDisplay: "02:00"
        ),
        hasTask: true,
        onChevronTapped: {}
    )
    .padding()
    .background(AppColors.background)
}

#Preview("No Task") {
    TaskCardView(
        viewModel: .empty,
        hasTask: false,
        onChevronTapped: {}
    )
    .padding()
    .background(AppColors.background)
}
