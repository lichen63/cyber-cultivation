import Cocoa
import IOKit
import IOKit.ps

class SystemInfoHandler {
  private var previousCpuInfo: host_cpu_load_info?
  private var previousNetworkBytes: (upload: UInt64, download: UInt64)?
  private var previousNetworkTime: Date?
  private var lastNetworkUploadSpeed: Int = 0
  private var lastNetworkDownloadSpeed: Int = 0
  
  func getCpuUsage() -> Double {
    let cpuInfo = hostCPULoadInfo()
    guard let current = cpuInfo else { return 0.0 }
    
    var usage: Double = 0.0
    
    if let previous = previousCpuInfo {
      let userDiff = Double(current.cpu_ticks.0 - previous.cpu_ticks.0)
      let systemDiff = Double(current.cpu_ticks.1 - previous.cpu_ticks.1)
      let idleDiff = Double(current.cpu_ticks.2 - previous.cpu_ticks.2)
      let niceDiff = Double(current.cpu_ticks.3 - previous.cpu_ticks.3)
      
      let totalTicks = userDiff + systemDiff + idleDiff + niceDiff
      if totalTicks > 0 {
        usage = ((userDiff + systemDiff + niceDiff) / totalTicks) * 100.0
      }
    }
    
    previousCpuInfo = current
    return usage
  }
  
  private func hostCPULoadInfo() -> host_cpu_load_info? {
    let count = MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride
    var size = mach_msg_type_number_t(count)
    var cpuLoadInfo = host_cpu_load_info()
    
    let result: kern_return_t = withUnsafeMutablePointer(to: &cpuLoadInfo) {
      $0.withMemoryRebound(to: integer_t.self, capacity: count) {
        host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
      }
    }
    
    if result != KERN_SUCCESS {
      return nil
    }
    return cpuLoadInfo
  }
  
  func getGpuUsage() -> Double {
    guard let accelerators = IOServiceHelper.shared.fetchIOService(kIOAcceleratorClassName) else {
      return 0.0
    }
    
    for accelerator in accelerators {
      if let stats = accelerator["PerformanceStatistics"] as? [String: Any] {
        // Try different keys that different GPU types use
        if let utilization = stats["Device Utilization %"] as? Int {
          return Double(min(utilization, 100))
        }
        if let utilization = stats["GPU Activity(%)"] as? Int {
          return Double(min(utilization, 100))
        }
        // For Apple Silicon GPUs
        if let utilization = stats["Renderer Utilization %"] as? Int {
          return Double(min(utilization, 100))
        }
      }
    }
    
    return 0.0
  }
  
  func getRamUsage() -> Double {
    var stats = vm_statistics64()
    var count = UInt32(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
    
    let result: kern_return_t = withUnsafeMutablePointer(to: &stats) {
      $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
        host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
      }
    }
    
    if result != KERN_SUCCESS {
      return 0.0
    }
    
    let pageSize = Double(vm_page_size)
    let active = Double(stats.active_count) * pageSize
    let wired = Double(stats.wire_count) * pageSize
    let compressed = Double(stats.compressor_page_count) * pageSize
    
    // Get total memory
    var hostInfo = host_basic_info()
    var hostCount = UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
    
    let hostResult: kern_return_t = withUnsafeMutablePointer(to: &hostInfo) {
      $0.withMemoryRebound(to: integer_t.self, capacity: Int(hostCount)) {
        host_info(mach_host_self(), HOST_BASIC_INFO, $0, &hostCount)
      }
    }
    
    if hostResult != KERN_SUCCESS {
      return 0.0
    }
    
    let totalMemory = Double(hostInfo.max_mem)
    let usedMemory = active + wired + compressed
    
    return (usedMemory / totalMemory) * 100.0
  }
  
  func getDiskUsage() -> Double {
    let fileURL = URL(fileURLWithPath: "/")
    
    do {
      let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
      
      if let totalCapacity = values.volumeTotalCapacity,
         let availableCapacity = values.volumeAvailableCapacity {
        let usedCapacity = totalCapacity - availableCapacity
        return (Double(usedCapacity) / Double(totalCapacity)) * 100.0
      }
    } catch {
      return 0.0
    }
    
    return 0.0
  }
  
  func getNetworkUpload() -> Int {
    updateNetworkStats()
    return lastNetworkUploadSpeed
  }
  
  func getNetworkDownload() -> Int {
    updateNetworkStats()
    return lastNetworkDownloadSpeed
  }
  
