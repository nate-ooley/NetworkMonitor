import Foundation

extension ARPScanner {
    // Backwards-compat convenience that returns [ip: mac]
    func scanNetworkMap(completion: @escaping ([String: String]) -> Void) {
        self.scanNetwork { pairs in
            var dict: [String: String] = [:]
            for (ip, mac) in pairs { dict[ip] = mac }
            completion(dict)
        }
    }
}
