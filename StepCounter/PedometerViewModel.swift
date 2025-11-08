//
//  PedometerViewModel.swift
//  StepCounter
//
//  Created by Andrew Hershey on 11/6/25.
//

import Foundation
import Combine
import CoreMotion

@MainActor
final class PedometerViewModel: ObservableObject {
    @Published var steps: Int = 0
    @Published var distanceMeters: Double?
    @Published var floorsAscended: Int?
    @Published var statusText: String = "Not started"
    @Published var isRunning: Bool = false
    @Published var usingMock: Bool = false
    @Published var errorMessage: String?

    private var service: PedometerLike = RealPedometerService()

    init(service: PedometerLike? = nil) {
        if let service { self.service = service }
    }

    func setMockMode(_ enabled: Bool) {
        stop()
        usingMock = enabled
        service = enabled ? MockPedometerService() : RealPedometerService()
        statusText = enabled ? "Mock ready" : "Not started"
    }

    func start() {
        guard service.isStepCountingAvailable() else {
            statusText = "Step counting not available on this device."
            return
        }

        switch service.authorizationStatus() {
        case .denied:
            statusText = "Permission denied. Enable in Settings > Privacy > Motion & Fitness"
            return
        case .restricted:
            statusText = "Permission restricted on this device"
            return
        default:
            break // .authorized or .notDetermined
        }

        steps = 0
        distanceMeters = nil
        floorsAscended = nil
        errorMessage = nil
        statusText = usingMock ? "Tracking (Mock)..." : "Tracking..."
        isRunning = true

        service.start(from: Date()) { [weak self] data, error in
            guard let self else { return }
            if let error = error {
                Task { @MainActor in
                    self.errorMessage = error.localizedDescription
                    self.statusText = "Error"
                    self.isRunning = false
                }
                return
            }

            guard let d = data else { return }
            Task { @MainActor in
                self.steps = d.numberOfSteps.intValue
                self.distanceMeters = d.distance?.doubleValue
                self.floorsAscended = d.floorsAscended?.intValue
            }
        }
    }

    func stop() {
        service.stop()
        isRunning = false
        statusText = "Stopped"
    }
    
    func resetSession() {
        steps = 0
        distanceMeters = nil
        floorsAscended = nil
        statusText = isRunning ? (usingMock ? "Tracking (Mock)..." : "Tracking..."): "Not started"
    }
    
    var distanceKMText: String {
        guard let m = distanceMeters else { return "_" }
        return String(format: "%.2f km", m / 1000.0)
    }
}
