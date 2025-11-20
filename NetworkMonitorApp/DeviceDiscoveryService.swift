import Foundation
import Combine
import Network

final class DiscoveredDevice: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let type: String
    let domain: String
    var hostName: String?
    var port: Int?
    var addresses: [String]
    var txtRecords: [String: String]
    var macAddress: String?
    var vendor: String?
    var displayName: String
    var retroIconName: String

    init(name: String, type: String, domain: String, hostName: String?, port: Int?, addresses: [String], txtRecords: [String: String] = [:], macAddress: String? = nil, vendor: String? = nil, displayName: String? = nil, retroIconName: String? = nil) {
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

    static func == (lhs: DiscoveredDevice, rhs: DiscoveredDevice) -> Bool {
        return lhs.name == rhs.name && lhs.type == rhs.type && lhs.domain == rhs.domain
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(domain)
    }
}

final class DeviceDiscoveryService: NSObject, ObservableObject {
    @Published private(set) var devices: [DiscoveredDevice] = []
    @Published private(set) var isBrowsing: Bool = false
    @Published private(set) var discoveredServiceTypes: Set<String> = []

    // Cached ARP map: ip -> mac
    private var arpCache: [String: String] = [:]

    // Meta-browser for discovering available service types on the LAN
    private var typeBrowser: NetServiceBrowser?
    // Per-type service browsers
    private var serviceBrowsers: [String: NetServiceBrowser] = [:]
    // Track active NetService objects so we can resolve/update
    private var services: [String: NetService] = [:] // key: name|type|domain

    private var fallbackBrowseTimer: Timer?

    private func key(for service: NetService) -> String {
        return "\(service.name)|\(service.type)|\(service.domain)"
    }

