import Cocoa
import FlutterMacOS
import QuartzCore

class MainFlutterWindow: NSWindow {
  private var layerObserver: NSKeyValueObservation?
  
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let keyEventChannel = FlutterEventChannel(name: "com.lichen63.cyber_cultivation/key_events", binaryMessenger: flutterViewController.engine.binaryMessenger)
    keyEventChannel.setStreamHandler(KeyMonitorStreamHandler())

    super.awakeFromNib()
    
    // Configure window for transparency
    self.isOpaque = false
    self.backgroundColor = .clear
    self.hasShadow = false
    
    // Configure the content view
    if let contentView = self.contentView {
      contentView.wantsLayer = true
      contentView.layer?.backgroundColor = .clear
      contentView.layer?.isOpaque = false
    }
    
    // Configure Flutter view
    let flutterView = flutterViewController.view
    flutterView.wantsLayer = true
    
    // Set up delayed checks to catch the Metal layer after it's created
    // Multiple attempts ensure we catch the layer even if creation timing varies
    let delays: [TimeInterval] = [0.05, 0.1, 0.2]
    delays.forEach { delay in
      DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
        self?.configureTransparency(for: flutterView)
      }
    }
  }
  
  private func configureTransparency(for view: NSView) {
    guard let layer = view.layer else { return }
    
    // Configure the main layer
    layer.backgroundColor = .clear
    layer.isOpaque = false
    
    // Recursively configure all sublayers (including Metal layers)
    configureSublayers(layer)
  }
  
  private func configureSublayers(_ layer: CALayer) {
    layer.backgroundColor = .clear
    layer.isOpaque = false
    
    // Special handling for Metal layers
    if let metalLayer = layer as? CAMetalLayer {
      metalLayer.isOpaque = false
      metalLayer.backgroundColor = .clear
      metalLayer.framebufferOnly = false
    }
    
    // Process all sublayers recursively
    layer.sublayers?.forEach { configureSublayers($0) }
  }
}

class KeyMonitorStreamHandler: NSObject, FlutterStreamHandler {
    private var globalMonitor: Any?
    private var localMonitor: Any?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        // Global monitor (background)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if let formatted = self.formatEvent(event) {
                events(formatted)
            }
        }
        
        // Local monitor (foreground)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            if let formatted = self.formatEvent(event) {
                events(formatted)
            }
            return event // Propagate event
        }
        
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        return nil
    }
    
    private func formatEvent(_ event: NSEvent) -> String? {
        var parts: [String] = []
        let flags = event.modifierFlags
        
        if flags.contains(.command) { parts.append("Cmd") }
        if flags.contains(.control) { parts.append("Ctrl") }
        if flags.contains(.option) { parts.append("Opt") }
        if flags.contains(.shift) { parts.append("Shift") }
        
        if event.type == .keyDown {
            if let chars = event.charactersIgnoringModifiers?.uppercased(), !chars.isEmpty {
                 let keyCode = event.keyCode
                 switch keyCode {
                 case 36: parts.append("Enter")
                 case 48: parts.append("Tab")
                 case 49: parts.append("Space")
                 case 51: parts.append("Backspace")
                 case 53: parts.append("Esc")
                 case 123: parts.append("←")
                 case 124: parts.append("→")
                 case 125: parts.append("↓")
                 case 126: parts.append("↑")
                 default: parts.append(chars)
                 }
            }
        }
        
        if parts.isEmpty {
            return nil
        }
        return parts.joined(separator: " + ")
    }
}
