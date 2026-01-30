import SwiftUI
import Cocoa

/// A SwiftUI-based popover view controller for menu bar popups.
/// This provides native macOS popover behavior with better performance
/// than creating separate Flutter windows.
class MenuBarPopoverViewController: NSViewController {
    
    private var hostingView: NSHostingView<AnyView>?
    private var currentItemId: String = ""
    private var currentData: [String: Any] = [:]
    private var isDarkMode: Bool = true
    private var onShowWindow: (() -> Void)?
    private var onHideWindow: (() -> Void)?
    private var onExitApp: (() -> Void)?
    private var onActivityMonitorTap: (() -> Void)?
    
    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }
    
    func configure(
        itemId: String,
        data: [String: Any],
        isDarkMode: Bool,
        onShowWindow: @escaping () -> Void,
        onHideWindow: @escaping () -> Void,
        onExitApp: @escaping () -> Void,
        onActivityMonitorTap: @escaping () -> Void
    ) {
        self.currentItemId = itemId
        self.currentData = data
        self.isDarkMode = isDarkMode
        self.onShowWindow = onShowWindow
        self.onHideWindow = onHideWindow
        self.onExitApp = onExitApp
        self.onActivityMonitorTap = onActivityMonitorTap
        
        updateContent()
    }
    
    func updateData(_ data: [String: Any]) {
        self.currentData = data
        if let itemId = data["itemId"] as? String {
            self.currentItemId = itemId
        }
        updateContent()
    }
    
    private func updateContent() {
        let contentView = buildContentView()
        
        if hostingView == nil {
            hostingView = NSHostingView(rootView: AnyView(contentView))
            hostingView!.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(hostingView!)
            
            NSLayoutConstraint.activate([
                hostingView!.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                hostingView!.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                hostingView!.topAnchor.constraint(equalTo: view.topAnchor),
                hostingView!.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        } else {
            hostingView!.rootView = AnyView(contentView)
        }
        
        // Update preferred content size based on item type
        let size = getPopoverSize(for: currentItemId)
        preferredContentSize = size
    }
    
    private func getPopoverSize(for itemId: String) -> NSSize {
        switch itemId {
        case "network":
            return NSSize(width: 490, height: 280)
        case "disk":
            return NSSize(width: 490, height: 210)
        case "cpu", "gpu", "ram", "battery":
            return NSSize(width: 430, height: 210)
        case "todo":
            return NSSize(width: 340, height: 210)
        case "levelExp", "focus", "keyboard", "mouse":
            return NSSize(width: 340, height: 156)
        default:
            return NSSize(width: 340, height: 136)
        }
    }
    
    @ViewBuilder
    private func buildContentView() -> some View {
        PopoverContentView(
            itemId: currentItemId,
            data: currentData,
            isDarkMode: isDarkMode,
            onShowWindow: { [weak self] in self?.onShowWindow?() },
            onHideWindow: { [weak self] in self?.onHideWindow?() },
            onExitApp: { [weak self] in self?.onExitApp?() },
            onActivityMonitorTap: { [weak self] in self?.onActivityMonitorTap?() }
        )
    }
}

/// SwiftUI view that renders the popover content
struct PopoverContentView: View {
    let itemId: String
    let data: [String: Any]
    let isDarkMode: Bool
    let onShowWindow: () -> Void
    let onHideWindow: () -> Void
    let onExitApp: () -> Void
    let onActivityMonitorTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            titleBar
            
            Divider()
                .opacity(0.3)
            
            // Content area
            contentArea
        }
        .background(isDarkMode ? Color(white: 0.15) : Color(white: 0.97))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isDarkMode ? Color(white: 0.3) : Color(white: 0.75), lineWidth: 1)
        )
    }
    
    private var titleBar: some View {
        ZStack {
            // Center: Title (in ZStack for true centering)
            Text(getTitle())
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isDarkMode ? Color.white : Color.black)
            
            // Left and Right buttons
            HStack {
                // Left: Show/Hide buttons
                HStack(spacing: 4) {
                    IconButton(
                        icon: "eye",
                        tooltip: "Show Window",
                        isDarkMode: isDarkMode,
                        action: onShowWindow
                    )
                    IconButton(
                        icon: "eye.slash",
                        tooltip: "Hide Window",
                        isDarkMode: isDarkMode,
                        action: onHideWindow
                    )
                }
                
                Spacer()
                
                // Right: Exit button
                IconButton(
                    icon: "power",
                    tooltip: "Exit App",
                    isDestructive: true,
                    isDarkMode: isDarkMode,
                    action: onExitApp
                )
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 28)
    }
    
    private func getTitle() -> String {
        switch itemId {
        case "focus":
            return data["locale"] as? String == "zh" ? "专注" : "Focus"
        case "cpu":
            return "CPU"
        case "ram":
            return data["locale"] as? String == "zh" ? "内存" : "RAM"
        case "network":
            return data["locale"] as? String == "zh" ? "网络" : "Network"
        case "gpu":
            return "GPU"
        case "disk":
            return data["locale"] as? String == "zh" ? "磁盘" : "Disk"
        case "battery":
            return data["locale"] as? String == "zh" ? "电池" : "Battery"
        case "todo":
            return data["locale"] as? String == "zh" ? "待办" : "Todo"
        case "levelExp":
            return data["locale"] as? String == "zh" ? "等级" : "Level"
        case "keyboard":
            return data["locale"] as? String == "zh" ? "键盘" : "Keyboard"
        case "mouse":
            return data["locale"] as? String == "zh" ? "鼠标" : "Mouse"
        default:
            return itemId.isEmpty ? "Menu" : itemId.capitalized
        }
    }
    
    @ViewBuilder
    private var contentArea: some View {
        switch itemId {
        case "focus":
            FocusContentView(data: data, isDarkMode: isDarkMode)
        case "cpu", "gpu", "ram", "battery":
            ProcessListView(
                itemId: itemId,
                processes: data["processes"] as? [[String: Any]] ?? [],
                isLoading: data["isLoading"] as? Bool ?? false,
                isDarkMode: isDarkMode,
                onTap: onActivityMonitorTap
            )
        case "disk":
            DiskProcessListView(
                processes: data["processes"] as? [[String: Any]] ?? [],
                isLoading: data["isLoading"] as? Bool ?? false,
                isDarkMode: isDarkMode,
                onTap: onActivityMonitorTap
            )
        case "network":
            NetworkContentView(
                data: data,
                isDarkMode: isDarkMode,
                onTap: onActivityMonitorTap
            )
        case "todo":
            TodoContentView(todos: data["todos"] as? [[String: Any]] ?? [], isDarkMode: isDarkMode)
        case "levelExp":
            LevelExpContentView(data: data, isDarkMode: isDarkMode)
        case "keyboard":
            KeyboardContentView(keyCount: data["keyCount"] as? Int ?? 0, isDarkMode: isDarkMode)
        case "mouse":
            MouseContentView(distance: data["distance"] as? Int ?? 0, isDarkMode: isDarkMode)
        default:
            Text("Content placeholder")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    let tooltip: String
    var isDestructive: Bool = false
    var isDarkMode: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    private var normalColor: Color {
        isDarkMode ? Color(white: 0.6) : Color(white: 0.4)
    }
    
    private var hoverColor: Color {
        isDarkMode ? Color.white : Color.black
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(isDestructive ? .red : (isHovered ? hoverColor : normalColor))
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Focus Content

struct FocusContentView: View {
    let data: [String: Any]
    let isDarkMode: Bool
    
    private var isActive: Bool { data["focusIsActive"] as? Bool ?? false }
    private var isRelaxing: Bool { data["focusIsRelaxing"] as? Bool ?? false }
    private var secondsRemaining: Int { data["focusSecondsRemaining"] as? Int ?? 0 }
    private var currentLoop: Int { data["focusCurrentLoop"] as? Int ?? 1 }
    private var totalLoops: Int { data["focusTotalLoops"] as? Int ?? 1 }
    private var locale: String { data["locale"] as? String ?? "en" }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            InfoRow(
                label: locale == "zh" ? "状态" : "Status",
                value: stateLabel,
                isDarkMode: isDarkMode
            )
            InfoRow(
                label: locale == "zh" ? "剩余时间" : "Time Remaining",
                value: timeString,
                isDarkMode: isDarkMode
            )
            InfoRow(
                label: locale == "zh" ? "循环" : "Loops",
                value: "\(currentLoop)/\(totalLoops)",
                isDarkMode: isDarkMode
            )
        }
        .padding(8)
    }
    
    private var stateLabel: String {
        if !isActive {
            return locale == "zh" ? "空闲" : "Idle"
        } else if isRelaxing {
            return locale == "zh" ? "休息中" : "Relaxing"
        }
        return locale == "zh" ? "专注中" : "Focusing"
    }
    
    private var timeString: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Process List Content

struct ProcessListView: View {
    let itemId: String
    let processes: [[String: Any]]
    let isLoading: Bool
    let isDarkMode: Bool
    let onTap: () -> Void
    
    private var primaryTextColor: Color {
        isDarkMode ? Color.white : Color.black
    }
    
    private var secondaryTextColor: Color {
        isDarkMode ? Color(white: 0.6) : Color(white: 0.4)
    }
    
    var body: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(0.7)
                .frame(maxWidth: .infinity, minHeight: 80)
        } else if processes.isEmpty {
            Text("No processes found")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, minHeight: 80)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                // Header
                HStack {
                    Text("Process")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("PID")
                        .frame(width: 50, alignment: .trailing)
                    Text("Usage")
                        .frame(width: 70, alignment: .trailing)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(secondaryTextColor)
                
                Divider()
                    .opacity(0.5)
                
                // Process rows
                ForEach(Array(processes.enumerated()), id: \.offset) { _, process in
                    ProcessRow(process: process, itemId: itemId, isDarkMode: isDarkMode, onTap: onTap)
                }
            }
            .padding(8)
        }
    }
}