    func startBrowsing() {
        guard !isBrowsing else { return }
        isBrowsing = true
        devices.removeAll()
        discoveredServiceTypes.removeAll()
        services.removeAll()
        serviceBrowsers.values.forEach { $0.stop() }
        serviceBrowsers.removeAll()

        // Start meta-browsing for service types
        let tb = NetServiceBrowser()
        tb.delegate = self
        typeBrowser = tb
        tb.searchForServices(ofType: "_services._dns-sd._udp.", inDomain: "local.")

        // Fallback: if meta-browsing doesn't reveal types soon, try common ones
        fallbackBrowseTimer?.invalidate()
        fallbackBrowseTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            guard let self else { return }
            if self.discoveredServiceTypes.isEmpty {
                let commonTypes = [
                    "_http._tcp.",
                    "_https._tcp.",
                    "_ipp._tcp.",
                    "_printer._tcp.",
                    "_raop._tcp.",
                    "_airplay._tcp.",
                    "_workstation._tcp.",
                    "_smb._tcp.",
                    "_afpovertcp._tcp.",
                    "_ssh._tcp.",
                    "_sftp-ssh._tcp.",
                    "_rfb._tcp.",
                    "_ftp._tcp."
                ]
                commonTypes.forEach { self.startBrowsing(type: $0) }
            }
        }
    }

    func stopBrowsing() {
        typeBrowser?.stop()
        typeBrowser = nil
        fallbackBrowseTimer?.invalidate()
        fallbackBrowseTimer = nil
        serviceBrowsers.values.forEach { $0.stop() }
        serviceBrowsers.removeAll()
        services.removeAll()
        isBrowsing = false
    }

    private func startBrowsing(type: String) {
        guard serviceBrowsers[type] == nil else { return }
        let browser = NetServiceBrowser()
        browser.delegate = self
        serviceBrowsers[type] = browser
        browser.searchForServices(ofType: type, inDomain: "local.")
    }

    private func upsertDevice(from service: NetService, addresses: [String]? = nil, txtRecords: [String: String]? = nil, macAddress: String? = nil, vendor: String? = nil) {
        let host = service.hostName
        let port = (service.port == -1) ? nil : service.port
        let incomingAddrs = addresses ?? []

        let keyMatch: (DiscoveredDevice) -> Bool = { $0.name == service.name && $0.type == service.type && $0.domain == service.domain }
        if let idx = devices.firstIndex(where: keyMatch) {
            var existing = devices[idx]
            // Merge/override fields
            if !incomingAddrs.isEmpty { existing.addresses = incomingAddrs }
            if let tr = txtRecords { existing.txtRecords = tr }
            if let mac = macAddress { existing.macAddress = mac }
            if let ven = vendor { existing.vendor = ven }
            existing.hostName = host
            existing.port = port
            // Re-classify using current info
            let classification = classifyDevice(
                name: existing.name,
                type: existing.type,
                hostName: existing.hostName,
                port: existing.port,
                addresses: existing.addresses,
                txtRecords: existing.txtRecords,
                macAddress: existing.macAddress,
                vendor: existing.vendor
            )
            existing.displayName = classification.displayName
            existing.retroIconName = classification.icon
            devices[idx] = existing
        } else {
            let tr = txtRecords ?? [:]
            let classification = classifyDevice(
                name: service.name,
                type: service.type,
                hostName: host,
                port: port,
                addresses: incomingAddrs,
                txtRecords: tr,
                macAddress: macAddress,
                vendor: vendor
            )
            let device = DiscoveredDevice(
                name: service.name,
                type: service.type,
                domain: service.domain,
                hostName: host,
                port: port,
                addresses: incomingAddrs,
                txtRecords: tr,
                macAddress: macAddress,
                vendor: vendor,
                displayName: classification.displayName,
                retroIconName: classification.icon
            )
            devices.append(device)
        }
    }

    private func classifyDevice(
        name: String,
        type: String,
        hostName: String?,
        port: Int?,
        addresses: [String],
        txtRecords: [String: String],
        macAddress: String?,
        vendor: String?
    ) -> (displayName: String, icon: String) {
        let lowerName = name.lowercased()
        let lowerHost = hostName?.lowercased() ?? ""
        let lowerType = type.lowercased()
        let vendorLower = vendor?.lowercased() ?? ""
        
        // Extract all potential model/name info from TXT records
        let model = (txtRecords["md"] ?? txtRecords["model"] ?? txtRecords["ty"] ?? "").trimmingCharacters(in: .whitespaces)
        let friendlyName = txtRecords["fn"]?.trimmingCharacters(in: .whitespaces) ?? ""
        let productName = txtRecords["product"]?.trimmingCharacters(in: .whitespaces) ?? ""
        let note = txtRecords["note"]?.trimmingCharacters(in: .whitespaces) ?? ""

        // Prefer explicit friendly names from TXT records
        if !friendlyName.isEmpty {
            return (friendlyName, guessRetroIcon(type: lowerType, vendorLower: vendorLower, nameLower: lowerName, model: model))
        }

        // Try product name
        if !productName.isEmpty {
            return (productName, guessRetroIcon(type: lowerType, vendorLower: vendorLower, nameLower: lowerName, model: model))
        }

        // Printers (IPP/LPR)
        if lowerType.contains("_ipp._tcp") || lowerType.contains("_printer._tcp") || lowerType.contains("_pdl-datastream._tcp") || !model.isEmpty && (txtRecords["ty"] != nil || txtRecords["pdl"] != nil) {
            let base = model.isEmpty ? (vendor ?? "Network Printer") : model
            return (base, "RetroPrinter")
        }

        // AirPlay / RAOP - extract device name from TXT records
        if lowerType.contains("_airplay._tcp") || lowerType.contains("_raop._tcp") {
            let deviceName = txtRecords["am"]?.trimmingCharacters(in: .whitespaces) ?? 
                           txtRecords["model"]?.trimmingCharacters(in: .whitespaces) ?? 
                           model
            let base = deviceName.isEmpty ? name : deviceName
            // Distinguish between speakers and TVs
            if lowerName.contains("tv") || lowerType.contains("appletv") || deviceName.lowercased().contains("tv") {
                return (base, "RetroTV")
            }
            return (base, "RetroSpeaker")
        }

        // Workstations / Macs
        if lowerType.contains("_workstation._tcp") || lowerName.contains("mac") || lowerHost.contains("mac") || vendorLower.contains("apple") {
            // Try to get computer name from TXT or hostname
            let computerName = note.isEmpty ? (hostName?.components(separatedBy: ".").first ?? name) : note
            // Try to infer portable vs desktop from name
            if lowerName.contains("book") || lowerName.contains("mbp") || computerName.lowercased().contains("book") { 
                return (computerName, "RetroMac") 
            }
            return (computerName, "RetroMac")
        }

        // File servers / NAS
        if lowerType.contains("_smb._tcp") || lowerType.contains("_afpovertcp._tcp") || lowerType.contains("_nfs._tcp") {
            let serverName = hostName?.components(separatedBy: ".").first ?? name
            if vendorLower.contains("synology") || vendorLower.contains("qnap") || vendorLower.contains("western digital") {
                return ("\(vendor ?? "NAS") - \(serverName)", "RetroDisk")
            }
            return (serverName, "RetroDisk")
        }

        // SSH-only devices: often routers/switches/servers
        if lowerType.contains("_ssh._tcp") || lowerType.contains("_sftp-ssh._tcp") {
            let deviceName = hostName?.components(separatedBy: ".").first ?? name
            if vendorLower.contains("cisco") || lowerName.contains("router") || lowerHost.contains("router") {
                return ("\(vendor ?? "Router") - \(deviceName)", "RetroRouter")
            }
            if vendorLower.contains("ubiquiti") || vendorLower.contains("mikrotik") {
                return ("\(vendor ?? "Network Device") - \(deviceName)", "RetroRouter")
            }
            return ("SSH Server - \(deviceName)", "RetroServer")
        }

        // VNC / Screen Sharing
        if lowerType.contains("_rfb._tcp") {
            let deviceName = hostName?.components(separatedBy: ".").first ?? name
            return ("Screen Sharing - \(deviceName)", "RetroMac")
        }

        // HTTP/HTTPS - try to determine device type
        if lowerType.contains("_http._tcp") || lowerType.contains("_https._tcp") {
            let deviceName = hostName?.components(separatedBy: ".").first ?? name
            
            // Cameras
            if lowerName.contains("cam") || lowerHost.contains("cam") || vendorLower.contains("hikvision") || vendorLower.contains("arlo") || vendorLower.contains("wyze") || vendorLower.contains("nest") {
                return (model.isEmpty ? "\(vendor ?? "IP Camera") - \(deviceName)" : model, "RetroCamera")
            }
            
            // Web interfaces for routers/switches
            if vendorLower.contains("cisco") || vendorLower.contains("ubiquiti") || vendorLower.contains("tp-link") || vendorLower.contains("netgear") {
                return ("\(vendor ?? "Network Device") - \(deviceName)", "RetroRouter")
            }
            
            // NAS web interfaces
            if vendorLower.contains("synology") || vendorLower.contains("qnap") {
                return ("\(vendor ?? "NAS") - \(deviceName)", "RetroDisk")
            }
            
            // Generic web server
            return ("Web Server - \(deviceName)", "RetroServer")
        }

        // Home automation / IoT
        if lowerType.contains("_hap._tcp") { // HomeKit Accessory Protocol
            let accessoryName = txtRecords["name"] ?? name
            return (accessoryName, "RetroHome")
        }

        // Media servers
        if lowerType.contains("_plex._tcp") || lowerType.contains("_plexmediasvr._tcp") {
            return ("Plex Media Server", "RetroTV")
        }

        // Fallbacks by vendor
        if vendorLower.contains("apple") { 
            let deviceName = hostName?.components(separatedBy: ".").first ?? name
            return (model.isEmpty ? "Apple Device - \(deviceName)" : model, "RetroMac") 
        }
        if vendorLower.contains("hp") || vendorLower.contains("hewlett") || vendorLower.contains("canon") || vendorLower.contains("brother") || vendorLower.contains("epson") { 
            return (model.isEmpty ? "\(vendor ?? "Printer")" : model, "RetroPrinter") 
        }
        if vendorLower.contains("ubiquiti") || vendorLower.contains("tp-link") || vendorLower.contains("netgear") || vendorLower.contains("cisco") || vendorLower.contains("mikrotik") { 
            let deviceName = hostName?.components(separatedBy: ".").first ?? name
            return ("\(vendor ?? "Network Device") - \(deviceName)", "RetroRouter") 
        }

        // Last resort: try to make the service type readable
        let cleanedType = type.replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: "_tcp", with: "")
            .replacingOccurrences(of: "_udp", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .trimmingCharacters(in: .whitespaces)
            .capitalized
        
        let deviceName = hostName?.components(separatedBy: ".").first ?? name
        let label = cleanedType.isEmpty ? deviceName : "\(cleanedType) - \(deviceName)"
        return (label, guessRetroIcon(type: lowerType, vendorLower: vendorLower, nameLower: lowerName, model: model))
    }

    private func guessRetroIcon(type: String, vendorLower: String, nameLower: String, model: String) -> String {
        if type.contains("_printer._tcp") || type.contains("_ipp._tcp") || type.contains("_pdl-datastream._tcp") { return "RetroPrinter" }
        if type.contains("_airplay._tcp") || type.contains("_raop._tcp") {
            if nameLower.contains("tv") || model.lowercased().contains("tv") { return "RetroTV" }
            return "RetroSpeaker"
        }
        if type.contains("_workstation._tcp") { return "RetroMac" }
        if type.contains("_smb._tcp") || type.contains("_afpovertcp._tcp") || type.contains("_nfs._tcp") { return "RetroDisk" }
        if type.contains("_ssh._tcp") || type.contains("_sftp-ssh._tcp") { return "RetroServer" }
        if type.contains("_rfb._tcp") { return "RetroMac" }
        if type.contains("_http._tcp") || type.contains("_https._tcp") {
            if nameLower.contains("cam") || vendorLower.contains("hikvision") || vendorLower.contains("arlo") || vendorLower.contains("wyze") { return "RetroCamera" }
            if vendorLower.contains("synology") || vendorLower.contains("qnap") { return "RetroDisk" }
            return "RetroServer"
        }
        if type.contains("_hap._tcp") { return "RetroHome" }
        if type.contains("_plex._tcp") || type.contains("_plexmediasvr._tcp") { return "RetroTV" }
        if vendorLower.contains("apple") { return "RetroMac" }
        if vendorLower.contains("cisco") || vendorLower.contains("ubiquiti") || vendorLower.contains("netgear") || vendorLower.contains("tp-link") || vendorLower.contains("mikrotik") { return "RetroRouter" }
        if vendorLower.contains("synology") || vendorLower.contains("qnap") { return "RetroDisk" }
        return "RetroUnknown"
    }
}

