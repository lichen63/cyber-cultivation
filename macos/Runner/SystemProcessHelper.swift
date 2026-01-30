import Foundation

/// Helper class to get system process information using shell commands
/// This is a native Swift replacement for the Dart system_process_helper.dart
/// to eliminate Dart↔Swift round-trips for menu bar popover data
class SystemProcessHelper {
    
    static let shared = SystemProcessHelper()
    
    private init() {}
    
    // MARK: - Process Data Types
    
    typealias ProcessInfo = [String: Any]
    typealias NetworkInfo = [String: String]
    
    // MARK: - CPU Processes
    
    /// Get top CPU consuming processes using the `ps` command
    func getTopCpuProcesses(limit: Int = 5) -> [ProcessInfo] {
        guard let output = runCommand("/bin/ps", arguments: ["-arcwwxo", "pid,pcpu,comm", "-r"]) else {
            return []
        }
        
        var processes: [ProcessInfo] = []
        let lines = output.components(separatedBy: "\n")
        
        // Skip header line
        for i in 1..<lines.count where processes.count < limit {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 3,
               let pid = Int(parts[0]),
               let cpu = Double(parts[1]) {
                let fullPath = parts[2...].joined(separator: " ")
                let name = extractProcessName(from: fullPath)
                processes.append([
                    "pid": pid,
                    "cpu": cpu,
                    "name": name
                ])
            }
        }
        
        return processes
    }
    
    // MARK: - RAM Processes
    
    /// Get top RAM consuming processes using the `ps` command
    /// Returns memory usage in bytes (rss - resident set size)
    func getTopRamProcesses(limit: Int = 5) -> [ProcessInfo] {
        guard let output = runCommand("/bin/ps", arguments: ["-arcwwxo", "pid,rss,comm", "-m"]) else {
            return []
        }
        
        var processes: [ProcessInfo] = []
        let lines = output.components(separatedBy: "\n")
        
        // Skip header line
        for i in 1..<lines.count where processes.count < limit {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 3,
               let pid = Int(parts[0]),
               let rssKb = Int(parts[1]) {
                let fullPath = parts[2...].joined(separator: " ")
                let name = extractProcessName(from: fullPath)
                // Store as bytes for consistent formatting
                processes.append([
                    "pid": pid,
                    "memory": rssKb * 1024,
                    "name": name
                ])
            }
        }
        
        return processes
    }
    
    // MARK: - Disk Processes
    
    /// Get top disk I/O processes using lsof
    func getTopDiskProcesses(limit: Int = 5) -> [ProcessInfo] {
        // Use lsof to get processes with open files
        guard let output = runCommand("/bin/sh", arguments: [
            "-c",
            "lsof -n 2>/dev/null | awk '$5==\"REG\" {print $2, $1}' | sort | uniq -c | sort -rn | head -\(limit * 2)"
        ]) else {
            return getTopDiskProcessesFallback(limit: limit)
        }
        
        var pidToData: [Int: ProcessInfo] = [:]
        var seenPids = Set<Int>()
        
        let lines = output.components(separatedBy: "\n")
        for line in lines where pidToData.count < limit {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 3,
               let count = Int(parts[0]),
               let pid = Int(parts[1]),
               count > 0,
               !seenPids.contains(pid) {
                let truncatedName = parts[2]
                if truncatedName == "COMMAND" || truncatedName == "PID" { continue }
                
                seenPids.insert(pid)
                pidToData[pid] = [
                    "pid": pid,
                    "name": truncatedName,
                    "bytesRead": count * 4096,  // Estimated read bytes
                    "bytesWritten": count * 2048  // Estimated write bytes
                ]
            }
        }
        
        // Get full process names
        if !pidToData.isEmpty {
            let pids = pidToData.keys.map { String($0) }.joined(separator: ",")
            if let psOutput = runCommand("/bin/ps", arguments: ["-o", "pid=,comm=", "-p", pids]) {
                for line in psOutput.components(separatedBy: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty { continue }
                    
                    if let match = trimmed.range(of: #"^\s*(\d+)\s+(.+)$"#, options: .regularExpression) {
                        let matchStr = String(trimmed[match])
                        let parts = matchStr.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                        if parts.count >= 2,
                           let pid = Int(parts[0]) {
                            let fullName = extractProcessName(from: parts[1...].joined(separator: " "))
                            if pidToData[pid] != nil && !fullName.isEmpty {
                                pidToData[pid]?["name"] = fullName
                            }
                        }
                    }
                }
            }
        }
        
        if pidToData.isEmpty {
            return getTopDiskProcessesFallback(limit: limit)
        }
        
        return Array(pidToData.values)
    }
    
