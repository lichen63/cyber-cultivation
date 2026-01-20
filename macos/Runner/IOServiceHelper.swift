import Foundation
import IOKit

/// Helper utilities for fetching IOService information
final class IOServiceHelper {
  /// Shared singleton instance
  static let shared = IOServiceHelper()
  
  private init() {}
  
  /// Fetches IOService entries matching the given service name
  /// - Parameter name: The IOService class name to match (e.g., kIOAcceleratorClassName)
  /// - Returns: An array of property dictionaries for matching services, or nil if none found
  func fetchIOService(_ name: String) -> [NSDictionary]? {
    var iterator: io_iterator_t = 0
    var masterPort: mach_port_t = 0
    
    if #available(macOS 12.0, *) {
      masterPort = kIOMainPortDefault
    } else {
      masterPort = kIOMasterPortDefault
    }
    
    let result = IOServiceGetMatchingServices(masterPort, IOServiceMatching(name), &iterator)
    
    guard result == KERN_SUCCESS else { return nil }
    defer { IOObjectRelease(iterator) }
    
    var list: [NSDictionary] = []
    var service = IOIteratorNext(iterator)
    
    while service != 0 {
      if let props = getIOProperties(service) {
        list.append(props)
      }
      IOObjectRelease(service)
      service = IOIteratorNext(iterator)
    }
    
    return list.isEmpty ? nil : list
  }
  
  /// Gets the properties dictionary for an IORegistry entry
  /// - Parameter entry: The IORegistry entry to query
  /// - Returns: The properties dictionary, or nil if retrieval failed
  func getIOProperties(_ entry: io_registry_entry_t) -> NSDictionary? {
    var properties: Unmanaged<CFMutableDictionary>?
    let result = IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0)
    
    guard result == KERN_SUCCESS, let props = properties else { return nil }
    return props.takeRetainedValue() as NSDictionary
  }
}
