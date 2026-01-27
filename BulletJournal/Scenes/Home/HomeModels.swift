//
//  HomeModels.swift
//  BulletJournal
//

import Foundation

enum Home {
    // MARK: - Use Cases

    enum LoadCurrentTask {
        struct Request {}

        struct Response {
            let task: FocusTask?
        }
    }

    enum TimerAction {
        enum ActionType {
            case start
            case pause
            case resume
            case stop
        }

        struct Request {
            let action: ActionType
        }

        struct Response {
            let timerState: TimerState
            let elapsedSeconds: Int
            let session: FocusSession?
        }
    }

    enum TimerTick {
        struct Response {
            let elapsedSeconds: Int
            let progressPercentage: Double
        }
    }

    enum SoundSelection {
        struct Request {
            let sound: AmbientSound
        }

        struct Response {
            let selectedSound: AmbientSound
        }
    }

    enum SleepQuality {
        struct Response {
            let needsPrompt: Bool
        }
    }

    // MARK: - View Models

    struct TaskCardViewModel: Equatable {
        let id: UUID
        let title: String
        let startTime: String
        let endTime: String
        let duration: String
        let progressPercentage: Double
        let focusedTimeDisplay: String

        static let empty = TaskCardViewModel(
            id: UUID(),
            title: "",
            startTime: "",
            endTime: "",
            duration: "",
            progressPercentage: 0,
            focusedTimeDisplay: ""
        )
    }

    struct TimerViewModel: Equatable {
        let timerDisplay: String
        let progressPercentage: Double
        let state: TimerState
        let buttonTitle: String

        static let initial = TimerViewModel(
            timerDisplay: "00:00",
            progressPercentage: 0,
            state: .idle,
            buttonTitle: String(localized: "home.timer.start")
        )
    }

    struct SoundViewModel: Equatable {
        let selectedSound: AmbientSound
        let displayName: String

        static let initial = SoundViewModel(
            selectedSound: .none,
            displayName: AmbientSound.none.localizedName
        )
    }
}