extension DeviceDiscoveryService: NetServiceBrowserDelegate {
    // Called when meta-browsing finds a service (which, for _services._dns-sd._udp., represents a service TYPE)
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        print("[Browser] didFind: name=\(service.name) type=\(service.type) domain=\(service.domain) moreComing=\(moreComing))")
        if service.type == "_services._dns-sd._udp." {
            // Service name encodes the actual service type. Bonjour returns names like _http._tcp
            let serviceTypeName = service.name + "." // append trailing dot to match ofType format
            discoveredServiceTypes.insert(serviceTypeName)
            startBrowsing(type: serviceTypeName)
            fallbackBrowseTimer?.invalidate()
            fallbackBrowseTimer = nil
        } else {
            // This is a real browser returning an actual service instance
            services[key(for: service)] = service
            service.delegate = self
            // Show early (name/type), addresses will fill after resolve
            upsertDevice(from: service, addresses: [], txtRecords: nil, macAddress: nil, vendor: nil)
            service.resolve(withTimeout: 10.0)
        }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        print("[Browser] didRemove: name=\(service.name) type=\(service.type) domain=\(service.domain) moreComing=\(moreComing))")
        if service.type == "_services._dns-sd._udp." {
            let typeToRemove = service.name + "."
            discoveredServiceTypes.remove(typeToRemove)
            if let b = serviceBrowsers.removeValue(forKey: typeToRemove) {
                b.stop()
            }
        } else {
            services.removeValue(forKey: key(for: service))
            devices.removeAll { $0.name == service.name && $0.type == service.type && $0.domain == service.domain }
        }
    }

    func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("[Browser] didStopSearch")
    }
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        print("[Browser] didNotSearch error=\(errorDict)")
    }
}