    private func getTopDiskProcessesFallback(limit: Int) -> [ProcessInfo] {
        guard let output = runCommand("/bin/ps", arguments: ["-arcwwxo", "pid,rss,comm", "-m"]) else {
            return []
        }
        
        var processes: [ProcessInfo] = []
        let lines = output.components(separatedBy: "\n")
        
        for i in 1..<lines.count where processes.count < limit {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 3,
               let pid = Int(parts[0]),
               let rss = Int(parts[1]),
               rss > 10000 {  // Only show processes with >10MB memory
                let fullPath = parts[2...].joined(separator: " ")
                let name = extractProcessName(from: fullPath)
                processes.append([
                    "pid": pid,
                    "name": name,
                    "bytesRead": rss * 10,
                    "bytesWritten": rss * 5
                ])
            }
        }
        
        return processes
    }
    
    // MARK: - Network Processes
    
    /// Get top network consuming processes using nettop
    func getTopNetworkProcesses(limit: Int = 5) -> [ProcessInfo] {
        guard let output = runCommand("/usr/bin/nettop", arguments: ["-P", "-L", "1", "-J", "bytes_in,bytes_out"]) else {
            return []
        }
        
        var pidToData: [Int: ProcessInfo] = [:]
        let lines = output.components(separatedBy: "\n")
        
        // nettop output: process_name.pid, bytes_in, bytes_out
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            
            let parts = line.components(separatedBy: ",")
            if parts.count >= 3 {
                let processInfo = parts[0].trimmingCharacters(in: .whitespaces)
                let bytesIn = Int(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0
                let bytesOut = Int(parts[2].trimmingCharacters(in: .whitespaces)) ?? 0
                let totalBytes = bytesIn + bytesOut
                
                if totalBytes > 0 {
                    // Extract process name and pid (format: name.pid)
                    if let dotIndex = processInfo.lastIndex(of: ".") {
                        let truncatedName = String(processInfo[..<dotIndex])
                        let pidStr = String(processInfo[processInfo.index(after: dotIndex)...])
                        if let pid = Int(pidStr), pid > 0 {
                            pidToData[pid] = [
                                "pid": pid,
                                "name": truncatedName,
                                "download": bytesIn,
                                "upload": bytesOut
                            ]
                        }
                    }
                }
            }
        }
        
        // Get full process names
        if !pidToData.isEmpty {
            let pids = pidToData.keys.map { String($0) }.joined(separator: ",")
            if let psOutput = runCommand("/bin/ps", arguments: ["-o", "pid=,comm=", "-p", pids]) {
                for line in psOutput.components(separatedBy: "\n") {
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    if trimmed.isEmpty { continue }
                    
                    let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if parts.count >= 2,
                       let pid = Int(parts[0]) {
                        let fullName = extractProcessName(from: parts[1...].joined(separator: " "))
                        if pidToData[pid] != nil && !fullName.isEmpty {
                            pidToData[pid]?["name"] = fullName
                        }
                    }
                }
            }
        }
        
        // Sort by total bytes and return top results
        let sorted = pidToData.values.sorted { a, b in
            let totalA = (a["download"] as? Int ?? 0) + (a["upload"] as? Int ?? 0)
            let totalB = (b["download"] as? Int ?? 0) + (b["upload"] as? Int ?? 0)
            return totalA > totalB
        }
        
        return Array(sorted.prefix(limit))
    }
    
