import Foundation

enum CommunicationProtocol: String, Codable, CaseIterable {
    case snmp = "SNMP"
    case ssh = "SSH"
    case http = "HTTP"
    case https = "HTTPS"
    case telnet = "Telnet"
    case mqtt = "MQTT"
    case modbus = "Modbus"
    case upnp = "UPnP"
    case onvif = "ONVIF"
    case denonAVR = "Denon AVR Protocol"
    case tpLinkKasa = "TP-Link Kasa"
    case rtsp = "RTSP"
    
    var defaultPort: Int {
        switch self {
        case .snmp: return 161
        case .ssh: return 22
        case .http: return 80
        case .https: return 443
        case .telnet: return 23
        case .mqtt: return 1883
        case .modbus: return 502
        case .upnp: return 1900
        case .onvif: return 80
        case .denonAVR: return 23
        case .rtsp: return 554
        default: return 0
        }
    }
    
    var description: String {
        switch self {
        case .snmp: return "Network management protocol"
        case .ssh: return "Secure shell access"
        case .http, .https: return "Web interface"
        case .mqtt: return "IoT messaging protocol"
        case .onvif: return "Camera control protocol"
        default: return self.rawValue
        }
    }
}

//
//  CommunicationProtocol.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//

