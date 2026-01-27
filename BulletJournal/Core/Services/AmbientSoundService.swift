//
//  AmbientSoundService.swift
//  BulletJournal
//

import Foundation
import AVFoundation
import Combine

final class AmbientSoundService: AmbientSoundServiceProtocol {
    private(set) var currentSound: AmbientSound = .none
    private(set) var isPlaying: Bool = false

    private var audioPlayer: AVAudioPlayer?
    private let currentSoundSubject = CurrentValueSubject<AmbientSound, Never>(.none)

    var currentSoundPublisher: AnyPublisher<AmbientSound, Never> {
        currentSoundSubject.eraseToAnyPublisher()
    }

    init() {
        setupAudioSession()
    }

    func play(_ sound: AmbientSound) {
        stop()

        currentSound = sound
        currentSoundSubject.send(sound)

        guard sound != .none,
              let fileName = sound.fileName,
              let url = Bundle.main.url(forResource: fileName, withExtension: "mp3") else {
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentSound = .none
        currentSoundSubject.send(.none)
    }

    func setVolume(_ volume: Float) {
        audioPlayer?.volume = max(0, min(1, volume))
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio session setup failed
        }
    }
}