  private func updateNetworkStats() {
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
    defer { freeifaddrs(ifaddr) }
    
    var totalUpload: UInt64 = 0
    var totalDownload: UInt64 = 0
    
    var ptr = firstAddr
    while true {
      let interface = ptr.pointee
      let name = String(cString: interface.ifa_name)
      
      // Only count physical interfaces (en0, en1, etc.)
      if name.hasPrefix("en") || name.hasPrefix("utun") || name.hasPrefix("pdp_ip") {
        if let data = interface.ifa_data {
          let networkData = data.assumingMemoryBound(to: if_data.self).pointee
          totalUpload += UInt64(networkData.ifi_obytes)
          totalDownload += UInt64(networkData.ifi_ibytes)
        }
      }
      
      if let next = interface.ifa_next {
        ptr = next
      } else {
        break
      }
    }
    
    let now = Date()
    
    if let previousBytes = previousNetworkBytes, let previousTime = previousNetworkTime {
      let timeDiff = now.timeIntervalSince(previousTime)
      if timeDiff > 0 {
        let uploadDiff = totalUpload >= previousBytes.upload ? totalUpload - previousBytes.upload : 0
        let downloadDiff = totalDownload >= previousBytes.download ? totalDownload - previousBytes.download : 0
        
        lastNetworkUploadSpeed = Int(Double(uploadDiff) / timeDiff)
        lastNetworkDownloadSpeed = Int(Double(downloadDiff) / timeDiff)
        
        previousNetworkBytes = (totalUpload, totalDownload)
        previousNetworkTime = now
      }
    } else {
      previousNetworkBytes = (totalUpload, totalDownload)
      previousNetworkTime = now
    }
  }
  
  func getAllStats() -> [String: Any] {
    // Update network stats once before getting all stats
    updateNetworkStats()
    
    // Get battery info
    let batteryInfo = getBatteryInfo()
    
    return [
      "cpu": getCpuUsage(),
      "gpu": getGpuUsage(),
      "ram": getRamUsage(),
      "disk": getDiskUsage(),
      "networkUp": lastNetworkUploadSpeed,
      "networkDown": lastNetworkDownloadSpeed,
      "batteryLevel": batteryInfo.level,
      "isBatteryCharging": batteryInfo.isCharging
    ]
  }
  
  /// Get top CPU consuming processes
  /// Returns an array of dictionaries with process info: name, pid, cpu
  func getTopCpuProcesses(limit: Int = 5) -> [[String: Any]] {
    let pipe = Pipe()
    let process = Foundation.Process()
    process.executableURL = URL(fileURLWithPath: "/bin/ps")
    process.arguments = ["-arcwwxo", "pid,pcpu,comm", "-r"]
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    
    do {
      try process.run()
      process.waitUntilExit()
      
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      guard let output = String(data: data, encoding: .utf8) else {
        return []
      }
      
      var processes: [[String: Any]] = []
      let lines = output.components(separatedBy: "\n")
      
      // Skip header line
      for (index, line) in lines.enumerated() {
        if index == 0 { continue } // Skip header
        if processes.count >= limit { break }
        
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { continue }
        
        // Parse: PID %CPU COMMAND
        let components = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        if components.count >= 3 {
          if let pid = Int(components[0]),
             let cpu = Double(components[1]) {
            let name = String(components[2])
            // Extract just the app name from path
            let appName = (name as NSString).lastPathComponent
            processes.append([
              "pid": pid,
              "cpu": cpu,
              "name": appName
            ])
          }
        }
      }
      
      return processes
    } catch {
      return []
    }
  }
  
  /// Get battery level and charging status
  /// Returns (level: Int, isOnPower: Bool) where level is -1 if no battery
  /// isOnPower is true when connected to AC power (shows charging icon even at 100%)
  func getBatteryInfo() -> (level: Int, isCharging: Bool) {
    guard let powerSourceInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let powerSources = IOPSCopyPowerSourcesList(powerSourceInfo)?.takeRetainedValue() as? [CFTypeRef],
          !powerSources.isEmpty else {
      // No battery (desktop Mac or error)
      return (-1, false)
    }
    
    for source in powerSources {
      if let description = IOPSGetPowerSourceDescription(powerSourceInfo, source)?.takeUnretainedValue() as? [String: Any] {
        // Check if this is a battery
        if let type = description[kIOPSTypeKey] as? String,
           type == kIOPSInternalBatteryType {
          let currentCapacity = description[kIOPSCurrentCapacityKey] as? Int ?? 0
          let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 100
          
          // Check if on AC power (not just actively charging)
          // kIOPSPowerSourceStateKey is "AC Power" when plugged in, "Battery Power" when unplugged
          let powerSource = description[kIOPSPowerSourceStateKey] as? String ?? ""
          let isOnPower = powerSource == kIOPSACPowerValue
          
          // Calculate percentage
          let level = maxCapacity > 0 ? (currentCapacity * 100) / maxCapacity : 0
          return (level, isOnPower)
        }
      }
    }
    
    return (-1, false)
  }
}
