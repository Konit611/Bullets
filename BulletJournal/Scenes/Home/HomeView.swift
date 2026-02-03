//
//  HomeView.swift
//  BulletJournal
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @StateObject private var presenter: HomePresenter
    @State private var navigateToDailyPlan = false
    @State private var showSoundPicker = false

    private let modelContext: ModelContext

    init(
        modelContext: ModelContext,
        serviceContainer: ServiceContainer = .shared
    ) {
        self.modelContext = modelContext
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
                    hasAnyTasks: presenter.hasAnyTasks,
                    isTaskLoaded: presenter.isTaskLoaded,
                    onChevronTapped: {
                        navigateToDailyPlan = true
                    }
                )

                if presenter.hasAnyTasks {
                    StartFocusCard(
                        timerState: presenter.timerViewModel.state,
                        focusedTimeDisplay: presenter.taskViewModel.focusedTimeDisplay,
                        soundName: presenter.soundViewModel.displayName,
                        isEnabled: presenter.hasCurrentTask,
                        onStart: presenter.requestStartTimer,
                        onResume: presenter.resumeTimer,
                        onSoundTapped: { showSoundPicker = true }
                    )
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
        .background(AppColors.background)
        .navigationDestination(isPresented: $navigateToDailyPlan) {
            DailyPlanView(date: Date(), modelContext: modelContext)
        }
        .onAppear {
            presenter.onAppear()
        }
        .onChange(of: navigateToDailyPlan) { _, isNavigating in
            if !isNavigating {
                // Returned from DailyPlan - reload current task
                presenter.onAppear()
            }
        }
        .onChange(of: presenter.showFocusView) { _, isShowing in
            if !isShowing {
                // Returned from Focus - reload current task
                presenter.onAppear()
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
                }
            )
        }
    }

    private var appLogo: some View {
        HStack {
            Image("AppLogoWhite")
                .resizable()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Spacer()
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: FocusTask.self, FocusSession.self, DailyRecord.self, configurations: config)

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

    return NavigationStack {
        HomeView(modelContext: container.mainContext)
    }
}
