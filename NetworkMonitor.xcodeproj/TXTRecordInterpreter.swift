import Foundation

/// Interprets common TXT record keys found in Bonjour/mDNS service advertisements
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
    
    /// Categorizes a TXT record key
    static func category(forKey key: String) -> Category {
        let lowerKey = key.lowercased()
        
        // Identity
        if ["fn", "name", "dn", "displayname", "md", "model", "ty", "product", "note", "id", "uid", "deviceid", "am", "vn"].contains(lowerKey) {
            return .identity
        }
        
        // Version/Firmware
        if ["fw", "fwv", "version", "vs", "ver", "srcvers", "pv", "ov", "txtvers"].contains(lowerKey) {
            return .version
        }
        
        // Network/Security
        if ["acl", "pw", "dk", "et", "tp", "pk", "sh"].contains(lowerKey) {
            return .network
        }
        
        // Status
        if ["act", "sf", "flags", "ff", "c#", "s#"].contains(lowerKey) {
            return .status
        }
        
        // Capabilities
        if ["pdl", "color", "duplex", "scan", "fax", "copies", "papermax", "ch", "cn", "sr", "ss", "features", "ft", "ci"].contains(lowerKey) {
            return .capabilities
        }
        
        // Configuration
        if ["rp", "path", "u", "adminurl", "qtotal", "priority", "machine", "sys", "wg", "da"].contains(lowerKey) {
            return .configuration
        }
        
        return .other
    }
    
    /// Returns a human-readable description for a TXT record key
    static func humanReadableKey(_ key: String) -> String {
        let lowerKey = key.lowercased()
        
        // Common keys across services
        switch lowerKey {
        // Identity & Model
        case "fn": return "Friendly Name"
        case "md", "model": return "Model"
        case "ty": return "Device Type"
        case "note": return "Location/Note"
        case "product": return "Product Name"
        case "name": return "Name"
        case "dn": return "Display Name"
        case "id": return "Identifier"
        case "uid": return "Unique ID"
        
        // Version & Firmware
        case "fw": return "Firmware Version"
        case "fwv": return "Firmware Version"
        case "vs", "ver", "version": return "Version"
        case "srcvers": return "Source Version"
        
        // Network & Protocol
        case "txtvers": return "TXT Record Version"
        case "vv": return "Version"
        case "acl": return "Access Control Level"
        case "act": return "Activity Status"
        case "dk": return "Decryption Key"
        case "et": return "Encryption Type"
        case "pw": return "Password Required"
        case "sf": return "Status Flags"
        case "tp": return "Transport Protocol"
        
        // Printer-specific
        case "pdl": return "Page Description Languages"
        case "rp": return "Resource Path"
        case "qtotal": return "Queue Total"
        case "priority": return "Priority"
        case "adminurl": return "Admin URL"
        case "usb_mfg": return "USB Manufacturer"
        case "usb_mdl": return "USB Model"
        case "color": return "Color Support"
        case "duplex": return "Duplex Printing"
        case "scan": return "Scanning Capable"
        case "fax": return "Fax Capable"
        case "copies": return "Copies Support"
        case "papermax": return "Max Paper Size"
        
        // AirPlay/RAOP
        case "am": return "AirPlay Model"
        case "pk": return "Public Key"
        case "ch": return "Audio Channels"
        case "cn": return "Audio Codecs"
        case "da": return "Device Announce"
        case "et": return "Encryption Types"
        case "md": return "Model"
        case "pw": return "Password Protected"
        case "sr": return "Sample Rate"
        case "ss": return "Sample Size"
        case "tp": return "Transport"
        case "vn": return "Vendor"
        case "vs": return "Server Version"
        case "vv": return "AirPlay Version"
        case "ft": return "Features"
        case "sf": return "System Flags"
        case "flags": return "Feature Flags"
        case "deviceid": return "Device ID"
        case "features": return "Supported Features"
        case "model": return "Device Model"
        case "srcvers": return "Source Version"
        case "acl": return "Access Control"
        case "fv": return "Firmware Version"
        case "ov": return "OS Version"
        case "pi": return "Product ID"
        
        // HomeKit (HAP)
        case "c#": return "Configuration Number"
        case "ff": return "Feature Flags"
        case "ci": return "Category Identifier"
        case "s#": return "State Number"
        case "pv": return "Protocol Version"
        case "sh": return "Setup Hash"
        
        // SMB/File Sharing
        case "machine": return "Machine Type"
        case "sys": return "System"
        case "wg": return "Workgroup"
        
        // HTTP/Web Services
        case "path": return "URL Path"
        case "u": return "URL"
        case "txtvers": return "TXT Version"
        
        // Media/Streaming
        case "am": return "Apple Model"
        case "at": return "Audio Types"
        case "ek": return "Encryption Key"
        
        default:
            // Capitalize first letter of unknown keys
            return key.prefix(1).uppercased() + key.dropFirst()
        }
    }
    
    /// Returns a human-readable interpretation of the value
    static func interpretValue(forKey key: String, value: String) -> String {
        let lowerKey = key.lowercased()
        
        // Handle empty values
        if value.isEmpty {
            return "(empty)"
        }
        
        // Interpret boolean-like values
        if value == "0" || value.lowercased() == "false" || value.lowercased() == "no" {
            switch lowerKey {
            case "pw": return "No password required"
            case "color": return "Black & white only"
            case "duplex": return "Single-sided only"
            case "scan", "fax": return "Not supported"
            default: return value
            }
        }
        
        if value == "1" || value.lowercased() == "true" || value.lowercased() == "yes" {
            switch lowerKey {
            case "pw": return "Password required"
            case "color": return "Color printing supported"
            case "duplex": return "Duplex printing supported"
            case "scan": return "Scanning supported"
            case "fax": return "Fax supported"
            default: return value
            }
        }
        
        // Interpret specific keys
        switch lowerKey {
        case "act":
            // Activity status
            if value == "0" { return "Idle" }
            if value == "1" { return "Active" }
            if value == "2" { return "Processing" }
            return value
            
        case "acl":
            // Access control level
            if value == "0" { return "Public (no restrictions)" }
            if value == "1" { return "Password protected" }
            if value == "2" { return "Device pin required" }
            return value
            
        case "sf", "flags":
            // Status flags (often hex values)
            if let hexValue = Int(value.replacingOccurrences(of: "0x", with: ""), radix: 16) {
                var flags: [String] = []
                
                // Common flag interpretations (varies by service)
                if hexValue & 0x01 != 0 { flags.append("Ready") }
                if hexValue & 0x02 != 0 { flags.append("Supports Pairing") }
                if hexValue & 0x04 != 0 { flags.append("Configured") }
                if hexValue & 0x08 != 0 { flags.append("Supports Remote Access") }
                
                if flags.isEmpty {
                    return value
                } else {
                    return "\(value) (\(flags.joined(separator: ", ")))"
                }
            }
            return value
            
        case "ci":
            // HomeKit category identifier
            let categories: [String: String] = [
                "1": "Other",
                "2": "Bridge",
                "3": "Fan",
                "4": "Garage Door Opener",
                "5": "Lightbulb",
                "6": "Door Lock",
                "7": "Outlet",
                "8": "Switch",
                "9": "Thermostat",
                "10": "Sensor",
                "11": "Security System",
                "12": "Door",
                "13": "Window",
                "14": "Window Covering",
                "15": "Programmable Switch",
                "16": "Range Extender",
                "17": "IP Camera",
                "18": "Video Doorbell",
                "19": "Air Purifier",
                "20": "Heater",
                "21": "Air Conditioner",
                "22": "Humidifier",
                "23": "Dehumidifier",
                "28": "Sprinkler",
                "29": "Faucet",
                "30": "Shower System",
                "31": "Television",
                "32": "Target Remote",
                "33": "Router"
            ]
            return categories[value] ?? value
            
        case "et":
            // Encryption type
            let types: [String: String] = [
                "0": "No encryption",
                "1": "RSA (Legacy)",
                "2": "FairPlay",
                "3": "MFiSAP",
                "4": "FairPlay SAPv2.5"
            ]
            return types[value] ?? value
            
        case "tp":
            // Transport protocol
            if value == "UDP" { return "UDP (User Datagram Protocol)" }
            if value == "TCP" { return "TCP (Transmission Control Protocol)" }
            return value
            
        case "pdl":
            // Page description languages
            let languages = value.components(separatedBy: ",")
            let readable = languages.map { lang -> String in
                switch lang.trimmingCharacters(in: .whitespaces).uppercased() {
                case "POSTSCRIPT": return "PostScript"
                case "PCL": return "PCL (HP Printer Language)"
                case "PCLXL": return "PCL XL"
                case "PDF": return "PDF Direct"
                case "URF": return "URF (AirPrint)"
                case "PWG": return "PWG Raster"
                default: return lang
                }
            }
            return readable.joined(separator: ", ")
            
        case "papermax":
            // Paper size
            let sizes: [String: String] = [
                "letter": "Letter (8.5\" × 11\")",
                "legal": "Legal (8.5\" × 14\")",
                "a4": "A4 (210mm × 297mm)",
                "a3": "A3 (297mm × 420mm)",
                "tabloid": "Tabloid (11\" × 17\")",
                "ledger": "Ledger (17\" × 11\")"
            ]
            return sizes[value.lowercased()] ?? value
            
        default:
            return value
        }
    }
    
    /// Returns both the human-readable key and interpreted value
    static func interpret(key: String, value: String) -> (readableKey: String, interpretedValue: String) {
        return (humanReadableKey(key), interpretValue(forKey: key, value: value))
    }
}
