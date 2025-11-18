class ProtocolManager {
    func detectProtocols(for device: NetworkDevice, completion: @escaping ([CommunicationProtocol]) -> Void) {
        var protocols: [CommunicationProtocol] = []
        
        // Check for SNMP
        if device.openPorts.contains(161) {
            testSNMP(device) { works in
                if works { protocols.append(.snmp) }
            }
        }
        
        // Check for SSH
        if device.openPorts.contains(22) {
            protocols.append(.ssh)
        }
        
        // Check for HTTP/HTTPS
        if device.openPorts.contains(80) || device.openPorts.contains(443) {
            protocols.append(.http)
        }
        
        // Check for proprietary protocols
        if device.manufacturer == "Denon" {
            protocols.append(.denonAVR)
        }
        
        if device.manufacturer == "TP-Link" {
            protocols.append(.tpLinkKasa)
        }
        
        completion(protocols)
    }
}

enum CommunicationProtocol {
    case snmp
    case ssh
    case http
    case telnet
    case mqtt
    case denonAVR
    case tpLinkKasa
    case onvif  // for cameras
    case modbus // for industrial devices
}

//
//  PortScanner.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//