struct ProcessRow: View {
    let process: [String: Any]
    let itemId: String
    let isDarkMode: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    private var name: String { process["name"] as? String ?? "Unknown" }
    private var pid: Int { process["pid"] as? Int ?? 0 }
    private var usage: String {
        switch itemId {
        case "cpu":
            let cpu = process["cpu"] as? Double ?? 0
            return String(format: "%.1f%%", cpu)
        case "gpu":
            let gpu = process["gpu"] as? Double ?? 0
            return String(format: "%.1f%%", gpu)
        case "ram":
            let ram = process["memory"] as? Int ?? 0
            return formatMemory(ram)
        case "battery":
            let energy = process["energy"] as? Double ?? 0
            return String(format: "%.1f", energy)
        default:
            return "-"
        }
    }
    
    private var textColor: Color {
        let baseColor = isDarkMode ? Color.white : Color.black
        return isHovered ? baseColor : baseColor.opacity(0.9)
    }
    
    private var hoverBackground: Color {
        isDarkMode ? Color.white.opacity(0.1) : Color.gray.opacity(0.1)
    }
    
    var body: some View {
        HStack {
            Text(name)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(pid > 0 ? "\(pid)" : "-")
                .frame(width: 50, alignment: .trailing)
            Text(usage)
                .frame(width: 70, alignment: .trailing)
        }
        .font(.system(size: 12))
        .foregroundColor(textColor)
        .padding(.vertical, 2)
        .background(isHovered ? hoverBackground : Color.clear)
        .cornerRadius(4)
        .onHover { hovering in isHovered = hovering }
        .onTapGesture { onTap() }
    }
    