    // MARK: - GPU Processes
    
    /// Get GPU-intensive processes (approximated via CPU usage)
    func getTopGpuProcesses(limit: Int = 5) -> [ProcessInfo] {
        guard let output = runCommand("/bin/ps", arguments: ["-arcwwxo", "pid,pcpu,comm", "-r"]) else {
            return []
        }
        
        let gpuApps = [
            "WindowServer", "Safari", "Chrome", "Firefox", "Brave", "Arc",
            "Unity", "Unreal", "Blender", "Final Cut", "Motion", "Compressor",
            "DaVinci", "Premiere", "After Effects", "Photoshop", "Illustrator",
            "Sketch", "Figma", "Steam", "Parallels", "VMware", "VirtualBox",
            "qemu", "CyberCultivation"
        ]
        
        var processes: [ProcessInfo] = []
        let lines = output.components(separatedBy: "\n")
        
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 3,
               let pid = Int(parts[0]),
               let cpu = Double(parts[1]) {
                let fullPath = parts[2...].joined(separator: " ")
                let name = extractProcessName(from: fullPath)
                
                // Include if it's a known GPU app or has significant CPU usage
                let isGpuApp = gpuApps.contains { name.lowercased().contains($0.lowercased()) }
                if isGpuApp || cpu > 1.0 {
                    processes.append([
                        "pid": pid,
                        "gpu": cpu,
                        "name": name
                    ])
                    if processes.count >= limit { break }
                }
            }
        }
        
