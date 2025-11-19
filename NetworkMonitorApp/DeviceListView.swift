import SwiftUI

struct DeviceListView: View {
    @StateObject private var discovery = DeviceDiscoveryService()
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        NavigationStack {
            deviceList
                .navigationTitle("Network Devices")
                .toolbar {
                    scanToolbarItem
                    refreshToolbarItem
                    themeToolbarItem
                }
                .onAppear {
                    print("[UI] DeviceListView appeared, starting browse")
                    discovery.startBrowsing()
                }
                .onDisappear {
                    print("[UI] DeviceListView disappeared, stopping browse")
                    discovery.stopBrowsing()
                }
                .scrollContentBackground(theme.style == .retro1986 ? .hidden : .automatic)
                .background(theme.style == .retro1986 ? Color(nsColor: .windowBackgroundColor) : Color(.clear))
        }
    }
    
    // MARK: - List Content
    
    @ViewBuilder
    private var deviceList: some View {
        List {
            if discovery.devices.isEmpty {
                emptyStateSection
            } else {
                devicesSection
            }
            
            if !discovery.discoveredServiceTypes.isEmpty {
                serviceTypesSection
            }
        }
    }
    
    private var emptyStateSection: some View {
        Section {
            Text("No devices discovered yet.")
                .foregroundStyle(.secondary)
            Text("Ensure you're on the same network and services are being advertised.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    private var devicesSection: some View {
        Section("Devices") {
            ForEach(discovery.devices) { device in
                NavigationLink {
                    deviceDetailView(for: device)
                } label: {
                    deviceRow(for: device)
                }
            }
        }
    }
    
    private var serviceTypesSection: some View {
        Section("Discovered Service Types") {
            ForEach(Array(discovery.discoveredServiceTypes).sorted(), id: \.self) { type in
                Text(type)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Device Views
    
    private func deviceDetailView(for device: DiscoveredDevice) -> some View {
        DeviceDetailView(details: DeviceDetails(
            name: device.name,
            type: device.type,
            domain: device.domain,
            hostName: device.hostName,
            port: device.port,
            addresses: device.addresses,
            txtRecords: device.txtRecords,
            macAddress: device.macAddress,
            vendor: device.vendor,
            displayName: device.displayName,
            retroIconName: device.retroIconName
        ))
    }
    
    @ViewBuilder
    private func deviceRow(for device: DiscoveredDevice) -> some View {
        if theme.style == .retro1986 {
            retroDeviceRow(for: device)
        } else {
            modernDeviceRow(for: device)
        }
    }
    
    private func retroDeviceRow(for device: DiscoveredDevice) -> some View {
        HStack(spacing: 8) {
            Image(device.retroIconName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(device.displayName)
                        .font(.chicago(size: 14))
                    Text(device.type)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                if let host = device.hostName, let port = device.port {
                    Text("\(host):\(port)")
                        .font(.geneva(size: 11))
                } else if let host = device.hostName {
                    Text(host)
                        .font(.geneva(size: 11))
                }
                if !device.addresses.isEmpty {
                    Text(device.addresses.joined(separator: ", "))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .retroMacStyle()
    }
    
    private func modernDeviceRow(for device: DiscoveredDevice) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "network")
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(device.displayName)
                    .font(.headline)
                if let host = device.hostName {
                    Text(host)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !device.addresses.isEmpty {
                    Text(device.addresses.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let port = device.port {
                Text(":\(port)")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Toolbar Items
    
    private var scanToolbarItem: some ToolbarContent {
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
    }
    
    private var refreshToolbarItem: some ToolbarContent {
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
    
    private var themeToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Menu {
                Picker("Theme", selection: $theme.style) {
                    ForEach(ThemeManager.Theme.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
            } label: {
                Label("Theme", systemImage: theme.style == .retro1986 ? "calendar.circle" : "paintbrush")
            }
        }
    }
}

#Preview {
    DeviceListView()
}