    private func formatMemory(_ bytes: Int) -> String {
        if bytes >= 1024 * 1024 * 1024 {
            return String(format: "%.1f GB", Double(bytes) / (1024 * 1024 * 1024))
        } else if bytes >= 1024 * 1024 {
            return String(format: "%.0f MB", Double(bytes) / (1024 * 1024))
        } else if bytes >= 1024 {
            return String(format: "%.0f KB", Double(bytes) / 1024)
        }
        return "\(bytes) B"
    }
}

// MARK: - Disk Process List

struct DiskProcessListView: View {
    let processes: [[String: Any]]
    let isLoading: Bool
    let isDarkMode: Bool
    let onTap: () -> Void
    
    private var secondaryTextColor: Color {
        isDarkMode ? Color(white: 0.6) : Color(white: 0.4)
    }
    
    var body: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(0.7)
                .frame(maxWidth: .infinity, minHeight: 80)
        } else if processes.isEmpty {
            Text("No disk activity")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, minHeight: 80)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                // Header
                HStack {
                    Text("Process")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("PID")
                        .frame(width: 50, alignment: .trailing)
                    Text("Read")
                        .frame(width: 70, alignment: .trailing)
                    Text("Write")
                        .frame(width: 70, alignment: .trailing)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(secondaryTextColor)
                
                Divider()
                    .opacity(0.5)
                
                // Process rows
                ForEach(Array(processes.enumerated()), id: \.offset) { _, process in
                    DiskProcessRow(process: process, isDarkMode: isDarkMode, onTap: onTap)
                }
            }
            .padding(8)
        }
    }
}

