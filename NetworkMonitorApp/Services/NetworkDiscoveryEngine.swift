import Foundation
import Network

@MainActor
class NetworkDiscoveryEngine: ObservableObject {
    @Published var discoveredDevices: [NetworkDevice] = []
    @Published var isScanning: Bool = false
    
    private var bonjourBrowsers: [NWBrowser] = []
    
    func startDiscovery() {
        isScanning = true
        
        // Start Bonjour discovery (best-effort)
        startBonjourDiscovery()
        
        #if os(macOS)
        // Stimulate ARP table by ping sweeping the local subnet, then read ARP
        let sweeper = PingSweeper()
        sweeper.sweep(concurrency: 64, maxHostsToScan: 512, timeoutMillis: 150) { [weak self] in
            let arp = ARPScanner()
            arp.scanNetwork { [weak self] devices in
                Task { @MainActor in
                    guard let self else { return }
                    print("[ARP] Found \(devices.count) entries after sweep")
                    let arpDevices = devices.map { (ip, mac) in
                        NetworkDevice(
                            name: ip,
                            displayName: ip,
                            ipAddress: ip,
                            macAddress: mac,
                            deviceType: .unknown,
                            isOnline: true,
                            lastSeen: Date()
                        )
                    }
                    let existingIPs = Set(self.discoveredDevices.map { $0.ipAddress })
                    let newOnes = arpDevices.filter { !existingIPs.contains($0.ipAddress) }
                    self.discoveredDevices.append(contentsOf: newOnes)
                    self.isScanning = false
                }
            }
        }
        #else
        // On non-macOS, just run ARP scanner (if available)
        let arp = ARPScanner()
        arp.scanNetwork { [weak self] devices in
            Task { @MainActor in
                guard let self else { return }
                print("[ARP] Found \(devices.count) entries")
                let arpDevices = devices.map { (ip, mac) in
                    NetworkDevice(
                        name: ip,
                        displayName: ip,
                        ipAddress: ip,
                        macAddress: mac,
                        deviceType: .unknown,
                        isOnline: true,
                        lastSeen: Date()
                    )
                }
                let existingIPs = Set(self.discoveredDevices.map { $0.ipAddress })
                let newOnes = arpDevices.filter { !existingIPs.contains($0.ipAddress) }
                self.discoveredDevices.append(contentsOf: newOnes)
                self.isScanning = false
            }
        }
        #endif
    }
    
    func refreshDevices() {
        discoveredDevices.removeAll()
        startDiscovery()
    }
    
    private func startBonjourDiscovery() {
        // Cancel any existing browsers before starting new ones
        bonjourBrowsers.forEach { $0.cancel() }
        bonjourBrowsers.removeAll()

        let parameters = NWParameters()
        let serviceTypes: [String] = [
            "_device-info._tcp",
            "_http._tcp",
            "_https._tcp",
            "_workstation._tcp",
            "_afpovertcp._tcp",
            "_smb._tcp",
            "_ssh._tcp",
            "_sftp-ssh._tcp",
            "_ipp._tcp",
            "_printer._tcp",
            "_airplay._tcp",
            "_raop._tcp",
            "_rfb._tcp",
            "_ftp._tcp"
        ]

        for type in serviceTypes {
            let browser = NWBrowser(
                for: .bonjour(type: type, domain: nil),
                using: parameters
            )

            browser.stateUpdateHandler = { [weak self] newState in
                Task { @MainActor in
                    switch newState {
                    case .ready:
                        print("Bonjour browser ready for \(type)")
                    case .failed(let error):
                        print("Browser failed (\(type)): \(error)")
                        // Do not flip isScanning to false here; ARP sweep will manage it.
                    default:
                        break
                    }
                }
            }

            browser.browseResultsChangedHandler = { [weak self] results, _ in
                Task { @MainActor in
                    for result in results {
                        if case let .service(name, _, _, _) = result.endpoint {
                            self?.handleDiscoveredDevice(name: name)
                        }
                    }
                }
            }

            browser.start(queue: .main)
            bonjourBrowsers.append(browser)
        }
    }
    
    private func handleDiscoveredDevice(name: String) {
        let device = NetworkDevice(
            name: name,
            displayName: name,
            ipAddress: "",
            macAddress: "",
            deviceType: .unknown
        )

        if !discoveredDevices.contains(where: { $0.name == name }) {
            discoveredDevices.append(device)
        }
    }
}


//
//  NetworkDiscoveryEngine.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//


