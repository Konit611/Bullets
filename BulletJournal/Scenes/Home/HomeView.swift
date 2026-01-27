//
//  HomeView.swift
//  BulletJournal
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @StateObject private var presenter: HomePresenter
    @State private var showSoundPicker = false
    @State private var selectedSound: AmbientSound = .none

    init(
        modelContext: ModelContext,
        serviceContainer: ServiceContainer = .shared
    ) {
        let interactor = HomeInteractor(
            modelContext: modelContext,
            timerService: serviceContainer.timerService,
            ambientSoundService: serviceContainer.ambientSoundService
        )
        _presenter = StateObject(wrappedValue: HomePresenter(interactor: interactor))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                appLogo

                TaskCardView(
                    viewModel: presenter.taskViewModel,
                    hasTask: presenter.hasCurrentTask,
                    onChevronTapped: {
                        // TODO: Navigate to task detail
                    }
                )

                TimerCardView(
                    viewModel: presenter.timerViewModel,
                    soundViewModel: presenter.soundViewModel,
                    isEnabled: presenter.hasCurrentTask,
                    onStart: presenter.requestStartTimer,
                    onPause: presenter.pauseTimer,
                    onResume: presenter.resumeTimer,
                    onStop: presenter.stopTimer,
                    onSoundTapped: {
                        showSoundPicker = true
                    }
                )
            }
            .padding(.horizontal, 15)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .background(AppColors.background)
        .onAppear {
            presenter.onAppear()
            selectedSound = presenter.soundViewModel.selectedSound
        }
        .sheet(isPresented: $showSoundPicker) {
            SoundPickerView(
                selectedSound: $selectedSound,
                isPresented: $showSoundPicker,
                onSoundSelected: presenter.selectSound
            )
        }
        .sheet(isPresented: $presenter.showSleepQualityPrompt) {
            SleepQualityPromptView(
                isPresented: $presenter.showSleepQualityPrompt,
                onSleepQualitySelected: presenter.selectSleepQuality
            )
        }
        .alert(
            Text("Error"),
            isPresented: .init(
                get: { presenter.error != nil },
                set: { if !$0 { presenter.clearError() } }
            )
        ) {
            Button(String(localized: "OK")) {
                presenter.clearError()
            }
        } message: {
            if let error = presenter.error {
                Text(error.localizedDescription)
            }
        }
        .fullScreenCover(isPresented: $presenter.showFocusView) {
            FocusView(
                presenter: presenter,
                onStop: {
                    presenter.stopTimer()
                },
                onSoundTapped: {
                    showSoundPicker = true
                }
            )
            .sheet(isPresented: $showSoundPicker) {
                SoundPickerView(
                    selectedSound: $selectedSound,
                    isPresented: $showSoundPicker,
                    onSoundSelected: presenter.selectSound
                )
            }
        }
        .alert(
            Text("focus.screenTime.permissionTitle"),
            isPresented: $presenter.showScreenTimePermissionAlert
        ) {
            Button(String(localized: "OK")) {
                presenter.showScreenTimePermissionAlert = false
            }
        } message: {
            Text("focus.screenTime.permissionMessage")
        }
    }

    private var appLogo: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.logoBackground)
                    .frame(width: 40, height: 40)

                // Placeholder for app icon - replace with actual image
                Text("B")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(AppColors.primaryText)
            }

            Spacer()
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FocusTask.self, FocusSession.self, configurations: config)

    let calendar = Calendar.current
    let now = Date()
    let startTime = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: now)!
    let endTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now)!

    let task = FocusTask(
        title: "회사 일 (오후)",
        startTime: startTime,
        endTime: endTime
    )
    container.mainContext.insert(task)

    return HomeView(modelContext: container.mainContext)
}
