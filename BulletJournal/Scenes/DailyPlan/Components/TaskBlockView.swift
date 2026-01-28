//
//  TaskBlockView.swift
//  BulletJournal
//

import SwiftUI

struct TaskBlockView: View {
    let viewModel: DailyPlan.TaskBlockViewModel

    // MARK: - Layout Constants

    private enum Layout {
        static let cornerRadius: CGFloat = 6
        static let accentBarWidth: CGFloat = 5
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 8
        static let minHeight: CGFloat = 40
    }


    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left accent bar
                Rectangle()
                    .fill(AppColors.taskBlockAccent)
                    .frame(width: Layout.accentBarWidth)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                        .lineLimit(viewModel.height > 60 ? 2 : 1)

                    if viewModel.height > 50 {
                        Text("\(viewModel.startTimeString) - \(viewModel.endTimeString)")
                            .font(.system(size: 11))
                            .foregroundStyle(AppColors.secondaryText)
                    }

                    if viewModel.height > 80 && viewModel.progressPercentage > 0 {
                        progressBar
                    }
                }
                .padding(.horizontal, Layout.horizontalPadding)
                .padding(.vertical, Layout.verticalPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: max(viewModel.height, Layout.minHeight))
            .background(AppColors.taskBlockBackground)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
            .overlay {
                if viewModel.isCurrentTask {
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .stroke(AppColors.taskBlockAccent, lineWidth: 2)
                }
            }
        }
        .frame(height: max(viewModel.height, Layout.minHeight))
        .frame(maxWidth: .infinity)
        .padding(.trailing, 15)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(viewModel.title))
        .accessibilityValue(Text("\(viewModel.startTimeString) - \(viewModel.endTimeString)"))
        .accessibilityHint(Text("accessibility.hint.tapToOpen"))
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.5))
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.taskBlockAccent)
                    .frame(width: geometry.size.width * viewModel.progressPercentage, height: 4)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - Preview

#Preview("Normal Task") {
    TaskBlockView(
        viewModel: DailyPlan.TaskBlockViewModel(
            id: UUID(),
            title: "Work Session",
            startTimeString: "09:00",
            endTimeString: "12:00",
            yPosition: 0,
            height: 198,
            isCurrentTask: false,
            progressPercentage: 0.5
        )
    )
    .frame(height: 198)
    .padding()
    .background(AppColors.background)
}

#Preview("Current Task") {
    TaskBlockView(
        viewModel: DailyPlan.TaskBlockViewModel(
            id: UUID(),
            title: "Current Focus",
            startTimeString: "14:00",
            endTimeString: "15:00",
            yPosition: 0,
            height: 66,
            isCurrentTask: true,
            progressPercentage: 0.3
        )
    )
    .frame(height: 66)
    .padding()
    .background(AppColors.background)
}

#Preview("Short Task") {
    TaskBlockView(
        viewModel: DailyPlan.TaskBlockViewModel(
            id: UUID(),
            title: "Quick Meeting",
            startTimeString: "10:00",
            endTimeString: "10:30",
            yPosition: 0,
            height: 33,
            isCurrentTask: false,
            progressPercentage: 0
        )
    )
    .frame(height: 33)
    .padding()
    .background(AppColors.background)
}
