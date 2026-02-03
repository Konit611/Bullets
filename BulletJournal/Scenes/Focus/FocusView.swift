//
//  FocusView.swift
//  BulletJournal
//

import SwiftUI
import SwiftData

struct FocusView: View {
    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalPadding: CGFloat = 15
        static let topPadding: CGFloat = 10
        static let bottomPadding: CGFloat = 40

        enum BackButton {
            static let size: CGFloat = 40
            static let iconSize: CGFloat = 16
        }

        enum TimerCircle {
            static let outerSize: CGFloat = 272
            static let innerSize: CGFloat = 248
            static let borderWidth: CGFloat = 2
            static let dashLength: CGFloat = 8
            static let fontSize: CGFloat = 52
        }

        enum ControlButton {
            static let fontSize: CGFloat = 20
            static let iconSize: CGFloat = 16
            static let horizontalPadding: CGFloat = 24
            static let verticalPadding: CGFloat = 14
            static let cornerRadius: CGFloat = 12
            static let spacing: CGFloat = 8
        }

        enum SoundBar {
            static let iconSize: CGFloat = 40
            static let chevronSize: CGFloat = 12
            static let playIconSize: CGFloat = 16
            static let titleFontSize: CGFloat = 14
            static let subtitleFontSize: CGFloat = 12
            static let horizontalPadding: CGFloat = 20
            static let verticalPadding: CGFloat = 16
            static let spacing: CGFloat = 12
            static let textSpacing: CGFloat = 2
        }
    }

    // MARK: - Properties

    @ObservedObject var presenter: HomePresenter
    @State private var showSoundPicker = false

    let onStop: () -> Void

    // MARK: - Body

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer()

                timerCircle

                Spacer()

                controlButton
                    .padding(.bottom, Layout.bottomPadding)

                Spacer()

                ambientSoundBar
            }
        }
        .sheet(isPresented: $showSoundPicker) {
            SoundPickerView(
                selectedSound: .init(
                    get: { presenter.soundViewModel.selectedSound },
                    set: { _ in }
                ),
                isPresented: $showSoundPicker,
                onSoundSelected: presenter.selectSound
            )
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            backButton
            Spacer()
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .padding(.top, Layout.topPadding)
    }

    /// 뒤로가기 버튼 = STOP (세션 종료)
    private var backButton: some View {
        Button(action: onStop) {
            ZStack {
                Circle()
                    .fill(AppColors.chevronBackground)
                    .frame(width: Layout.BackButton.size, height: Layout.BackButton.size)

                Image(systemName: "chevron.left")
                    .font(.system(size: Layout.BackButton.iconSize, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
            }
        }
        .accessibilityLabel(Text("accessibility.back"))
        .accessibilityHint(Text("focus.accessibility.stopHint"))
    }

    // MARK: - Timer Circle

    private var timerCircle: some View {
        ZStack {
            // White background circle
            Circle()
                .fill(Color.white)
                .frame(width: Layout.TimerCircle.outerSize, height: Layout.TimerCircle.outerSize)

            // Dashed border
            Circle()
                .stroke(
                    AppColors.primaryText,
                    style: StrokeStyle(
                        lineWidth: Layout.TimerCircle.borderWidth,
                        lineCap: .round,
                        dash: [Layout.TimerCircle.dashLength, Layout.TimerCircle.dashLength]
                    )
                )
                .frame(width: Layout.TimerCircle.innerSize, height: Layout.TimerCircle.innerSize)

            // Timer display
            Text(presenter.timerViewModel.timerDisplay)
                .font(.system(size: Layout.TimerCircle.fontSize, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(AppColors.primaryText)
        }
    }

    // MARK: - Control Button (PAUSE / RESUME)

    @ViewBuilder
    private var controlButton: some View {
        switch presenter.timerViewModel.state {
        case .running:
            // PAUSE 버튼
            Button(action: { presenter.pauseTimer() }) {
                HStack(spacing: Layout.ControlButton.spacing) {
                    Text("home.timer.pause")
                        .font(.system(size: Layout.ControlButton.fontSize, weight: .semibold))
                    Image(systemName: "pause.fill")
                        .font(.system(size: Layout.ControlButton.iconSize))
                }
                .foregroundStyle(AppColors.primaryText)
                .padding(.horizontal, Layout.ControlButton.horizontalPadding)
                .padding(.vertical, Layout.ControlButton.verticalPadding)
                .background(AppColors.buttonBackground)
                .clipShape(RoundedRectangle(cornerRadius: Layout.ControlButton.cornerRadius))
            }

        case .paused:
            // RESUME 버튼
            Button(action: { presenter.resumeTimerInFocus() }) {
                HStack(spacing: Layout.ControlButton.spacing) {
                    Text("home.timer.resume")
                        .font(.system(size: Layout.ControlButton.fontSize, weight: .semibold))
                    Image(systemName: "play.fill")
                        .font(.system(size: Layout.ControlButton.iconSize))
                }
                .foregroundStyle(AppColors.primaryText)
                .padding(.horizontal, Layout.ControlButton.horizontalPadding)
                .padding(.vertical, Layout.ControlButton.verticalPadding)
                .background(AppColors.buttonBackground)
                .clipShape(RoundedRectangle(cornerRadius: Layout.ControlButton.cornerRadius))
            }

        case .idle:
            EmptyView()
        }
    }

    // MARK: - Ambient Sound Bar

    private var ambientSoundBar: some View {
        HStack(spacing: Layout.SoundBar.spacing) {
            // Expand button
            Button(action: { showSoundPicker = true }) {
                Image(systemName: "chevron.up")
                    .font(.system(size: Layout.SoundBar.chevronSize, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
            }

            // Sound icon
            ZStack {
                Circle()
                    .fill(AppColors.chevronBackground)
                    .frame(width: Layout.SoundBar.iconSize, height: Layout.SoundBar.iconSize)

                Image(systemName: presenter.soundViewModel.selectedSound.iconName)
                    .font(.system(size: Layout.SoundBar.playIconSize))
                    .foregroundStyle(AppColors.primaryText)
            }

            // Sound info
            VStack(alignment: .leading, spacing: Layout.SoundBar.textSpacing) {
                Text(presenter.soundViewModel.displayName)
                    .font(.system(size: Layout.SoundBar.titleFontSize, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text("focus.sound.artist")
                    .font(.system(size: Layout.SoundBar.subtitleFontSize))
                    .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()

            // Play/Pause button
            Button(action: {
                if presenter.soundViewModel.selectedSound == .none {
                    showSoundPicker = true
                } else {
                    presenter.toggleSound()
                }
            }) {
                Image(systemName: presenter.soundViewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: Layout.SoundBar.playIconSize))
                    .foregroundStyle(AppColors.primaryText)
            }
        }
        .padding(.horizontal, Layout.SoundBar.horizontalPadding)
        .padding(.vertical, Layout.SoundBar.verticalPadding)
        .background(Color.white)
    }
}

// MARK: - Previews

#Preview("Focus View - Running") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FocusTask.self, FocusSession.self, DailyRecord.self, configurations: config)
    let interactor = HomeInteractor(
        modelContext: container.mainContext,
        timerService: ServiceContainer.shared.timerService,
        ambientSoundService: ServiceContainer.shared.ambientSoundService,
        nowPlayingService: ServiceContainer.shared.nowPlayingService
    )
    let presenter = HomePresenter(interactor: interactor)

    return FocusView(
        presenter: presenter,
        onStop: {}
    )
}
