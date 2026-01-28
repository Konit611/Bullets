//
//  StartFocusCard.swift
//  BulletJournal
//

import SwiftUI

struct StartFocusCard: View {
    // MARK: - Layout Constants

    private enum Layout {
        static let circleSize: CGFloat = 272
        static let innerShadowRadius: CGFloat = 10
        static let innerShadowOffset: CGFloat = 5
        static let timerFontSize: CGFloat = 52
    }

    // MARK: - Properties

    let timerState: TimerState
    let focusedTimeDisplay: String
    let soundName: String
    let isEnabled: Bool

    let onStart: () -> Void
    let onResume: () -> Void
    let onSoundTapped: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            soundDropdown

            focusCircle

            switch timerState {
            case .idle:
                startButton

            case .paused:
                resumeButton

            case .running:
                // FocusView가 표시되므로 홈에서는 보이지 않음
                EmptyView()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    // MARK: - Sound Dropdown

    private var soundDropdown: some View {
        Button(action: onSoundTapped) {
            HStack(spacing: 6) {
                Text(soundName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppColors.primaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppColors.focusCardCircle)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .accessibilityLabel(Text("home.sound.label"))
        .accessibilityValue(Text(soundName))
        .accessibilityHint(Text("accessibility.hint.tapToOpen"))
    }

    // MARK: - Focus Circle

    private var focusCircle: some View {
        ZStack {
            // Base circle
            Circle()
                .fill(AppColors.focusCardCircle)
                .frame(width: Layout.circleSize, height: Layout.circleSize)

            // Inner shadow overlay
            Circle()
                .fill(Color.clear)
                .frame(width: Layout.circleSize, height: Layout.circleSize)
                .overlay(
                    Circle()
                        .stroke(AppColors.focusInnerShadow, lineWidth: 20)
                        .blur(radius: Layout.innerShadowRadius)
                        .offset(x: -Layout.innerShadowOffset, y: -Layout.innerShadowOffset)
                )
                .overlay(
                    Circle()
                        .stroke(AppColors.focusInnerShadow, lineWidth: 20)
                        .blur(radius: Layout.innerShadowRadius)
                        .offset(x: Layout.innerShadowOffset, y: Layout.innerShadowOffset)
                )
                .clipShape(Circle())

            // Timer display inside circle
            Text(focusedTimeDisplay)
                .font(.system(size: Layout.timerFontSize, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(AppColors.timerText)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("home.focusTime"))
        .accessibilityValue(Text(focusedTimeDisplay))
    }

    // MARK: - Buttons

    private var startButton: some View {
        Button(action: onStart) {
            HStack(spacing: 8) {
                Text("home.timer.start")
                    .font(.system(size: 20, weight: .semibold))

                Image(systemName: "play.fill")
                    .font(.system(size: 16))
            }
            .foregroundStyle(AppColors.primaryText)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(AppColors.focusCardCircle)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
        .accessibilityLabel(Text("home.timer.start"))
        .accessibilityHint(isEnabled ? Text("sleepQuality.accessibility.hint") : nil)
    }

    private var resumeButton: some View {
        Button(action: onResume) {
            HStack(spacing: 8) {
                Text("home.timer.resume")
                    .font(.system(size: 20, weight: .semibold))

                Image(systemName: "play.fill")
                    .font(.system(size: 16))
            }
            .foregroundStyle(AppColors.primaryText)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(AppColors.focusCardCircle)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .accessibilityLabel(Text("home.timer.resume"))
        .accessibilityHint(Text("sleepQuality.accessibility.hint"))
    }
}

// MARK: - Previews

#Preview("Idle - Enabled") {
    StartFocusCard(
        timerState: .idle,
        focusedTimeDisplay: "03:00",
        soundName: "White Noise",
        isEnabled: true,
        onStart: {},
        onResume: {},
        onSoundTapped: {}
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Idle - Disabled") {
    StartFocusCard(
        timerState: .idle,
        focusedTimeDisplay: "00:00",
        soundName: "None",
        isEnabled: false,
        onStart: {},
        onResume: {},
        onSoundTapped: {}
    )
    .padding()
    .background(AppColors.background)
}

#Preview("Paused") {
    StartFocusCard(
        timerState: .paused,
        focusedTimeDisplay: "15:30",
        soundName: "Rain",
        isEnabled: true,
        onStart: {},
        onResume: {},
        onSoundTapped: {}
    )
    .padding()
    .background(AppColors.background)
}
