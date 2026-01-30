//
//  AmbientSoundServiceProtocol.swift
//  BulletJournal
//

import Foundation
import Combine

protocol AmbientSoundServiceProtocol: AnyObject {
    var currentSound: AmbientSound { get }
    var isPlaying: Bool { get }
    var currentSoundPublisher: AnyPublisher<AmbientSound, Never> { get }
    var isPlayingPublisher: AnyPublisher<Bool, Never> { get }

    func play(_ sound: AmbientSound)
    func pause()
    func resume()
    func stop()
    func setVolume(_ volume: Float)
}