struct DiskProcessRow: View {
    let process: [String: Any]
    let isDarkMode: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    private var name: String { process["name"] as? String ?? "Unknown" }
    private var pid: Int { process["pid"] as? Int ?? 0 }
    private var readBytes: Int { process["bytesRead"] as? Int ?? 0 }
    private var writeBytes: Int { process["bytesWritten"] as? Int ?? 0 }
    
    private var textColor: Color {
        let baseColor = isDarkMode ? Color.white : Color.black
        return isHovered ? baseColor : baseColor.opacity(0.9)
    }
    
    private var hoverBackground: Color {
        isDarkMode ? Color.white.opacity(0.1) : Color.gray.opacity(0.1)
    }
    
    var body: some View {
        HStack {
            Text(name)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(pid > 0 ? "\(pid)" : "-")
                .frame(width: 50, alignment: .trailing)
            Text(formatBytes(readBytes))
                .frame(width: 70, alignment: .trailing)
            Text(formatBytes(writeBytes))
                .frame(width: 70, alignment: .trailing)
        }
        .font(.system(size: 12))
        .foregroundColor(textColor)
        .padding(.vertical, 2)
        .background(isHovered ? hoverBackground : Color.clear)
        .cornerRadius(4)
        .onHover { hovering in isHovered = hovering }
        .onTapGesture { onTap() }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        if bytes >= 1024 * 1024 * 1024 {
            return String(format: "%.1fG", Double(bytes) / (1024 * 1024 * 1024))
        } else if bytes >= 1024 * 1024 {
            return String(format: "%.1fM", Double(bytes) / (1024 * 1024))
        } else if bytes >= 1024 {
            return String(format: "%.1fK", Double(bytes) / 1024)
        }
        return "\(bytes)B"
    }
}

// MARK: - Network Content

struct NetworkContentView: View {
    let data: [String: Any]
    let isDarkMode: Bool
    let onTap: () -> Void
    
    private var networkInfo: [String: String] {
        data["networkInfo"] as? [String: String] ?? [:]
    }
    private var processes: [[String: Any]] {
        data["processes"] as? [[String: Any]] ?? []
    }
    private var isLoading: Bool {
        data["isLoading"] as? Bool ?? false
    }
    private var locale: String {
        data["locale"] as? String ?? "en"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Network info section
            VStack(alignment: .leading, spacing: 2) {
                NetworkInfoRow(
                    label: locale == "zh" ? "接口" : "Interface",
                    value: networkInfo["interfaceType"] ?? "-",
                    isDarkMode: isDarkMode
                )
                NetworkInfoRow(
                    label: locale == "zh" ? "网络名称" : "Network",
                    value: networkInfo["networkName"] ?? "-",
                    isDarkMode: isDarkMode
                )
                NetworkInfoRow(
                    label: locale == "zh" ? "本地 IP" : "Local IP",
                    value: networkInfo["localIp"] ?? "-",
                    isDarkMode: isDarkMode
                )
                NetworkInfoRow(
                    label: locale == "zh" ? "公网 IP" : "Public IP",
                    value: networkInfo["publicIp"] ?? "-",
                    isDarkMode: isDarkMode
                )
                NetworkInfoRow(
                    label: "MAC",
                    value: networkInfo["macAddress"] ?? "-",
                    isDarkMode: isDarkMode
                )
                NetworkInfoRow(
                    label: locale == "zh" ? "网关" : "Gateway",
                    value: networkInfo["gateway"] ?? "-",
                    isDarkMode: isDarkMode
                )
            }
            .padding(8)
            
            Divider()
                .opacity(0.3)
            
            // Process list
            NetworkProcessListView(processes: processes, isLoading: isLoading, isDarkMode: isDarkMode, onTap: onTap)
        }
    }
}

