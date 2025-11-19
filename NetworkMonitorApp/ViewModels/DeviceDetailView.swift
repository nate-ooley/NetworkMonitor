import SwiftUI

struct DeviceDetailView: View {
    let details: DeviceDetails

    var body: some View {
        List {
            Section("Overview") {
                LabeledContent("Name", value: details.displayName)
                LabeledContent("Type", value: details.type)
                LabeledContent("Domain", value: details.domain)
                if let hp = details.hostAndPort {
                    LabeledContent("Host", value: hp)
                }
            }
            
            if !details.addresses.isEmpty {
                Section("Addresses") {
                    ForEach(details.addresses, id: \.self) { addr in
                        Text(addr)
                            .font(.body.monospaced())
                    }
                }
            }
        }
        .navigationTitle("Device Details")
    }
}

#Preview {
    NavigationStack {
        DeviceDetailView(details: DeviceDetails(name: "My Device", type: "_http._tcp.", domain: "local.", hostName: "my-device.local", port: 80, addresses: ["192.168.1.10", "fe80::1%en0"]))
    }
}
