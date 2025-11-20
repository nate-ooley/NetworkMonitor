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
    
    // Helper function to get modern SF Symbol for device
    private func modernIcon(for device: DiscoveredDevice) -> String {
        let lowerType = device.type.lowercased()
        let lowerName = device.name.lowercased()
        let vendorLower = device.vendor?.lowercased() ?? ""
        
        // Printers
        if lowerType.contains("_printer._tcp") || lowerType.contains("_ipp._tcp") || lowerType.contains("_pdl-datastream._tcp") {
            return "printer.fill"
        }
        
        // AirPlay devices
        if lowerType.contains("_airplay._tcp") || lowerType.contains("_raop._tcp") {
            if lowerName.contains("tv") || device.displayName.lowercased().contains("tv") {
                return "tv.fill"
            }
            return "hifispeaker.fill"
        }
        
        // Workstations / Computers
        if lowerType.contains("_workstation._tcp") || lowerName.contains("mac") || vendorLower.contains("apple") {
            if lowerName.contains("book") || lowerName.contains("mbp") || device.displayName.lowercased().contains("book") {
                return "laptopcomputer"
            }
            return "desktopcomputer"
        }
        
        // File servers / NAS
        if lowerType.contains("_smb._tcp") || lowerType.contains("_afpovertcp._tcp") || lowerType.contains("_nfs._tcp") {
            if vendorLower.contains("synology") || vendorLower.contains("qnap") {
                return "externaldrive.fill.badge.timemachine"
            }
            return "server.rack"
        }
        
        // SSH servers
        if lowerType.contains("_ssh._tcp") || lowerType.contains("_sftp-ssh._tcp") {
            if vendorLower.contains("cisco") || vendorLower.contains("ubiquiti") || vendorLower.contains("netgear") || vendorLower.contains("tp-link") {
                return "wifi.router.fill"
            }
            return "terminal.fill"
        }
        
        // VNC / Screen Sharing
        if lowerType.contains("_rfb._tcp") {
            return "display"
        }
        
        // HTTP/HTTPS
        if lowerType.contains("_http._tcp") || lowerType.contains("_https._tcp") {
            // Cameras
            if lowerName.contains("cam") || vendorLower.contains("hikvision") || vendorLower.contains("arlo") || vendorLower.contains("wyze") || vendorLower.contains("nest") {
                return "video.fill"
            }
            // NAS web interfaces
            if vendorLower.contains("synology") || vendorLower.contains("qnap") {
                return "externaldrive.fill.badge.timemachine"
            }
            // Routers
            if vendorLower.contains("cisco") || vendorLower.contains("ubiquiti") || vendorLower.contains("tp-link") || vendorLower.contains("netgear") {
                return "wifi.router.fill"
            }
            return "globe"
        }
        
        // HomeKit
        if lowerType.contains("_hap._tcp") {
            return "house.fill"
        }
        
        // Media servers
        if lowerType.contains("_plex._tcp") || lowerType.contains("_plexmediasvr._tcp") {
            return "play.rectangle.on.rectangle.fill"
        }
        
        // Vendor-based fallbacks
        if vendorLower.contains("apple") {
            return "applelogo"
        }
        if vendorLower.contains("cisco") || vendorLower.contains("ubiquiti") || vendorLower.contains("netgear") || vendorLower.contains("tp-link") {
            return "wifi.router.fill"
        }
        if vendorLower.contains("hp") || vendorLower.contains("hewlett") || vendorLower.contains("canon") || vendorLower.contains("brother") || vendorLower.contains("epson") {
            return "printer.fill"
        }
        
        // Default
        return "network"
    }
    
    // Helper function to get icon color
    private func iconColor(for device: DiscoveredDevice) -> Color {
        let lowerType = device.type.lowercased()
        let vendorLower = device.vendor?.lowercased() ?? ""
        
        if lowerType.contains("_printer._tcp") || lowerType.contains("_ipp._tcp") { return .cyan }
        if lowerType.contains("_airplay._tcp") || lowerType.contains("_raop._tcp") { return .purple }
        if lowerType.contains("_workstation._tcp") || vendorLower.contains("apple") { return .blue }
        if lowerType.contains("_smb._tcp") || lowerType.contains("_afpovertcp._tcp") { return .orange }
        if lowerType.contains("_ssh._tcp") || lowerType.contains("_sftp-ssh._tcp") { return .green }
        if lowerType.contains("_http._tcp") || lowerType.contains("_https._tcp") { return .indigo }
        if lowerType.contains("_hap._tcp") { return .pink }
        if vendorLower.contains("cisco") || vendorLower.contains("ubiquiti") { return .teal }
        
        return .gray
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
                HStack(spacing: 6) {
                    Text(device.displayName)
                        .font(.chicago(size: 14))
                    
                    if let vendor = device.vendor {
                        Text(vendor)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let host = device.hostName, let port = device.port {
                    Text("\(host):\(port)")
                        .font(.geneva(size: 11))
                } else if let host = device.hostName {
                    Text(host)
                        .font(.geneva(size: 11))
                }
                
                HStack(spacing: 8) {
                    if !device.addresses.isEmpty {
                        Text(device.addresses.first ?? "")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let mac = device.macAddress {
                        Text(mac)
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .retroMacStyle()
    }
    
    private func modernDeviceRow(for device: DiscoveredDevice) -> some View {
        HStack(spacing: 12) {
            // Modern glossy icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor(for: device).gradient)
                    .frame(width: 44, height: 44)
                    .shadow(color: iconColor(for: device).opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: modernIcon(for: device))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(device.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let vendor = device.vendor {
                        Text(vendor)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                if let host = device.hostName, host != device.displayName {
                    Text(host)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    if !device.addresses.isEmpty {
                        Label(device.addresses.first ?? "", systemImage: "network")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let port = device.port {
                        Label(":\(port)", systemImage: "globe")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let mac = device.macAddress {
                        Label(mac, systemImage: "person.crop.circle.badge.checkmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
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