struct NetworkInfoRow: View {
    let label: String
    let value: String
    let isDarkMode: Bool
    
    private var labelColor: Color {
        isDarkMode ? Color(white: 0.6) : Color.black.opacity(0.6)
    }
    
    private var valueColor: Color {
        isDarkMode ? Color.white : Color.black
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(labelColor)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .font(.system(size: 12))
        .frame(height: 22)
    }
}

struct NetworkProcessListView: View {
    let processes: [[String: Any]]
    let isLoading: Bool
    let isDarkMode: Bool
    let onTap: () -> Void
    
    private var secondaryTextColor: Color {
        isDarkMode ? Color(white: 0.6) : Color(white: 0.4)
    }
    
    var body: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(0.7)
                .frame(maxWidth: .infinity, minHeight: 60)
        } else if processes.isEmpty {
            Text("No active connections")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, minHeight: 60)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                // Header
                HStack {
                    Text("Process")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("PID")
                        .frame(width: 50, alignment: .trailing)
                    Text("Down")
                        .frame(width: 70, alignment: .trailing)
                    Text("Up")
                        .frame(width: 70, alignment: .trailing)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(secondaryTextColor)
                
                Divider()
                    .opacity(0.5)
                
                ForEach(Array(processes.enumerated()), id: \.offset) { _, process in
                    NetworkProcessRow(process: process, isDarkMode: isDarkMode, onTap: onTap)
                }
            }
            .padding(8)
        }
    }
}

struct NetworkProcessRow: View {
    let process: [String: Any]
    let isDarkMode: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    private var name: String { process["name"] as? String ?? "Unknown" }
    private var pid: Int { process["pid"] as? Int ?? 0 }
    private var download: Int { (process["download"] as? NSNumber)?.intValue ?? 0 }
    private var upload: Int { (process["upload"] as? NSNumber)?.intValue ?? 0 }
    
    private var textColor: Color {
        let baseColor = isDarkMode ? Color.white : Color.black
        return isHovered ? baseColor : baseColor.opacity(0.9)
    }
    
    private var hoverBackground: Color {
        isDarkMode ? Color.white.opacity(0.1) : Color.gray.opacity(0.1)
    }
    
    var body: some View {
        HStack {
            Text(name)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(pid > 0 ? "\(pid)" : "-")
                .frame(width: 50, alignment: .trailing)
            Text(formatSpeed(download))
                .frame(width: 70, alignment: .trailing)
            Text(formatSpeed(upload))
                .frame(width: 70, alignment: .trailing)
        }
        .font(.system(size: 12))
        .foregroundColor(textColor)
        .padding(.vertical, 2)
        .background(isHovered ? hoverBackground : Color.clear)
        .cornerRadius(4)
        .onHover { hovering in isHovered = hovering }
        .onTapGesture { onTap() }
    }
    
    private func formatSpeed(_ bytesPerSec: Int) -> String {
        if bytesPerSec >= 1024 * 1024 * 1024 {
            return String(format: "%.1fG/s", Double(bytesPerSec) / (1024 * 1024 * 1024))
        } else if bytesPerSec >= 1024 * 1024 {
            return String(format: "%.1fM/s", Double(bytesPerSec) / (1024 * 1024))
        } else if bytesPerSec >= 1024 {
            return String(format: "%.1fK/s", Double(bytesPerSec) / 1024)
        }
        return "\(bytesPerSec)B/s"
    }
}

