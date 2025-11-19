import SwiftUI
import Combine

@MainActor
class NetworkCanvasViewModel: ObservableObject {
    @Published var discoveredDevices: [NetworkDevice] = []
    @Published var devicesOnCanvas: [NetworkDevice] = []
    @Published var connections: [NetworkConnection] = []
    @Published var isScanning: Bool = false
    @Published var selectedDevice: NetworkDevice? = nil
    
    private let discoveryService = DeviceDiscoveryService()
    private var cancellables = Set<AnyCancellable>()
    private var deviceIdByKey: [String: UUID] = [:]
    
    init() {
        setupBindings()
        startDiscovery()
    }
    
    private func setupBindings() {
        discoveryService.$devices
            .map { [weak self] devices -> [NetworkDevice] in
                guard let self else { return devices.map { NetworkDevice(name: $0.name) } }
                var seenKeys = Set<String>()
                return devices.compactMap { d in
                    let key = "\(d.name)|\(d.type)|\(d.domain)"
                    // Skip exact duplicates by key
                    guard seenKeys.insert(key).inserted else { return nil }
                    // Reuse a stable UUID per key so SwiftUI doesn't treat updates as new rows
                    let id: UUID
                    if let existing = self.deviceIdByKey[key] {
                        id = existing
                    } else {
                        let newId = UUID()
                        self.deviceIdByKey[key] = newId
                        id = newId
                    }
                    return NetworkDevice(id: id, name: d.name)
                }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$discoveredDevices)
        
        discoveryService.$isBrowsing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isScanning)
    }
    
    func startDiscovery() {
        discoveryService.startBrowsing()
    }
    
    func refreshDevices() {
        discoveryService.stopBrowsing()
        discoveryService.startBrowsing()
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
    
    // Selection helpers
    func selectDevice(_ device: NetworkDevice) {
        selectedDevice = device
    }
    
    func clearSelection() {
        selectedDevice = nil
    }
    
    // Map a canvas device back to rich discovery details, if available
    func details(for device: NetworkDevice) -> DeviceDetails {
        if let match = discoveryService.devices.first(where: { $0.name == device.name }) {
            return DeviceDetails(
                name: match.name,
                type: match.type,
                domain: match.domain,
                hostName: match.hostName,
                port: match.port,
                addresses: match.addresses
            )
        }
        return DeviceDetails(
            name: device.name,
            type: "Unknown",
            domain: "local.",
            hostName: nil,
            port: nil,
            addresses: []
        )
    }
}


//
//  NetworkCanvasViewModel.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//


