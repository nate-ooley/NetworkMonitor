import SwiftUI
import CoreData
import Network

// Note: Mock device data removed. Devices shown here come from DeviceDiscoveryService / NetworkDiscoveryEngine.

struct ContentView: View {
    @EnvironmentObject private var networkMonitor: NetworkStatusMonitor
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NetworkLog.timestamp, ascending: false)],
        animation: .default)
    private var logs: FetchedResults<NetworkLog>
    
    @StateObject private var discovery = DeviceDiscoveryService()

    var body: some View {
        NavigationView {
            VStack {
                // Status Header
                HStack {
                    Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                        .foregroundColor(networkMonitor.isConnected ? .green : .red)
                        .font(.title)
                    
                    VStack(alignment: .leading) {
                        Text(networkMonitor.isConnected ? "Online" : "Offline")
                            .font(.headline)
                            .foregroundColor(networkMonitor.isConnected ? .green : .red)
                        Text("Type: \(connectionTypeDescription())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                
                Divider()

                // Device Discovery Controls
                HStack {
                    Text("Devices")
                        .font(.headline)
                    Spacer()
                    if discovery.isBrowsing {
                        Button("Stop Scan") { discovery.stopBrowsing() }
                            .buttonStyle(.bordered)
                    } else {
                        Button("Scan Network") { discovery.startBrowsing() }
                            .buttonStyle(.borderedProminent)
                    }
                }
                .padding(.horizontal)

                // Discovered Devices List
                if !discovery.devices.isEmpty {
                    List(discovery.devices) { device in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(device.name)
                                    .font(.subheadline).bold()
                                Spacer()
                                if let port = device.port {
                                    Text(":\(port)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text(device.type.replacingOccurrences(of: ".", with: ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(device.hostName ?? "Resolving…")
                                .font(.caption2)
                            if device.addresses.isEmpty {
                                Text("Waiting for address…")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text(device.addresses.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 220)
                } else {
                    Text(discovery.isBrowsing ? "Scanning…" : "No devices found yet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }

                // Logs List
                List {
                    ForEach(logs) { log in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(log.method ?? "UNK")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(4)
                                    .background(colorForMethod(log.method))
                                    .cornerRadius(4)
                                    .foregroundColor(.white)
                                
                                Text(log.url ?? "Unknown URL")
                                    .font(.subheadline)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("\(log.statusCode)")
                                    .foregroundColor(log.statusCode >= 200 && log.statusCode < 300 ? .green : .red)
                                
                                if let date = log.timestamp {
                                    Text(date, style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("Network Monitor")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addSampleLog) {
                        Label("Add Test Log", systemImage: "plus")
                    }
                }
            }
        }
    }

    @MainActor
    private func connectionTypeDescription() -> String {
        // Adjust this mapping to your NetworkStatusMonitor's real API.
        // We avoid generic inference issues by explicitly typing the dictionary as [String: Any].
        let mirror = Mirror(reflecting: networkMonitor)
        var children: [String: Any] = [:]
        for child in mirror.children {
            if let label = child.label {
                children[label] = child.value
            }
        }

        if let type = children["connectionType"] as? String { return type }
        if let type = children["currentInterface"] as? String { return type }
        if let isWiFi = children["isOnWiFi"] as? Bool, isWiFi { return "Wi‑Fi" }
        if let isCell = children["isOnCellular"] as? Bool, isCell { return "Cellular" }

        return networkMonitor.isConnected ? "Unknown" : "None"
    }

    private func colorForMethod(_ method: String?) -> Color {
        switch method {
        case "GET": return .blue
        case "POST": return .green
        case "DELETE": return .red
        case "PUT": return .orange
        default: return .gray
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { logs[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
    
    private func addSampleLog() {
        withAnimation {
            let newLog = NetworkLog(context: viewContext)
            newLog.timestamp = Date()
            newLog.url = "https://api.apple.com/test"
            newLog.method = "GET"
            newLog.statusCode = 200
            newLog.status = "Success"
            newLog.duration = 0.45
            try? viewContext.save()
        }
    }
}


//
//  ContentView.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/18/25.
//


