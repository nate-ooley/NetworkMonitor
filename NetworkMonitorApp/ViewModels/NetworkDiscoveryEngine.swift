// Removed mock NetworkDiscoveryEngine that emitted simulated devices.
// A real implementation (Bonjour + ping-sweep/ARP discovery) lives in
// Services/NetworkDiscoveryEngine.swift, but the Services folder is not
// currently a member of the NetworkMonitor target; live discovery in the
// built app is provided by DeviceDiscoveryService.swift instead.
