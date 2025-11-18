import Foundation
import CoreGraphics

struct NetworkDevice: Identifiable, Equatable {
    let id: UUID
    var name: String
    var position: CGPoint

    init(id: UUID = UUID(), name: String, position: CGPoint = .zero) {
        self.id = id
        self.name = name
        self.position = position
    }
}

enum ConnectionType: String, Codable {
    case ethernet
    case wifi
    case bluetooth
}

struct NetworkConnection: Identifiable, Equatable, Codable {
    let id: UUID
    let fromDeviceId: UUID
    let toDeviceId: UUID
    let connectionType: ConnectionType

    init(id: UUID = UUID(), fromDeviceId: UUID, toDeviceId: UUID, connectionType: ConnectionType) {
        self.id = id
        self.fromDeviceId = fromDeviceId
        self.toDeviceId = toDeviceId
        self.connectionType = connectionType
    }
}
