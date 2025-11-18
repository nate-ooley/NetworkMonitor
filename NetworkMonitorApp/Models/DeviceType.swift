import Foundation

enum DeviceType: String, Codable, CaseIterable {
    // Apple Devices
    case mac = "Mac"
    case iPhone = "iPhone"
    case iPad = "iPad"
    case appleTv = "Apple TV"
    case homePod = "HomePod"
    case airPlayDevice = "AirPlay Device"
    
    // Network Infrastructure
    case ciscoRouter = "Cisco Router"
    case ciscoSwitch = "Cisco Switch"
    case router = "Router"
    case switch_ = "Switch"
    case accessPoint = "Access Point"
    
    // Servers
    case linuxServer = "Linux Server"
    case windowsServer = "Windows Server"
    case webServer = "Web Server"
    case nas = "NAS"
    
    // IoT & Smart Home
    case smartSpeaker = "Smart Speaker"
    case smartBulb = "Smart Bulb"
    case thermostat = "Thermostat"
    case doorbell = "Smart Doorbell"
    case smartPlug = "Smart Plug"
    case ipCamera = "IP Camera"
    
    // Peripherals
    case printer = "Printer"
    case scanner = "Scanner"
    
    // Media Devices
    case denonAVR = "Denon Receiver"
    case tv = "Smart TV"
    case streamingDevice = "Streaming Device"
    
    // Industrial/IoT
    case mqttDevice = "MQTT Device"
    case modbusDevice = "Modbus Device"
    
    // Generic
    case unknown = "Unknown"
    
    var category: DeviceCategory {
        switch self {
        case .mac, .iPhone, .iPad, .appleTv, .homePod:
            return .apple
        case .ciscoRouter, .ciscoSwitch, .router, .switch_, .accessPoint:
            return .networking
        case .linuxServer, .windowsServer, .webServer, .nas:
            return .server
        case .smartSpeaker, .smartBulb, .thermostat, .doorbell, .smartPlug:
            return .smartHome
        case .printer, .scanner:
            return .peripheral
        case .denonAVR, .tv, .streamingDevice:
            return .media
        case .ipCamera:
            return .security
        default:
            return .other
        }
    }
}

enum DeviceCategory: String {
    case apple = "Apple Devices"
    case networking = "Network Equipment"
    case server = "Servers"
    case smartHome = "Smart Home"
    case peripheral = "Peripherals"
    case media = "Media Devices"
    case security = "Security"
    case other = "Other"
}

//
//  DeviceType.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//

