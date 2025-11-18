import Foundation
import Combine
import CoreGraphics

final class NetworkDiscoveryEngine: ObservableObject {
    @Published private(set) var discoveredDevices: [NetworkDevice] = []
    @Published private(set) var isScanning: Bool = false

    private var timer: Timer?

    func startDiscovery() {
        guard !isScanning else { return }
        isScanning = true
        // Simulate discovery by emitting a few devices over time
        var counter = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self = self else { return }
            counter += 1
            let device = NetworkDevice(name: "Device \(counter)", position: CGPoint(x: 50 * counter, y: 40 * counter))
            self.discoveredDevices.append(device)
            if counter >= 5 {
                self.stopDiscovery()
            }
        }
    }

    func refreshDevices() {
        stopDiscovery()
        discoveredDevices.removeAll()
        startDiscovery()
    }

    private func stopDiscovery() {
        isScanning = false
        timer?.invalidate()
        timer = nil
    }
}