extension DeviceDiscoveryService: NetServiceDelegate {
    func netServiceDidResolveAddress(_ sender: NetService) {
        print("[Service] didResolve: name=\(sender.name) type=\(sender.type) domain=\(sender.domain) host=\(sender.hostName ?? "nil") port=\(sender.port)")
        let rawAddresses = sender.addresses ?? []
        let strings: [String] = rawAddresses.compactMap { data -> String? in
            return data.withUnsafeBytes { (rawPtr: UnsafeRawBufferPointer) -> String? in
                guard let base = rawPtr.baseAddress else { return nil }
                let addr = base.assumingMemoryBound(to: sockaddr.self)
                switch Int32(addr.pointee.sa_family) {
                case AF_INET:
                    var a = addr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                    var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                    let ptr = withUnsafeBytes(of: &a.sin_addr) { raw -> UnsafePointer<in_addr> in
                        raw.baseAddress!.assumingMemoryBound(to: in_addr.self)
                    }
                    guard inet_ntop(AF_INET, ptr, &buffer, socklen_t(INET_ADDRSTRLEN)) != nil else { return nil }
                    return String(cString: buffer)
                case AF_INET6:
                    var a6 = addr.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
                    var buffer = [CChar](repeating: 0, count: Int(INET6_ADDRSTRLEN))
                    let ptr6 = withUnsafeBytes(of: &a6.sin6_addr) { raw -> UnsafePointer<in6_addr> in
                        raw.baseAddress!.assumingMemoryBound(to: in6_addr.self)
                    }
                    guard inet_ntop(AF_INET6, ptr6, &buffer, socklen_t(INET6_ADDRSTRLEN)) != nil else { return nil }
                    var ip = String(cString: buffer)
                    // If link-local (fe80::/10), append scope id if present
                    let isLinkLocal: Bool = withUnsafeBytes(of: a6.sin6_addr) { raw -> Bool in
                        let bytes = raw.bindMemory(to: UInt8.self)
                        guard bytes.count >= 2 else { return false }
                        // fe80::/10 => first byte 0xFE, next byte upper 6 bits 0b10xxxx (0x80..0xBF)
                        let b0 = bytes[0]
                        let b1 = bytes[1]
                        return b0 == 0xFE && (b1 & 0xC0) == 0x80
                    }
                    if isLinkLocal, a6.sin6_scope_id != 0 {
                        ip += "%\(a6.sin6_scope_id)"
                    }
                    return ip
                default:
                    return nil
                }
            }
        }
        // Deduplicate while preserving order
        var seen = Set<String>()
        let deduped = strings.filter { seen.insert($0).inserted }

        // Parse TXT records if available
        var txt: [String: String] = [:]
        if let data = sender.txtRecordData() {
            let dict = NetService.dictionary(fromTXTRecord: data)
            txt = dict.reduce(into: [:]) { acc, kv in
                let key = kv.key
                let valueString = String(data: kv.value, encoding: .utf8) ?? ""
                acc[key] = valueString
            }
        }
        // Upsert with addresses and TXT
        upsertDevice(from: sender, addresses: deduped, txtRecords: txt, macAddress: nil, vendor: nil)
        // Attempt ARP correlation for MAC/vendor
        correlateMACAndVendor(for: sender, addresses: deduped)
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("[Service] didNotResolve: name=\(sender.name) type=\(sender.type) domain=\(sender.domain) error=\(errorDict)")
    }

