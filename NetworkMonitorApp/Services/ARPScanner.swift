class ARPScanner {
    func scanNetwork(completion: @escaping ([String: String]) -> Void) {
        // Execute system arp command
        let task = Process()
        task.launchPath = "/usr/sbin/arp"
        task.arguments = ["-a"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            let devices = parseARPOutput(output)
            completion(devices)
        }
    }
    
    private func parseARPOutput(_ output: String) -> [String: String] {
        var devices: [String: String] = [:]
        
        // Parse lines like: "? (192.168.1.5) at aa:bb:cc:dd:ee:ff on en0"
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            if let ipMatch = line.range(of: #"\(\d+\.\d+\.\d+\.\d+\)"#, options: .regularExpression),
               let macMatch = line.range(of: #"[0-9a-f]{1,2}(:[0-9a-f]{1,2}){5}"#, options: .regularExpression) {
                
                let ip = String(line[ipMatch]).trimmingCharacters(in: CharacterSet(charactersIn: "()"))
                let mac = String(line[macMatch])
                devices[ip] = mac
            }
        }
        
        return devices
    }
}

//
//  ARPScanner.swift
//  NetworkMonitor
//
//  Created by Nathan Ooley on 11/17/25.
//

