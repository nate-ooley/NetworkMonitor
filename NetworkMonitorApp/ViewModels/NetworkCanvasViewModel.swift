import SwiftUI
import Combine

@MainActor
class NetworkCanvasViewModel: ObservableObject {
    @Published var discoveredDevices: [NetworkDevice] = []
    @Published var devicesOnCanvas: [NetworkDevice] = []
    @Published var connections: [NetworkConnection] = []
    @Published var isScanning: Bool = false
    
    private let discoveryEngine = NetworkDiscoveryEngine()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        startDiscovery()
    }
    
    private func setupBindings() {
        discoveryEngine.$discoveredDevices
            .receive(on: DispatchQueue.main)
            .assign(to: &$discoveredDevices)
        
        discoveryEngine.$isScanning
            .receive(on: DispatchQueue.main)
            .assign(to: &$isScanning)
    }
    
    func startDiscovery() {
        discoveryEngine.startDiscovery()
    }
    
    func refreshDevices() {
        discoveryEngine.refreshDevices()
    }
    
    func addDeviceToCanvas(_ device: NetworkDevice, at position: CGPoint? = nil) {
        var newDevice = device
        
        // Position device
        if let position = position {
            newDevice.position = position
        } else {
            // Auto-position in a grid
            let gridSize: CGFloat = 150
            let col = devicesOnCanvas.count % 5
            let row = devicesOnCanvas.count / 5
            newDevice.position = CGPoint(
                x: 300 + CGFloat(col) * gridSize,
                y: 100 + CGFloat(row) * gridSize
            )
        }
        
        devicesOnCanvas.append(newDevice)
    }
    
    func moveDevice(_ device: NetworkDevice, to position: CGPoint) {
        if let index = devicesOnCanvas.firstIndex(where: { $0.id == device.id }) {
            devicesOnCanvas[index].position = position
        }
    }
    
    func getDevicePosition(_ deviceId: UUID) -> CGPoint? {
        devicesOnCanvas.first(where: { $0.id == deviceId })?.position
    }
    
    func removeDevice(_ device: NetworkDevice) {
        devicesOnCanvas.removeAll(where: { $0.id == device.id })
        connections.removeAll(where: {
            $0.fromDeviceId == device.id || $0.toDeviceId == device.id
        })
    }
    
    func createConnection(from: NetworkDevice, to: NetworkDevice) {
        let connection = NetworkConnection(
            fromDeviceId: from.id,
            toDeviceId: to.id,
            connectionType: .ethernet
        )
        connections.append(connection)
    }
}


//
//  NetworkCanvasViewModel.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//

