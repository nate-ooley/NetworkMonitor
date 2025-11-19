import Foundation

struct DeviceDetails: Identifiable, Equatable {
    let id: UUID
    let name: String
    let type: String
    let domain: String
    let hostName: String?
    let port: Int?
    let addresses: [String]

    init(id: UUID = UUID(), name: String, type: String, domain: String, hostName: String?, port: Int?, addresses: [String]) {
        self.id = id
        self.name = name
        self.type = type
        self.domain = domain
        self.hostName = hostName
        self.port = port
        self.addresses = addresses
    }

    var displayName: String { name }

    var hostAndPort: String? {
        if let hostName, let port { return "\(hostName):\(port)" }
        if let hostName { return hostName }
        return nil
    }
}
