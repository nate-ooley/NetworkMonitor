import Foundation

#if os(macOS)
final class PingSweeper {
    struct IPv4Interface {
        let address: in_addr
        let netmask: in_addr
    }

    func sweep(concurrency: Int = 32, maxHostsToScan: Int = 1024, timeoutMillis: Int = 200, completion: @escaping () -> Void) {
        guard let iface = primaryIPv4Interface() else {
            print("[PingSweep] No IPv4 interface found; skipping sweep")
            completion()
            return
        }

        // Convert to host byte order for math
        let ipHost = UInt32(bigEndian: iface.address.s_addr)
        let maskHost = UInt32(bigEndian: iface.netmask.s_addr)
        let network = ipHost & maskHost
        let broadcast = network | ~maskHost
        var start = network &+ 1
        var end = broadcast &- 1

        // Cap scan size to avoid huge subnets
        let totalHosts = (end >= start) ? (end &- start &+ 1) : 0
        if totalHosts > maxHostsToScan {
            end = start &+ UInt32(maxHostsToScan &- 1)
        }

        let myIP = ipHost
        let group = DispatchGroup()
        let semaphore = DispatchSemaphore(value: max(1, concurrency))
        let queue = DispatchQueue(label: "PingSweeper.queue", qos: .utility)

        var launched = 0
        var scanned = 0

        for ip in start...end {
            if ip == myIP { continue }
            group.enter()
            semaphore.wait()
            queue.async {
                self.ping(ipHostOrder: ip, timeoutMillis: timeoutMillis) {
                    scanned += 1
                    semaphore.signal()
                    group.leave()
                }
                launched += 1
            }
        }

        group.notify(queue: .main) {
            print("[PingSweep] Completed sweep. Launched: \(launched), Scanned: \(scanned)")
            completion()
        }
    }

    private func primaryIPv4Interface() -> IPv4Interface? {
        var ifaddrPtr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddrPtr) == 0, let first = ifaddrPtr else { return nil }
        defer { freeifaddrs(ifaddrPtr) }

        var candidate: IPv4Interface?

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let ifa = ptr?.pointee {
            defer { ptr = ifa.ifa_next }
            guard let addr = ifa.ifa_addr?.pointee, addr.sa_family == UInt8(AF_INET) else { continue }
            let flags = Int32(ifa.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0
            if !isUp || isLoopback { continue }

            let name = String(cString: ifa.ifa_name)
            let sa4 = withUnsafePointer(to: ifa.ifa_addr!.pointee) { ptr -> sockaddr_in in
                return ptr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
            }
            let netmask4 = withUnsafePointer(to: ifa.ifa_netmask!.pointee) { ptr -> sockaddr_in in
                return ptr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
            }
            let candidateIface = IPv4Interface(address: sa4.sin_addr, netmask: netmask4.sin_addr)

            // Prefer en0/en1; otherwise take the first non-loopback UP interface
            if name == "en0" || name == "en1" { return candidateIface }
            if candidate == nil { candidate = candidateIface }
        }
        return candidate
    }

    private func ping(ipHostOrder: UInt32, timeoutMillis: Int, done: @escaping () -> Void) {
        let ipString = ipStringFromHostOrder(ipHostOrder)
        let task = Process()
        task.launchPath = "/sbin/ping"
        task.arguments = ["-c", "1", "-W", String(timeoutMillis), ipString]
        task.terminationHandler = { _ in done() }
        do { try task.run() } catch { done() }
    }

    private func ipStringFromHostOrder(_ value: UInt32) -> String {
        let b1 = (value >> 24) & 0xFF
        let b2 = (value >> 16) & 0xFF
        let b3 = (value >> 8) & 0xFF
        let b4 = value & 0xFF
        return "\(b1).\(b2).\(b3).\(b4)"
    }
}
#endif
