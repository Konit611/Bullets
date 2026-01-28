//
//  AppColors.swift
//  BulletJournal
//

import SwiftUI

enum AppColors {
    // MARK: - Background Colors
    static let background = Color(hex: "#F2E6DF")
    static let cardBackground = Color(hex: "#FCF7F5")

    // MARK: - Accent Colors
    static let progressGreen = Color(hex: "#95F2AC")
    static let timerRing = Color(hex: "#FADADD")
    static let timerRingBackground = Color(hex: "#F5E6E8")

    // MARK: - Text Colors
    static let primaryText = Color(hex: "#373737")
    static let secondaryText = Color(hex: "#777F8F")

    // MARK: - Button Colors
    static let startButton = Color(hex: "#373737")
    static let stopButton = Color(hex: "#FF6B6B")
    static let pauseButton = Color(hex: "#FFB347")

    // MARK: - Misc
    static let divider = Color(hex: "#E8E0DC")
    static let tabBarBackground = Color(hex: "#FFFFFF")
    static let chevronBackground = Color(hex: "#F5F0ED")
    static let buttonBackground = Color(hex: "#FEFEFD")
    static let logoBackground = Color(hex: "#F6F6F6")

    // MARK: - Dashboard
    static let dashboardGreen = Color(hex: "#7DE998")
    static let emojiBackground = Color.white

    // MARK: - Focus Card
    static let focusCardCircle = Color(hex: "#FEFEFD")
    static let focusInnerShadow = Color(red: 234/255, green: 111/255, blue: 111/255).opacity(0.25)
    static let timerText = Color(hex: "#373737")

    // MARK: - Task Block
    static let taskBlockBackground = Color(hex: "#95F2AC").opacity(0.8)
    static let taskBlockAccent = Color(hex: "#72E78F")

    // MARK: - Sleep Record
    static let selectedEmojiBackground = Color(hex: "#F5A623")
    static let timePickerBackground = Color(hex: "#F5F0ED")

    // MARK: - Current Time Indicator
    static let currentTimeIndicator = Color(hex: "#FF0B0B")

    // MARK: - Onboarding
    static let onboardingAccent = Color(hex: "#65C37C")
}
