//
//  SoundPickerView.swift
//  BulletJournal
//

import SwiftUI

struct SoundPickerView: View {
    @Binding var selectedSound: AmbientSound
    @Binding var isPresented: Bool

    let onSoundSelected: (AmbientSound) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(AmbientSound.allCases) { sound in
                    Button {
                        selectedSound = sound
                        onSoundSelected(sound)
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: sound.iconName)
                                .foregroundStyle(AppColors.secondaryText)
                                .frame(width: 24)

                            Text(sound.localizedName)
                                .foregroundStyle(AppColors.primaryText)

                            Spacer()

                            if selectedSound == sound {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppColors.progressGreen)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("home.sound.label"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(AppColors.primaryText)
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedSound: AmbientSound = .whiteNoise
        @State private var isPresented = true

        var body: some View {
            SoundPickerView(
                selectedSound: $selectedSound,
                isPresented: $isPresented,
                onSoundSelected: { _ in }
            )
        }
    }

    return PreviewWrapper()
}
