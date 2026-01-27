//
//  TimerServiceProtocol.swift
//  BulletJournal
//

import Foundation
import Combine

enum TimerState: Equatable, Sendable {
    case idle
    case running
    case paused
}

protocol TimerServiceProtocol: AnyObject {
    var state: TimerState { get }
    var elapsedSeconds: Int { get }
    var statePublisher: AnyPublisher<TimerState, Never> { get }
    var tickPublisher: AnyPublisher<Int, Never> { get }

    func start()
    func pause()
    func resume()
    func stop() -> Int
    func reset()
}
