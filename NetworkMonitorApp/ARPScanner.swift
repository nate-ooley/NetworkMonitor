import Foundation

final class ARPScanner {
    typealias ARPPair = (ip: String, mac: String)

    // Scans the local ARP table and returns (ip, mac) pairs.
    // On macOS, this parses the output of `/usr/sbin/arp -an`.
    // On iOS and other platforms, ARP table access isn't available, so this returns an empty result.
    func scanNetwork(completion: @escaping ([(String, String)]) -> Void) {
        #if os(macOS)
        DispatchQueue.global(qos: .utility).async {
            let pairs = self.readARPTable()
            completion(pairs.map { ($0.ip, $0.mac) })
        }
        #else
        DispatchQueue.global(qos: .utility).async {
            completion([])
        }
        #endif
    }

    #if os(macOS)
    private func readARPTable() -> [ARPPair] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/arp")
        process.arguments = ["-an"]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            return []
        }
        process.waitUntilExit()

        let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }
        return parseARP(output)
    }

    private func parseARP(_ output: String) -> [ARPPair] {
        var results: [ARPPair] = []
        // Typical macOS line examples:
        // ? (192.168.1.1) at 3c:52:82:aa:bb:cc on en0 ifscope [ethernet]
        // ? (192.168.1.42) at (incomplete) on en0 ifscope [ethernet]
        let lines = output.split(separator: "\n")
        for line in lines {
            guard let ipStart = line.firstIndex(of: "("),
                  let ipEnd = line.firstIndex(of: ")"),
                  ipStart < ipEnd else { continue }
            let ip = String(line[line.index(after: ipStart)..<ipEnd])

            if let atRange = line.range(of: " at ") {
                let macStart = atRange.upperBound
                let rest = line[macStart...]
                let mac = rest.prefix { $0 != " " }
                let macStr = String(mac)
                if macStr.lowercased() != "(incomplete)" {
                    results.append((ip: ip, mac: macStr))
                }
            }
        }
        return results
    }
    #endif
}