        return processes
    }
    
    // MARK: - Battery/Energy Processes
    
    /// Get top energy consuming processes using top command
    func getTopBatteryProcesses(limit: Int = 5) -> [ProcessInfo] {
        guard let output = runCommand("/bin/sh", arguments: [
            "-c",
            "top -l 2 -n \(limit + 5) -stats pid,cpu,command -o cpu | tail -\(limit + 3)"
        ]) else {
            return getTopBatteryProcessesFallback(limit: limit)
        }
        
        var processes: [ProcessInfo] = []
        let lines = output.components(separatedBy: "\n")
        
        for line in lines where processes.count < limit {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 3,
               let pid = Int(parts[0]),
               let cpu = Double(parts[1]),
               cpu > 0 {
                let name = extractProcessName(from: parts[2...].joined(separator: " "))
                processes.append([
                    "pid": pid,
                    "energy": cpu,
                    "name": name
                ])
            }
        }
        
        if processes.isEmpty {
            return getTopBatteryProcessesFallback(limit: limit)
        }
        
        return processes
    }
    
    private func getTopBatteryProcessesFallback(limit: Int) -> [ProcessInfo] {
        guard let output = runCommand("/bin/ps", arguments: ["-arcwwxo", "pid,pcpu,comm", "-r"]) else {
            return []
        }
        
        var processes: [ProcessInfo] = []
        let lines = output.components(separatedBy: "\n")
        
        for i in 1..<lines.count where processes.count < limit {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 3,
               let pid = Int(parts[0]),
               let cpu = Double(parts[1]),
               cpu > 0 {
                let fullPath = parts[2...].joined(separator: " ")
                let name = extractProcessName(from: fullPath)
                processes.append([
                    "pid": pid,
                    "energy": cpu,
                    "name": name
                ])
            }
        }
        
        return processes
    }
    
    // MARK: - Network Info
    
    /// Get basic network interface information
    func getNetworkInfo() -> NetworkInfo {
        var info: NetworkInfo = [
            "interfaceType": "-",
            "networkName": "-",
            "localIp": "-",
            "publicIp": "-",
            "macAddress": "-",
            "gateway": "-"
        ]
        
        // Get the primary network interface using route
        var activeInterface: String?
        var isVpnActive = false
        
        if let routeOutput = runCommand("/sbin/route", arguments: ["-n", "get", "default"]) {
            // Parse interface name
            if let interfaceMatch = routeOutput.range(of: #"interface:\s*(\S+)"#, options: .regularExpression) {
                let matchStr = String(routeOutput[interfaceMatch])
                let parts = matchStr.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count >= 2 {
                    activeInterface = parts[1]
                }
            }
            // Parse gateway
            if let gatewayMatch = routeOutput.range(of: #"gateway:\s*(\S+)"#, options: .regularExpression) {
                let matchStr = String(routeOutput[gatewayMatch])
                let parts = matchStr.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count >= 2 {
                    info["gateway"] = parts[1]
                }
            }
        }
        
        // Check if VPN interface and find physical interface
        if let iface = activeInterface, isVpnInterface(iface) {
            isVpnActive = true
            if let physicalInterface = findPhysicalInterface() {
                activeInterface = physicalInterface
                info["gateway"] = "-"
            }
        }
        
        // Get local IP and MAC address using ifconfig
        if let iface = activeInterface {
            if let ifconfigOutput = runCommand("/sbin/ifconfig", arguments: [iface]) {
                // Extract IPv4 address
                if let inetMatch = ifconfigOutput.range(of: #"inet\s+(\d+\.\d+\.\d+\.\d+)"#, options: .regularExpression) {
                    let matchStr = String(ifconfigOutput[inetMatch])
                    let parts = matchStr.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if parts.count >= 2 {
                        info["localIp"] = parts[1]
                    }
                }
                
                // Extract MAC address
                if let etherMatch = ifconfigOutput.range(of: #"(?:ether|lladdr)\s+([0-9a-fA-F:]+)"#, options: .regularExpression) {
                    let matchStr = String(ifconfigOutput[etherMatch])
                    let parts = matchStr.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if parts.count >= 2 {
                        info["macAddress"] = parts[1].uppercased()
                    }
                }
            }
            
            // Get gateway for physical interface when VPN is active
            if isVpnActive {
                if let gateway = getGatewayForInterface(iface) {
                    info["gateway"] = gateway
                }
            }
            
            // Determine interface type and get WiFi SSID
            var isWifi = false
            if iface.hasPrefix("en") {
                // Try system_profiler SPAirPortDataType
                if let profilerOutput = runCommand("/usr/sbin/system_profiler", arguments: ["SPAirPortDataType", "-json"]) {
                    if profilerOutput.contains("spairport_current_network_information") {
                        // Extract SSID
                        if let ssidRange = profilerOutput.range(of: #"spairport_current_network_information[^}]*"_name"\s*:\s*"([^"]+)""#, options: .regularExpression) {
                            isWifi = true
                            info["interfaceType"] = "WiFi"
                            let matchStr = String(profilerOutput[ssidRange])
                            if let nameStart = matchStr.range(of: "\"_name\" : \""),
                               let nameEnd = matchStr[nameStart.upperBound...].firstIndex(of: "\"") {
                                let ssid = String(matchStr[nameStart.upperBound..<nameEnd])
                                info["networkName"] = ssid == "<redacted>" || ssid.isEmpty ? "Connected" : ssid
                            }
                        }
                    }
                }
                
                // Fallback to networksetup
                if !isWifi {
                    if let wifiOutput = runCommand("/usr/sbin/networksetup", arguments: ["-getairportnetwork", iface]) {
                        if wifiOutput.contains("Current Wi-Fi Network:") || wifiOutput.contains("Current Airport Network:") {
                            isWifi = true
                            info["interfaceType"] = "WiFi"
                            let parts = wifiOutput.components(separatedBy: ":")
                            if parts.count >= 2 {
                                info["networkName"] = parts[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
                            }
                        }
                    }
                }
            }
            
            // If not WiFi, treat as Ethernet/VM network
            if !isWifi {
                if iface.hasPrefix("en") {
                    info["interfaceType"] = "Ethernet"
                } else if iface.hasPrefix("bridge") {
                    info["interfaceType"] = "Bridge"
                } else if iface.hasPrefix("vmnet") {
                    info["interfaceType"] = "VMware"
                } else if iface.hasPrefix("vnic") {
                    info["interfaceType"] = "Virtual"
                } else {
                    info["interfaceType"] = iface
                }
                info["networkName"] = iface
            }
        }
        
        // Get public IP address
        if let publicIpOutput = runCommand("/usr/bin/curl", arguments: ["-s", "-m", "2", "https://api.ipify.org"]) {
            let publicIp = publicIpOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            if publicIp.range(of: #"^\d+\.\d+\.\d+\.\d+$"#, options: .regularExpression) != nil {
                info["publicIp"] = publicIp
            }
        }
        
        return info
    }
    
    // MARK: - Helper Methods
    
    private func isVpnInterface(_ interfaceName: String) -> Bool {
        let vpnPrefixes = ["utun", "ipsec", "ppp", "tun", "tap", "gif", "stf"]
        let lowerName = interfaceName.lowercased()
        return vpnPrefixes.contains { lowerName.hasPrefix($0) }
    }
    
    private func findPhysicalInterface() -> String? {
        guard let output = runCommand("/usr/sbin/networksetup", arguments: ["-listnetworkserviceorder"]) else {
            return nil
        }
        
        // Parse interface names from output
        let pattern = #"\(Hardware Port:\s*[^,]+,\s*Device:\s*(\w+)\)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let matches = regex?.matches(in: output, options: [], range: NSRange(output.startIndex..., in: output)) ?? []
        
        for match in matches {
            if let deviceRange = Range(match.range(at: 1), in: output) {
                let device = String(output[deviceRange]).trimmingCharacters(in: .whitespaces)
                
                if device.isEmpty || isVpnInterface(device) { continue }
                
                if device.hasPrefix("en") {
                    if let ifconfigOutput = runCommand("/sbin/ifconfig", arguments: [device]) {
                        if ifconfigOutput.contains("inet ") && ifconfigOutput.contains("status: active") {
                            return device
                        }
                    }
                }
            }
        }
        
        // Fallback: scan en0-en9
        for i in 0...9 {
            let device = "en\(i)"
            if let ifconfigOutput = runCommand("/sbin/ifconfig", arguments: [device]) {
                if ifconfigOutput.contains("inet ") && ifconfigOutput.contains("status: active") {
                    return device
                }
            }
        }
        
        return nil
    }
    
    private func getGatewayForInterface(_ interfaceName: String) -> String? {
        guard let output = runCommand("/usr/sbin/networksetup", arguments: ["-listnetworkserviceorder"]) else {
            return nil
        }
        
        // Find service name for this interface
        let pattern = #"\((\d+)\)\s+([^\n]+)\n\(Hardware Port:[^,]+,\s*Device:\s*"# + NSRegularExpression.escapedPattern(for: interfaceName) + #"\)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: []),
           let match = regex.firstMatch(in: output, options: [], range: NSRange(output.startIndex..., in: output)),
           let serviceNameRange = Range(match.range(at: 2), in: output) {
            let serviceName = String(output[serviceNameRange]).trimmingCharacters(in: .whitespaces)
            
            // Get network info for this service
            if let infoOutput = runCommand("/usr/sbin/networksetup", arguments: ["-getinfo", serviceName]) {
                if let routerMatch = infoOutput.range(of: #"Router:\s*(\d+\.\d+\.\d+\.\d+)"#, options: .regularExpression) {
                    let matchStr = String(infoOutput[routerMatch])
                    let parts = matchStr.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
                    if parts.count >= 2 {
                        return parts[1]
                    }
                }
            }
        }
        
        return nil
    }
    
    private func extractProcessName(from path: String) -> String {
        if path.contains("/") {
            return path.components(separatedBy: "/").last ?? path
        }
        return path
    }
    
    private func runCommand(_ command: String, arguments: [String]) -> String? {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        task.executableURL = URL(fileURLWithPath: command)
        task.arguments = arguments
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
