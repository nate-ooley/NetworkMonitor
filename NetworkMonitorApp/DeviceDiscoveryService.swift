import Foundation
import Network

final class DiscoveredDevice: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: String
    let domain: String
    let hostName: String?
    let port: Int?
    let addresses: [String]

    init(name: String, type: String, domain: String, hostName: String?, port: Int?, addresses: [String]) {
        self.name = name
        self.type = type
        self.domain = domain
        self.hostName = hostName
        self.port = port
        self.addresses = addresses
    }

    static func == (lhs: DiscoveredDevice, rhs: DiscoveredDevice) -> Bool {
        return lhs.name == rhs.name && lhs.type == rhs.type && lhs.domain == rhs.domain
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(domain)
    }
}

@MainActor
final class DeviceDiscoveryService: NSObject, ObservableObject {
    @Published private(set) var devices: [DiscoveredDevice] = []
    @Published private(set) var isBrowsing: Bool = false

    private var browsers: [NetServiceBrowser] = []
    private var services: Set<NetService> = []

    // Common Bonjour service types to look for
    private let serviceTypes: [String] = [
        "_http._tcp.",
        "_https._tcp.",
        "_ssh._tcp.",
        "_airplay._tcp.",
        "_ipp._tcp.",
        "_printer._tcp.",
        "_ftp._tcp.",
        "_smb._tcp.",
        "_afpovertcp._tcp.",
        "_rfb._tcp.",
    ]

    func startBrowsing() {
        guard !isBrowsing else { return }
        isBrowsing = true
        devices.removeAll()
        services.removeAll()
        browsers.removeAll()

        for type in serviceTypes {
            let browser = NetServiceBrowser()
            browser.delegate = self
            browsers.append(browser)
            browser.searchForServices(ofType: type, inDomain: "local.")
        }
    }

    func stopBrowsing() {
        for browser in browsers {
            browser.stop()
        }
        browsers.removeAll()
        services.removeAll()
        isBrowsing = false
    }
}

extension DeviceDiscoveryService: NetServiceBrowserDelegate {
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        services.insert(service)
        service.delegate = self
        service.resolve(withTimeout: 5.0)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        services.remove(service)
        // Remove matching device by name/type/domain
        devices.removeAll { $0.name == service.name && $0.type == service.type && $0.domain == service.domain }
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) { }
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) { }
}

extension DeviceDiscoveryService: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        let addresses = (sender.addresses ?? []).compactMap { data -> String? in
            data.withUnsafeBytes { (rawPtr: UnsafeRawBufferPointer) -> String? in
                guard let base = rawPtr.baseAddress else { return nil }
                let addr = base.assumingMemoryBound(to: sockaddr.self)
                if addr.pointee.sa_family == sa_family_t(AF_INET) {
                    var addr4 = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                    var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                    let ptr = withUnsafePointer(to: &addr4.sin_addr) {
                        inet_ntop(AF_INET, $0, &buffer, socklen_t(INET_ADDRSTRLEN))
                    }
                    if ptr != nil { return String(cString: buffer) }
                } else if addr.pointee.sa_family == sa_family_t(AF_INET6) {
                    var addr6 = addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
                    var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                    let ptr = withUnsafePointer(to: &addr6.sin6_addr) {
                        inet_ntop(AF_INET6, $0, &buffer, socklen_t(INET6_ADDRSTRLEN))
                    }
                    if ptr != nil { return String(cString: buffer) }
                }
                return nil
            }
        }

        let device = DiscoveredDevice(
            name: sender.name,
            type: sender.type,
            domain: sender.domain,
            hostName: sender.hostName,
            port: sender.port == -1 ? nil : sender.port,
            addresses: addresses
        )

        // Deduplicate by identity (name/type/domain)
        if let idx = devices.firstIndex(where: { $0.name == device.name && $0.type == device.type && $0.domain == device.domain }) {
            devices[idx] = device
        } else {
            devices.append(device)
        }
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        // Could log or handle errors; ignore for now.
    }
}
