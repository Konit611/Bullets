//
//  TaskCardView.swift
//  BulletJournal
//

import SwiftUI

struct TaskCardView: View {
    let viewModel: Home.TaskCardViewModel
    let hasTask: Bool
    let hasAnyTasks: Bool
    let isTaskLoaded: Bool
    let onChevronTapped: () -> Void

    private enum NoPlanLayout {
        static let iconSize: CGFloat = 36
        static let titleFontSize: CGFloat = 18
        static let descriptionFontSize: CGFloat = 14
        static let descriptionLineSpacing: CGFloat = 4
        static let buttonFontSize: CGFloat = 16
        static let buttonIconSize: CGFloat = 14
        static let buttonHeight: CGFloat = 48
        static let buttonHorizontalPadding: CGFloat = 24
        static let buttonCornerRadius: CGFloat = 12
        static let verticalPadding: CGFloat = 32
        static let horizontalPadding: CGFloat = 20
    }

    var body: some View {
        Group {
            if !isTaskLoaded {
                loadingState
            } else if !hasAnyTasks {
                noPlanState
                    .transition(.opacity)
            } else {
                normalCard
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isTaskLoaded)
        .animation(.easeInOut(duration: 0.25), value: hasAnyTasks)
    }

    private var loadingState: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("home.task.label")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.secondaryText)

                Spacer()
            }

            emptyState
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var normalCard: some View {
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
                                .fill(.white)
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

            // Time + Progress rows (aligned columns)
            HStack(spacing: 8) {
                // Left column: times + progress bar
                VStack(spacing: 4) {
                    HStack {
                        Text(viewModel.startTime)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.secondaryText)

                        Spacer()

                        Text(viewModel.endTime)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.secondaryText)
                    }

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

                // Right column: duration aligned with progress bar
                VStack {
                    Spacer()

                    Text(viewModel.duration)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.secondaryText)
                        .fixedSize()
                }
            }
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

    private var noPlanState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: NoPlanLayout.iconSize))
                .foregroundStyle(AppColors.onboardingAccent)
                .accessibilityHidden(true)

            Text("home.noPlan.title")
                .font(.system(size: NoPlanLayout.titleFontSize, weight: .semibold))
                .foregroundStyle(AppColors.primaryText)
                .multilineTextAlignment(.center)

            VStack(spacing: NoPlanLayout.descriptionLineSpacing) {
                Text("home.noPlan.description.line1")
                Text("home.noPlan.description.line2")
                Text("home.noPlan.description.line3")
            }
            .font(.system(size: NoPlanLayout.descriptionFontSize))
            .foregroundStyle(AppColors.secondaryText)
            .multilineTextAlignment(.center)

            Button(action: onChevronTapped) {
                HStack(spacing: 8) {
                    Text("home.noPlan.button")
                        .font(.system(size: NoPlanLayout.buttonFontSize, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)

                    Image(systemName: "chevron.right")
                        .font(.system(size: NoPlanLayout.buttonIconSize, weight: .semibold))
                        .foregroundStyle(AppColors.primaryText)
                }
                .frame(height: NoPlanLayout.buttonHeight)
                .padding(.horizontal, NoPlanLayout.buttonHorizontalPadding)
                .background(AppColors.onboardingAccent.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: NoPlanLayout.buttonCornerRadius))
            }
            .accessibilityLabel(String(localized: "home.noPlan.button"))
            .accessibilityHint(String(localized: "accessibility.hint.tapToOpen"))
            .accessibilityAddTraits(.isButton)
        }
        .padding(.vertical, NoPlanLayout.verticalPadding)
        .padding(.horizontal, NoPlanLayout.horizontalPadding)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .accessibilityElement(children: .combine)
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
        hasAnyTasks: true,
        isTaskLoaded: true,
        onChevronTapped: {}
    )
    .padding()
    .background(AppColors.background)
}

#Preview("No Task") {
    TaskCardView(
        viewModel: .empty,
        hasTask: false,
        hasAnyTasks: true,
        isTaskLoaded: true,
        onChevronTapped: {}
    )
    .padding()
    .background(AppColors.background)
}

#Preview("No Plan") {
    TaskCardView(
        viewModel: .empty,
        hasTask: false,
        hasAnyTasks: false,
        isTaskLoaded: true,
        onChevronTapped: {}
    )
    .padding()
    .background(AppColors.background)
}