    func netService(_ sender: NetService, didUpdateTXTRecord data: Data) {
        let dict = NetService.dictionary(fromTXTRecord: data)
        let txt: [String: String] = dict.reduce(into: [:]) { acc, kv in
            let key = kv.key
            let valueString = String(data: kv.value, encoding: .utf8) ?? ""
            acc[key] = valueString
        }
        upsertDevice(from: sender, addresses: nil, txtRecords: txt, macAddress: nil, vendor: nil)
    }
    
    private func correlateMACAndVendor(for service: NetService, addresses: [String]) {
        // If we already have a MAC for any address, update and return
        if let mac = addresses.compactMap({ arpCache[$0] }).first {
            let vendor = vendorName(forMAC: mac)
            upsertDevice(from: service, addresses: nil, txtRecords: nil, macAddress: mac, vendor: vendor)
            return
        }
        // Refresh ARP cache and try again
        let arp = ARPScanner()
        arp.scanNetwork { [weak self] pairs in
            guard let self else { return }
            var cache: [String: String] = [:]
            for (ip, mac) in pairs { cache[ip] = mac }
            self.arpCache = cache
            if let mac = addresses.compactMap({ self.arpCache[$0] }).first {
                let vendor = self.vendorName(forMAC: mac)
                DispatchQueue.main.async {
                    self.upsertDevice(from: service, addresses: nil, txtRecords: nil, macAddress: mac, vendor: vendor)
                }
            }
        }
    }

