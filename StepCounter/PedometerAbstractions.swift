//
//  PedometerAbstractions.swift
//  StepCounter
//
//  Created by Andrew Hershey on 11/6/25.
//
import Foundation
import CoreMotion

protocol PedometerLike: AnyObject {
    func isStepCountingAvailable() -> Bool
    func authorizationStatus() -> CMAuthorizationStatus
    func start(from: Date, onUpdate: @escaping (CMPedometerData?, Error?) -> Void)
    func stop()
    func query(from: Date, to: Date, completion: @escaping (CMPedometerData?, Error?) -> Void)
}

final class RealPedometerService: PedometerLike {
    private let pedometer = CMPedometer()

    func isStepCountingAvailable() -> Bool { CMPedometer.isStepCountingAvailable() }

    func authorizationStatus() -> CMAuthorizationStatus { CMPedometer.authorizationStatus() }

    func start(from: Date, onUpdate: @escaping (CMPedometerData?, Error?) -> Void) {
        pedometer.startUpdates(from: from, withHandler: onUpdate)
    }

    func stop() { pedometer.stopUpdates() }

    func query(from: Date, to: Date, completion: @escaping (CMPedometerData?, Error?) -> Void) {
        pedometer.queryPedometerData(from: from, to: to, withHandler: completion)
    }
}

final class MockPedometerService: PedometerLike {
    private var timer: Timer?
    private var steps: Int = 0
    private var startDate: Date = Date()

    func isStepCountingAvailable() -> Bool { true }

    func authorizationStatus() -> CMAuthorizationStatus { .authorized }

    func start(from: Date, onUpdate: @escaping (CMPedometerData?, Error?) -> Void) {
        startDate = from
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.steps += Int.random(in: 3...12) // pretend walking
            let mock = CMPedometerDataMock(steps: self.steps,
                                           distanceMeters: Double(self.steps) * 0.7, // ~0.7 m/step
                                           floors: self.steps % 40 == 0 ? 1 : 0,
                                           start: self.startDate,
                                           end: Date())
            onUpdate(mock, nil)
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() { timer?.invalidate(); timer = nil }

    func query(from: Date, to: Date, completion: @escaping (CMPedometerData?, Error?) -> Void) {
        let mock = CMPedometerDataMock(steps: steps,
                                       distanceMeters: Double(steps) * 0.7,
                                       floors: steps / 100,
                                       start: from, end: to)
        completion(mock, nil)
    }
}

// A tiny wrapper to mimic CMPedometerData using a subclass.
final class CMPedometerDataMock: CMPedometerData {
    private let _numberOfSteps: NSNumber
    private let _distance: NSNumber?
    private let _floorsAscended: NSNumber?
    private let _startDate: Date
    private let _endDate: Date

    init(steps: Int, distanceMeters: Double?, floors: Int?, start: Date, end: Date) {
        _numberOfSteps = NSNumber(value: steps)
        _distance = distanceMeters != nil ? NSNumber(value: distanceMeters!) : nil
        _floorsAscended = floors != nil ? NSNumber(value: floors!) : nil
        _startDate = start
        _endDate = end
        super.init()
    }
    required init?(coder:NSCoder){
        fatalError("init(coder:) has not been implemented")
    }
    
    override var numberOfSteps: NSNumber { _numberOfSteps }
    override var distance: NSNumber? { _distance }
    override var floorsAscended: NSNumber? { _floorsAscended }
    override var startDate: Date { _startDate }
    override var endDate: Date { _endDate }
}

