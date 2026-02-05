//
//  AmbientSoundService.swift
//  BulletJournal
//

import Foundation
import AVFoundation
import Combine
import os.log

@MainActor
final class AmbientSoundService: AmbientSoundServiceProtocol {
    private(set) var currentSound: AmbientSound = .none
    private(set) var isPlaying: Bool = false

    private var audioPlayer: AVAudioPlayer?
    private var fadingOutPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?
    private var targetVolume: Float = 1.0
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "BulletJournal", category: "AmbientSound")

    private let currentSoundSubject = CurrentValueSubject<AmbientSound, Never>(.none)
    private let isPlayingSubject = CurrentValueSubject<Bool, Never>(false)

    private enum Crossfade {
        static let duration: TimeInterval = 1.0
        static let stepInterval: TimeInterval = 0.05
        static var steps: Int { Int(duration / stepInterval) }
    }

    var currentSoundPublisher: AnyPublisher<AmbientSound, Never> {
        currentSoundSubject.eraseToAnyPublisher()
    }

    var isPlayingPublisher: AnyPublisher<Bool, Never> {
        isPlayingSubject.eraseToAnyPublisher()
    }

    init() {
        setupAudioSession()
    }

    func play(_ sound: AmbientSound) {
        guard sound != currentSound else { return }

        cancelFade()

        // .none 선택 시 fade out 후 정지
        guard sound != .none,
              let fileName = sound.fileName,
              let url = Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
            fadeOutAndStop()
            currentSound = sound
            currentSoundSubject.send(sound)
            return
        }

        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.volume = 0
            newPlayer.prepareToPlay()
            newPlayer.play()

            // 기존 플레이어는 fade out 대상으로 이동
            fadingOutPlayer = audioPlayer
            audioPlayer = newPlayer

            currentSound = sound
            currentSoundSubject.send(sound)
            isPlaying = true
            isPlayingSubject.send(true)

            crossfade()
        } catch {
            isPlaying = false
            isPlayingSubject.send(false)
        }
    }

    func pause() {
        cancelFade()
        audioPlayer?.pause()
        isPlaying = false
        isPlayingSubject.send(false)
    }

    func resume() {
        guard let audioPlayer, currentSound != .none else { return }
        audioPlayer.play()
        isPlaying = true
        isPlayingSubject.send(true)
    }

    func stop() {
        cancelFade()
        audioPlayer?.stop()
        audioPlayer = nil
        fadingOutPlayer?.stop()
        fadingOutPlayer = nil
        isPlaying = false
        isPlayingSubject.send(false)
        currentSound = .none
        currentSoundSubject.send(.none)
    }

    func setVolume(_ volume: Float) {
        targetVolume = max(0, min(1, volume))
        audioPlayer?.volume = targetVolume
    }

    // MARK: - Crossfade

    private func crossfade() {
        let steps = Crossfade.steps
        let fadeOutStart = fadingOutPlayer?.volume ?? 0
        var step = 0

        fadeTimer = Timer.scheduledTimer(withTimeInterval: Crossfade.stepInterval, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            MainActor.assumeIsolated {
                step += 1
                let progress = Float(step) / Float(steps)

                self.audioPlayer?.volume = progress * self.targetVolume
                self.fadingOutPlayer?.volume = fadeOutStart * (1 - progress)

                if step >= steps {
                    timer.invalidate()
                    self.fadingOutPlayer?.stop()
                    self.fadingOutPlayer = nil
                    self.fadeTimer = nil
                }
            }
        }
    }

    private func fadeOutAndStop() {
        guard let player = audioPlayer, player.volume > 0 else {
            cleanupPlayers()
            return
        }

        fadingOutPlayer = player
        audioPlayer = nil
        let startVolume = player.volume
        let steps = Crossfade.steps
        var step = 0

        isPlaying = false
        isPlayingSubject.send(false)

        fadeTimer = Timer.scheduledTimer(withTimeInterval: Crossfade.stepInterval, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            MainActor.assumeIsolated {
                step += 1
                let progress = Float(step) / Float(steps)

                self.fadingOutPlayer?.volume = startVolume * (1 - progress)

                if step >= steps {
                    timer.invalidate()
                    self.fadingOutPlayer?.stop()
                    self.fadingOutPlayer = nil
                    self.fadeTimer = nil
                }
            }
        }
    }

    private func cancelFade() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        fadingOutPlayer?.stop()
        fadingOutPlayer = nil
    }

    private func cleanupPlayers() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        isPlayingSubject.send(false)
    }

    // MARK: - Audio Session

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("Audio session setup failed: \(error.localizedDescription)")
        }
    }
}
