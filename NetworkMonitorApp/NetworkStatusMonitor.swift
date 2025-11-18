import Foundation
import Network
import SwiftUI

final class NetworkStatusMonitor: ObservableObject {
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var interfaceType: String = "Unknown"

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkStatusMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            let connected = path.status == .satisfied
            let type: String
            if path.usesInterfaceType(.wifi) { type = "Wi‑Fi" }
            else if path.usesInterfaceType(.cellular) { type = "Cellular" }
            else if path.usesInterfaceType(.wiredEthernet) { type = "Ethernet" }
            else if path.usesInterfaceType(.loopback) { type = "Loopback" }
            else if path.usesInterfaceType(.other) { type = "Other" }
            else { type = "Unavailable" }

            DispatchQueue.main.async {
                self.isConnected = connected
                self.interfaceType = type
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