// MARK: - Todo Content

struct TodoContentView: View {
    let todos: [[String: Any]]
    let isDarkMode: Bool
    
    var body: some View {
        if todos.isEmpty {
            Text("No todos")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, minHeight: 80)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(todos.prefix(10).enumerated()), id: \.offset) { _, todo in
                    TodoRow(todo: todo, isDarkMode: isDarkMode)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
    }
}

struct TodoRow: View {
    let todo: [String: Any]
    let isDarkMode: Bool
    
    private var title: String { todo["title"] as? String ?? "" }
    private var status: String { todo["status"] as? String ?? "todo" }
    
    private var icon: String {
        switch status {
        case "done": return "checkmark.circle.fill"
        case "doing": return "circle.inset.filled"
        default: return "circle"
        }
    }
    
    private var iconColor: Color {
        switch status {
        case "done": return .green
        case "doing": return .orange
        default: return .secondary
        }
    }
    
    private var textColor: Color {
        if status == "done" {
            return isDarkMode ? Color(white: 0.5) : Color.gray
        }
        return isDarkMode ? Color.white : Color.black
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 14))
            
            Text(title)
                .strikethrough(status == "done")
                .foregroundColor(textColor)
                .lineLimit(1)
        }
        .font(.system(size: 12))
    }
}

// MARK: - Level/Exp Content

struct LevelExpContentView: View {
    let data: [String: Any]
    let isDarkMode: Bool
    
    private var level: Int { data["level"] as? Int ?? 1 }
    private var currentExp: Double { (data["currentExp"] as? NSNumber)?.doubleValue ?? 0 }
    private var maxExp: Double { (data["maxExp"] as? NSNumber)?.doubleValue ?? 100 }
    private var locale: String { data["locale"] as? String ?? "en" }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            InfoRow(
                label: locale == "zh" ? "等级" : "Level",
                value: "\(level)",
                isDarkMode: isDarkMode
            )
            InfoRow(
                label: locale == "zh" ? "当前经验" : "Current EXP",
                value: "\(Int(currentExp))",
                isDarkMode: isDarkMode
            )
            InfoRow(
                label: locale == "zh" ? "升级经验" : "Max EXP",
                value: "\(Int(maxExp))",
                isDarkMode: isDarkMode
            )
        }
        .padding(8)
    }
}

// MARK: - Keyboard Content

struct KeyboardContentView: View {
    let keyCount: Int
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            InfoRow(
                label: "Today Key Events",
                value: formatNumber(keyCount),
                isDarkMode: isDarkMode
            )
        }
        .padding(8)
    }
    
    private func formatNumber(_ num: Int) -> String {
        if num >= 1_000_000 {
            return String(format: "%.1fM", Double(num) / 1_000_000)
        } else if num >= 1_000 {
            return String(format: "%.1fK", Double(num) / 1_000)
        }
        return "\(num)"
    }
}

// MARK: - Mouse Content

struct MouseContentView: View {
    let distance: Int
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            InfoRow(
                label: "Today Mouse Distance",
                value: formatDistance(distance),
                isDarkMode: isDarkMode
            )
        }
        .padding(8)
    }
    
    private func formatDistance(_ pixels: Int) -> String {
        // Convert pixels to meters (assuming 96 DPI, 1 inch = 2.54 cm)
        let meters = Double(pixels) / 96 * 2.54 / 100
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        } else if meters >= 1 {
            return String(format: "%.1f m", meters)
        }
        return String(format: "%.0f cm", meters * 100)
    }
}

// MARK: - Common Info Row

struct InfoRow: View {
    let label: String
    let value: String
    let isDarkMode: Bool
    
    private var textColor: Color {
        isDarkMode ? Color.white : Color.black
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(textColor)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(textColor)
        }
        .font(.system(size: 12))
    }
}