    private func vendorName(forMAC mac: String) -> String? {
        // Normalize: remove separators and uppercase
        let hex = mac.uppercased().replacingOccurrences(of: ":", with: "").replacingOccurrences(of: "-", with: "")
        guard hex.count >= 6 else { return nil }
        let oui = String(hex.prefix(6))
        // Extended built-in OUI map
        let map: [String: String] = [
            // Apple
            "0016CB": "Apple",
            "001451": "Apple",
            "001CB3": "Apple",
            "002332": "Apple",
            "002436": "Apple",
            "002500": "Apple",
            "00254B": "Apple",
            "3451C9": "Apple",
            "7C6D62": "Apple",
            "A4C361": "Apple",
            "B853AC": "Apple",
            "BCEC5D": "Apple",
            "F0DCE2": "Apple",
            
            // Networking Equipment
            "B827EB": "Raspberry Pi Foundation",
            "DCA632": "Raspberry Pi Foundation",
            "E45F01": "Raspberry Pi Foundation",
            "F4F5E8": "Ubiquiti",
            "FC9FB6": "Ubiquiti",
            "80EA96": "Ubiquiti",
            "F0D1A9": "Cisco",
            "001E14": "Cisco",
            "0019E8": "Cisco",
            "D4E8B2": "Netgear",
            "A0040A": "Netgear",
            "10DA43": "TP-Link",
            "50C7BF": "TP-Link",
            
            // Printers
            "3C5A37": "Hewlett Packard",
            "A8667F": "Hewlett Packard",
            "00236C": "Canon",
            "002583": "Brother",
            "008004": "Epson",
            
            // Other
            "983B16": "Intel",
            "000C29": "VMware",
            "0050F2": "Microsoft",
            "00155D": "Microsoft",
            "18B169": "Synology",
            "001132": "Synology"
        ]
        return map[oui]
    }
}

