import Foundation
import SwiftUI

struct NetworkDevice: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var displayName: String
    var ipAddress: String
    var macAddress: String
    var manufacturer: String?
    var deviceType: DeviceType
    var openPorts: [Int]
    var serviceName: String?
    var serviceType: String?
    var position: CGPoint
    var isOnline: Bool
    var lastSeen: Date
    var recommendedProtocols: [CommunicationProtocol]
    var confidence: Double // AI confidence level
    
    init(
        id: UUID = UUID(),
        name: String = "Unknown Device",
        displayName: String = "Unknown",
        ipAddress: String = "",
        macAddress: String = "",
        manufacturer: String? = nil,
        deviceType: DeviceType = .unknown,
        openPorts: [Int] = [],
        serviceName: String? = nil,
        serviceType: String? = nil,
        position: CGPoint = .zero,
        isOnline: Bool = true,
        lastSeen: Date = Date(),
        recommendedProtocols: [CommunicationProtocol] = [],
        confidence: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.manufacturer = manufacturer
        self.deviceType = deviceType
        self.openPorts = openPorts
        self.serviceName = serviceName
        self.serviceType = serviceType
        self.position = position
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.recommendedProtocols = recommendedProtocols
        self.confidence = confidence
    }
    
    var iconName: String {
        switch deviceType {
        case .mac: return "desktopcomputer"
        case .iPhone, .iPad: return "iphone"
        case .appleTv: return "appletv"
        case .ciscoRouter: return "wifi.router"
        case .ciscoSwitch: return "network"
        case .printer: return "printer"
        case .ipCamera: return "video"
        case .nas: return "externaldrive"
        case .smartSpeaker: return "homepod"
        case .thermostat: return "thermometer"
        default: return "questionmark.circle"
        }
    }
}

//
//  NetworkDevice.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//

