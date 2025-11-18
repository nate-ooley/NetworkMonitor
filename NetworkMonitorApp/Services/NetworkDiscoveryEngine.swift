import Foundation
import Network

@MainActor
class NetworkDiscoveryEngine: ObservableObject {
    @Published var discoveredDevices: [NetworkDevice] = []
    @Published var isScanning: Bool = false
    
    private var bonjourBrowser: NWBrowser?
    
    func startDiscovery() {
        isScanning = true
        
        // Start Bonjour discovery
        startBonjourDiscovery()
        
        // Add some mock devices for testing
        addMockDevices()
    }
    
    func refreshDevices() {
        discoveredDevices.removeAll()
        startDiscovery()
    }
    
    private func startBonjourDiscovery() {
        let parameters = NWParameters()
        bonjourBrowser = NWBrowser(
            for: .bonjour(type: "_device-info._tcp", domain: nil),
            using: parameters
        )
        
        bonjourBrowser?.stateUpdateHandler = { [weak self] newState in
            Task { @MainActor in
                switch newState {
                case .ready:
                    print("Bonjour browser ready")
                case .failed(let error):
                    print("Browser failed: \(error)")
                    self?.isScanning = false
                default:
                    break
                }
            }
        }
        
        bonjourBrowser?.browseResultsChangedHandler = { [weak self] results, changes in
            Task { @MainActor in
                for result in results {
                    if case let .service(name, _, _, _) = result.endpoint {
                        self?.handleDiscoveredDevice(name: name)
                    }
                }
            }
        }
        
        bonjourBrowser?.start(queue: .main)
    }
    
    private func handleDiscoveredDevice(name: String) {
        let device = NetworkDevice(
            name: name,
            displayName: name,
            ipAddress: "192.168.1.\(Int.random(in: 2...254))",
            macAddress: generateRandomMAC(),
            deviceType: .unknown
        )
        
        if !discoveredDevices.contains(where: { $0.id == device.id }) {
            discoveredDevices.append(device)
        }
    }
    
    // Mock devices for testing
    private func addMockDevices() {
        let mockDevices = [
            NetworkDevice(
                name: "MacBook Pro",
                displayName: "MacBook Pro",
                ipAddress: "192.168.1.100",
                macAddress: "00:1B:63:84:45:E6",
                manufacturer: "Apple",
                deviceType: .mac,
                confidence: 0.95
            ),
            NetworkDevice(
                name: "iPhone",
                displayName: "iPhone 15 Pro",
                ipAddress: "192.168.1.101",
                macAddress: "00:1B:63:84:45:E7",
                manufacturer: "Apple",
                deviceType: .iPhone,
                confidence: 0.98
            ),
            NetworkDevice(
                name: "Cisco Switch",
                displayName: "Catalyst 2960",
                ipAddress: "192.168.1.1",
                macAddress: "00:1E:F7:A8:9C:00",
                manufacturer: "Cisco",
                deviceType: .ciscoSwitch,
                openPorts: [22, 23, 80, 443, 161],
                confidence: 0.90
            ),
            NetworkDevice(
                name: "Hisense Camera",
                displayName: "Front Door Camera",
                ipAddress: "192.168.1.50",
                macAddress: "A8:5E:45:D1:23:45",
                deviceType: .ipCamera,
                openPorts: [80, 554],
                confidence: 0.85
            )
        ]
        
        discoveredDevices.append(contentsOf: mockDevices)
    }
    
    private func generateRandomMAC() -> String {
        let bytes = (0..<6).map { _ in String(format: "%02X", Int.random(in: 0...255)) }
        return bytes.joined(separator: ":")
    }
}


//
//  NetworkDiscoveryEngine.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//

