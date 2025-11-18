import Foundation
import SwiftUI

struct NetworkConnection: Identifiable, Codable {
    let id: UUID
    let fromDeviceId: UUID
    let toDeviceId: UUID
    var connectionType: ConnectionType
    var bandwidth: String?
    var latency: Double?
    
    init(
        id: UUID = UUID(),
        fromDeviceId: UUID,
        toDeviceId: UUID,
        connectionType: ConnectionType = .ethernet,
        bandwidth: String? = nil,
        latency: Double? = nil
    ) {
        self.id = id
        self.fromDeviceId = fromDeviceId
        self.toDeviceId = toDeviceId
        self.connectionType = connectionType
        self.bandwidth = bandwidth
        self.latency = latency
    }
    
    // Helper computed properties for drawing
    var from: CGPoint {
        // Will be populated by ViewModel
        return .zero
    }
    
    var to: CGPoint {
        // Will be populated by ViewModel
        return .zero
    }
}

enum ConnectionType: String, Codable {
    case ethernet = "Ethernet"
    case wifi = "WiFi"
    case virtual = "Virtual"
    case unknown = "Unknown"
    
    var color: Color {
        switch self {
        case .ethernet: return .blue
        case .wifi: return .green
        case .virtual: return .purple
        case .unknown: return .gray
        }
    }
}


//
//  NetworkConnection.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//

