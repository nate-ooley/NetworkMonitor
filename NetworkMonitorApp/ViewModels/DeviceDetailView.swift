import SwiftUI
import AppKit
import Foundation

struct DeviceDetailView: View {
    let details: DeviceDetails
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        List {
            Section("Overview") {
                if theme.style == .retro1986 {
                    HStack(spacing: 8) {
                        Image(details.retroIconName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                        Text(details.displayName)
                            .font(Font.chicago(size: 16))
                    }
                } else {
                    LabeledContent("Name", value: details.displayName)
                }
                LabeledContent("Type", value: details.type)
                LabeledContent("Domain", value: details.domain)
                if let hp = details.hostAndPort {
                    LabeledContent("Host", value: hp)
                }
                if !details.addresses.isEmpty {
                    LabeledContent("Addresses", value: details.addresses.joined(separator: ", "))
                }
            }

            if details.macAddress != nil || details.vendor != nil {
                Section("Hardware") {
                    if let mac = details.macAddress {
                        LabeledContent("MAC", value: mac)
                    }
                    if let vendor = details.vendor {
                        LabeledContent("Vendor", value: vendor)
                    }
                }
            }

            if !details.txtRecords.isEmpty {
                // Group records by category
                let groupedRecords = Dictionary(grouping: details.txtRecords.sorted(by: { $0.key < $1.key })) { key, _ in
                    TXTRecordInterpreter.category(forKey: key)
                }
                
                ForEach(TXTRecordInterpreter.Category.allCases, id: \.self) { category in
                    if let records = groupedRecords[category], !records.isEmpty {
                        Section {
                            ForEach(records, id: \.key) { key, value in
                                let interpretation = TXTRecordInterpreter.interpret(key: key, value: value)
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Image(systemName: iconForKey(key))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 20)
                                        
                                        Text(interpretation.readableKey)
                                            .font(.headline)
                                        
                                        Spacer()
                                        
                                        Text(key)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                    
                                    Text(interpretation.interpretedValue)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .textSelection(.enabled)
                                        .padding(.leading, 28)
                                    
                                    if interpretation.interpretedValue != value && !value.isEmpty {
                                        HStack(spacing: 4) {
                                            Image(systemName: "info.circle")
                                                .font(.caption2)
                                            Text("Raw value:")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                            Text(value)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .textSelection(.enabled)
                                        }
                                        .padding(.leading, 28)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                        } header: {
                            Label(category.rawValue, systemImage: iconForCategory(category))
                        }
                    }
                }
                
                Section {
                    Text("These properties are advertised by the device's network service and provide additional information about its capabilities and configuration.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Device Details")
    }
    
    // MARK: - Helper Methods
    
    private func iconForCategory(_ category: TXTRecordInterpreter.Category) -> String {
        switch category {
        case .identity: return "person.text.rectangle"
        case .capabilities: return "star.circle"
        case .network: return "lock.shield"
        case .version: return "arrow.triangle.2.circlepath"
        case .status: return "bolt.circle"
        case .configuration: return "gearshape"
        case .other: return "doc.text"
        }
    }
    
    private func iconForKey(_ key: String) -> String {
        let lowerKey = key.lowercased()
        
        switch lowerKey {
        // Identity
        case "fn", "name", "dn": return "person.text.rectangle"
        case "md", "model", "product": return "cube.box"
        case "ty": return "tag"
        case "note": return "note.text"
        case "id", "uid", "deviceid": return "barcode"
        
        // Version/Firmware
        case "fw", "fwv", "version", "vs", "ver", "srcvers": return "arrow.triangle.2.circlepath"
        
        // Network/Security
        case "acl", "pw", "dk", "et": return "lock.shield"
        case "act": return "bolt.circle"
        case "sf", "flags", "ff": return "flag"
        case "tp": return "network"
        
        // Printer
        case "pdl", "rp": return "printer"
        case "color": return "paintpalette"
        case "duplex", "copies": return "doc.on.doc"
        case "scan": return "doc.viewfinder"
        case "fax": return "phone"
        case "papermax": return "doc"
        case "qtotal", "priority": return "list.number"
        case "adminurl": return "gearshape"
        
        // AirPlay/Media
        case "am", "vn": return "airplayvideo"
        case "ch", "cn", "sr", "ss": return "waveform"
        case "features", "ft": return "star.circle"
        
        // HomeKit
        case "c#", "s#": return "house"
        case "ci": return "square.grid.2x2"
        case "pv": return "hand.raised"
        case "sh": return "number"
        
        // File Sharing
        case "machine", "sys", "wg": return "folder.badge.gearshape"
        
        // Web/URL
        case "path", "u": return "globe"
        
        default: return "doc.text"
        }
    }
}

#Preview {
    NavigationStack {
        DeviceDetailView(details: DeviceDetails(
            name: "My Printer",
            type: "_ipp._tcp.",
            domain: "local.",
            hostName: "printer.local",
            port: 631,
            addresses: ["192.168.1.10", "fe80::1%en0"],
            txtRecords: [
                "ty": "HP LaserJet Pro",
                "product": "HP LaserJet Pro MFP M428fdw",
                "pdl": "application/postscript,application/pdf,image/urf",
                "color": "1",
                "duplex": "1",
                "scan": "1",
                "papermax": "legal",
                "adminurl": "http://printer.local",
                "txtvers": "1",
                "qtotal": "1",
                "fw": "2.4.1.5",
                "note": "Office Printer - 2nd Floor",
                "act": "0"
            ],
            macAddress: "3C:5A:37:AA:BB:CC",
            vendor: "Hewlett Packard",
            displayName: "Office HP Printer"
        ))
        .environmentObject(ThemeManager())
    }
}

