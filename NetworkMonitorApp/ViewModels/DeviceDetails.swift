import Foundation

struct DeviceDetails: Identifiable, Equatable {
    let id: UUID
    let name: String
    let type: String
    let domain: String
    let hostName: String?
    let port: Int?
    let addresses: [String]
    let txtRecords: [String: String]
    let macAddress: String?
    let vendor: String?
    let displayName: String
    let retroIconName: String

    init(id: UUID = UUID(), name: String, type: String, domain: String, hostName: String?, port: Int?, addresses: [String], txtRecords: [String: String] = [:], macAddress: String? = nil, vendor: String? = nil, displayName: String? = nil, retroIconName: String? = nil) {
        self.id = id
        self.name = name
        self.type = type
        self.domain = domain
        self.hostName = hostName
        self.port = port
        self.addresses = addresses
        self.txtRecords = txtRecords
        self.macAddress = macAddress
        self.vendor = vendor
        self.displayName = displayName ?? name
        self.retroIconName = retroIconName ?? "RetroUnknown"
    }

    var hostAndPort: String? {
        if let hostName, let port { return "\(hostName):\(port)" }
        if let hostName { return hostName }
        return nil
    }
}
