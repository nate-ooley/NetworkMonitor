import Foundation

/// Interprets TXT record key-value pairs from network services
struct TXTRecordInterpreter {
    
    enum Category: String, CaseIterable {
        case identity = "Identity"
        case capabilities = "Capabilities"
        case network = "Network & Security"
        case version = "Version & Firmware"
        case status = "Status"
        case configuration = "Configuration"
        case other = "Other"
    }
    
    struct Interpretation {
        let readableKey: String
        let interpretedValue: String
    }
    
    // MARK: - Category Classification
    
    static func category(forKey key: String) -> Category {
        let lowerKey = key.lowercased()
        
        // Identity
        if ["fn", "name", "dn", "md", "model", "product", "ty", "note", "id", "uid", "deviceid", "machine", "sys"].contains(lowerKey) {
            return .identity
        }
        
        // Capabilities
        if ["features", "ft", "pdl", "color", "duplex", "scan", "fax", "copies", "am", "vn", "ch", "cn", "sf", "flags", "ff"].contains(lowerKey) {
            return .capabilities
        }
        
        // Network & Security
        if ["acl", "pw", "dk", "et", "tp", "wg"].contains(lowerKey) {
            return .network
        }
        
        // Version & Firmware
        if ["fw", "fwv", "version", "vs", "ver", "srcvers", "txtvers", "pv"].contains(lowerKey) {
            return .version
        }
        
        // Status
        if ["act", "qtotal", "priority", "s#", "c#", "ci", "sh", "sr", "ss"].contains(lowerKey) {
            return .status
        }
        
        // Configuration
        if ["rp", "papermax", "adminurl", "path", "u"].contains(lowerKey) {
            return .configuration
        }
        
        return .other
    }
    
    // MARK: - Interpretation
    
    static func interpret(key: String, value: String) -> Interpretation {
        let readableKey = makeReadableKey(key)
        let interpretedValue = interpretValue(key: key, value: value)
        
        return Interpretation(readableKey: readableKey, interpretedValue: interpretedValue)
    }
    
    // MARK: - Private Helpers
    
    private static func makeReadableKey(_ key: String) -> String {
        let lowerKey = key.lowercased()
        
        switch lowerKey {
        // Identity
        case "fn": return "Friendly Name"
        case "name": return "Name"
        case "dn": return "Display Name"
        case "md": return "Model"
        case "model": return "Model"
        case "product": return "Product"
        case "ty": return "Type"
        case "note": return "Note"
        case "id": return "Identifier"
        case "uid": return "Unique ID"
        case "deviceid": return "Device ID"
        case "machine": return "Machine"
        case "sys": return "System"
        
        // Version/Firmware
        case "fw": return "Firmware"
        case "fwv": return "Firmware Version"
        case "version": return "Version"
        case "vs": return "Version"
        case "ver": return "Version"
        case "srcvers": return "Source Version"
        case "txtvers": return "TXT Record Version"
        case "pv": return "Protocol Version"
        
        // Network/Security
        case "acl": return "Access Control"
        case "pw": return "Password Required"
        case "dk": return "Device Key"
        case "et": return "Encryption Type"
        case "tp": return "Transport Protocol"
        case "wg": return "Workgroup"
        
        // Status
        case "act": return "Active"
        case "qtotal": return "Queue Total"
        case "priority": return "Priority"
        case "s#": return "State Number"
        case "c#": return "Configuration Number"
        case "ci": return "Category Identifier"
        case "sh": return "Status Hash"
        case "sr": return "Sample Rate"
        case "ss": return "Sample Size"
        
        // Capabilities
        case "sf": return "Status Flags"
        case "flags": return "Flags"
        case "ff": return "Feature Flags"
        case "features": return "Features"
        case "ft": return "Feature Flags"
        case "am": return "Audio Metadata"
        case "vn": return "Vendor Name"
        case "ch": return "Channels"
        case "cn": return "Channel Number"
        
        // Printer
        case "pdl": return "Page Description Languages"
        case "rp": return "Resource Path"
        case "color": return "Color Printing"
        case "duplex": return "Duplex Printing"
        case "copies": return "Copies"
        case "scan": return "Scanning Support"
        case "fax": return "Fax Support"
        case "papermax": return "Maximum Paper Size"
        case "adminurl": return "Admin URL"
        
        // Configuration
        case "path": return "Path"
        case "u": return "URL"
        
        default:
            // Convert camelCase or snake_case to Title Case
            return key.replacingOccurrences(of: "_", with: " ")
                .split(separator: " ")
                .map { $0.capitalized }
                .joined(separator: " ")
        }
    }
    
    private static func interpretValue(key: String, value: String) -> String {
        let lowerKey = key.lowercased()
        
        // Boolean interpretations
        if ["color", "duplex", "scan", "fax"].contains(lowerKey) {
            switch value {
            case "1", "T", "true", "yes": return "Supported"
            case "0", "F", "false", "no": return "Not Supported"
            default: return value
            }
        }
        
        // Active status
        if lowerKey == "act" {
            switch value {
            case "0": return "Idle"
            case "1": return "Active"
            default: return value
            }
        }
        
        // Password required
        if lowerKey == "pw" {
            switch value {
            case "1", "T", "true", "yes": return "Required"
            case "0", "F", "false", "no": return "Not Required"
            default: return value
            }
        }
        
        // PDL (Page Description Language) - split comma-separated values
        if lowerKey == "pdl" {
            let languages = value.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            return languages.map { pdl in
                // Clean up common MIME types
                pdl.replacingOccurrences(of: "application/", with: "")
                   .replacingOccurrences(of: "image/", with: "")
                   .uppercased()
            }.joined(separator: ", ")
        }
        
        // Paper sizes
        if lowerKey == "papermax" {
            return value.capitalized
        }
        
        // Feature flags (hex)
        if ["sf", "flags", "ff", "ft"].contains(lowerKey) {
            if let hexValue = UInt64(value, radix: 16) {
                return "0x\(String(hexValue, radix: 16, uppercase: true)) (\(hexValue))"
            }
        }
        
        // If value is empty, provide a placeholder
        if value.isEmpty {
            return "(not set)"
        }
        
        return value
    }
}
