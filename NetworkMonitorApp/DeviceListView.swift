import SwiftUI

struct DeviceListView: View {
    @StateObject private var discovery = DeviceDiscoveryService()

    var body: some View {
        NavigationStack {
            List {
                if discovery.devices.isEmpty {
                    Section {
                        Text("No devices discovered yet.")
                            .foregroundStyle(.secondary)
                        Text("Ensure you're on the same network and services are being advertised.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Devices") {
                        ForEach(discovery.devices) { device in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(device.name)
                                        .font(.headline)
                                    Text(device.type)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                if let host = device.hostName, let port = device.port {
                                    Text("Host: \(host):\(port)")
                                        .font(.subheadline)
                                } else if let host = device.hostName {
                                    Text("Host: \(host)")
                                        .font(.subheadline)
                                }
                                if !device.addresses.isEmpty {
                                    Text(device.addresses.joined(separator: ", "))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }

                if !discovery.discoveredServiceTypes.isEmpty {
                    Section("Discovered Service Types") {
                        ForEach(Array(discovery.discoveredServiceTypes).sorted(), id: \.self) { type in
                            Text(type)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Network Devices")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(discovery.isBrowsing ? "Stop" : "Scan") {
                        if discovery.isBrowsing {
                            print("[UI] Stop browsing pressed")
                            discovery.stopBrowsing()
                        } else {
                            print("[UI] Start browsing pressed")
                            discovery.startBrowsing()
                        }
                    }
                }
                ToolbarItem(placement: .navigation) {
                    Button("Refresh") {
                        print("[UI] Refresh pressed")
                        discovery.stopBrowsing()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            discovery.startBrowsing()
                        }
                    }
                    .disabled(discovery.isBrowsing)
                }
            }
            .onAppear {
                print("[UI] DeviceListView appeared, starting browse")
                discovery.startBrowsing()
            }
            .onDisappear {
                print("[UI] DeviceListView disappeared, stopping browse")
                discovery.stopBrowsing()
            }
        }
    }
}

#Preview {
    DeviceListView()
}
