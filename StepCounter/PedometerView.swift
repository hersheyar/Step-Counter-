//
//  PedometerView.swift
//  StepCounter
//
//  Created by Andrew Hershey on 11/6/25.
//

import SwiftUI

struct PedometerView: View {
    @StateObject private var vm = PedometerViewModel()

    var body: some View {
        VStack(spacing: 15) {
            Text("Steps: \(vm.steps)")
            Text("Distance: \(vm.distanceKMText)")
            Text("Floors: \(vm.floorsAscended ?? 0)")
            Text(vm.statusText)
                .foregroundColor(.gray)

            Button(vm.isRunning ? "Stop" : "Start") {
                vm.isRunning ? vm.stop() : vm.start()
            }

            Button("Reset") {
                vm.resetSession()
            }

            Toggle("Mock Mode", isOn: $vm.usingMock)
                .onChange(of: vm.usingMock) { oldValue, newValue in
                    vm.setMockMode(newValue)
                }
        }
        .padding()
    }
}

#Preview {
    PedometerView()
}
