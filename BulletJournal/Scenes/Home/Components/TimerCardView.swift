//
//  TimerCardView.swift
//  BulletJournal
//

import SwiftUI

struct TimerCardView: View {
    let viewModel: Home.TimerViewModel
    let soundViewModel: Home.SoundViewModel
    let isEnabled: Bool

    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    let onSoundTapped: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            soundDropdown
            timerRing
            controlButtons
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var soundDropdown: some View {
        Button(action: onSoundTapped) {
            HStack(spacing: 6) {
                Text(soundViewModel.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(
                    AppColors.timerRingBackground,
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 272, height: 272)

            Circle()
                .trim(from: 0, to: viewModel.progressPercentage)
                .stroke(
                    AppColors.timerRing,
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 272, height: 272)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: viewModel.progressPercentage)

            Text(viewModel.timerDisplay)
                .font(.system(size: 52, weight: .medium, design: .default))
                .monospacedDigit()
                .foregroundStyle(AppColors.primaryText)
        }
    }

    @ViewBuilder
    private var controlButtons: some View {
        switch viewModel.state {
        case .running:
            HStack(spacing: 12) {
                TimerButton(
                    title: String(localized: "home.timer.pause"),
                    icon: "pause.fill",
                    style: .secondary,
                    action: onPause
                )
                TimerButton(
                    title: String(localized: "home.timer.stop"),
                    icon: "stop.fill",
                    style: .destructive,
                    action: onStop
                )
            }

        case .paused:
            HStack(spacing: 12) {
                TimerButton(
                    title: String(localized: "home.timer.resume"),
                    icon: "play.fill",
                    style: .secondary,
                    action: onResume
                )
                TimerButton(
                    title: String(localized: "home.timer.stop"),
                    icon: "stop.fill",
                    style: .destructive,
                    action: onStop
                )
            }

        case .idle:
            TimerButton(
                title: String(localized: "home.timer.start"),
                icon: "play.fill",
                style: .primary,
                isEnabled: isEnabled,
                action: onStart
            )
        }
    }
}

// MARK: - Timer Button Component

private struct TimerButton: View {
    enum Style {
        case primary
        case secondary
        case destructive
    }

    let title: String
    let icon: String
    let style: Style
    var isEnabled: Bool = true
    let action: () -> Void

    private var backgroundColor: Color {
        switch style {
        case .primary, .secondary:
            return AppColors.buttonBackground
        case .destructive:
            return AppColors.stopButton
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .secondary:
            return AppColors.primaryText
        case .destructive:
            return .white
        }
    }

    private var fontSize: CGFloat {
        style == .primary ? 20 : 16
    }

    private var iconSize: CGFloat {
        style == .primary ? 16 : 14
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: style == .primary ? 8 : 6) {
                Text(title)
                    .font(.system(size: fontSize, weight: .semibold))

                Image(systemName: icon)
                    .font(.system(size: iconSize))
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, style == .primary ? 24 : 20)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

// MARK: - Previews

#Preview("Idle") {
    TimerCardView(
        viewModel: .initial,
        soundViewModel: Home.SoundViewModel(selectedSound: .whiteNoise, displayName: "White Noise"),
        isEnabled: true,
        onStart: {},
        onPause: {},
        onResume: {},
        onStop: {},
        onSoundTapped: {}
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Running") {
    TimerCardView(
        viewModel: Home.TimerViewModel(
            timerDisplay: "03:00",
            progressPercentage: 0.35,
            state: .running,
            buttonTitle: "PAUSE"
        ),
        soundViewModel: Home.SoundViewModel(selectedSound: .whiteNoise, displayName: "White Noise"),
        isEnabled: true,
        onStart: {},
        onPause: {},
        onResume: {},
        onStop: {},
        onSoundTapped: {}
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Paused") {
    TimerCardView(
        viewModel: Home.TimerViewModel(
            timerDisplay: "03:00",
            progressPercentage: 0.35,
            state: .paused,
            buttonTitle: "RESUME"
        ),
        soundViewModel: Home.SoundViewModel(selectedSound: .whiteNoise, displayName: "White Noise"),
        isEnabled: true,
        onStart: {},
        onPause: {},
        onResume: {},
        onStop: {},
        onSoundTapped: {}
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Disabled") {
    TimerCardView(
        viewModel: .initial,
        soundViewModel: Home.SoundViewModel(selectedSound: .none, displayName: "None"),
        isEnabled: false,
        onStart: {},
        onPause: {},
        onResume: {},
        onStop: {},
        onSoundTapped: {}
    )
    .padding()
    .background(AppColors.background)
}
