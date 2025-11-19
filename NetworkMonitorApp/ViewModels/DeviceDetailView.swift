import SwiftUI
import AppKit

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
                Section("Service Metadata (TXT)") {
                    ForEach(details.txtRecords.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        LabeledContent(key, value: value)
                    }
                }
            }
        }
        .navigationTitle("Device Details")
    }
}

#Preview {
    NavigationStack {
        DeviceDetailView(details: DeviceDetails(
            name: "My Device",
            type: "_http._tcp.",
            domain: "local.",
            hostName: "my-device.local",
            port: 80,
            addresses: ["192.168.1.10", "fe80::1%en0"],
            txtRecords: ["model": "Test 1000", "fw": "1.2.3"],
            macAddress: "7C:6D:62:AA:BB:CC",
            vendor: "Apple, Inc."
        ))
    }
}

