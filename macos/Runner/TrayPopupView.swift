import SwiftUI
import Cocoa

/// A view controller for the tray icon popup that shows a live preview of the game window.
/// Uses streamed image frames from Flutter for the preview.
class TrayPopupViewController: NSViewController {
    
    private var hostingView: NSHostingView<AnyView>?
    private var currentImage: NSImage?
    private var isDarkMode: Bool = true
    private var locale: String = "en"
    private var onShowWindow: (() -> Void)?
    private var onHideWindow: (() -> Void)?
    private var onExitApp: (() -> Void)?
    private var onPinToggle: (() -> Void)?
    
    // Popup size - initialized from Dart constants via configure()
    private var popupSize: NSSize = .zero
    private var titleBarHeight: CGFloat = 0
    
    // Pin state - observable for SwiftUI updates
    private let pinState = PinState()
    
    // Observable object to trigger SwiftUI updates
    private let imageState = ImageState()
    
    override func loadView() {
        view = NSView()
        view.wantsLayer = true
    }
    
    func configure(
        isDarkMode: Bool,
        locale: String,
        popupWidth: CGFloat,
        popupHeight: CGFloat,
        titleBarHeight: CGFloat,
        isPinned: Bool,
        onShowWindow: @escaping () -> Void,
        onHideWindow: @escaping () -> Void,
        onExitApp: @escaping () -> Void,
        onPinToggle: @escaping () -> Void
    ) {
        self.isDarkMode = isDarkMode
        self.locale = locale
        self.popupSize = NSSize(width: popupWidth, height: popupHeight)
        self.titleBarHeight = titleBarHeight
        self.pinState.isPinned = isPinned
        self.onShowWindow = onShowWindow
        self.onHideWindow = onHideWindow
        self.onExitApp = onExitApp
        self.onPinToggle = onPinToggle
        
        updateContent()
    }
    
    func updatePinState(_ isPinned: Bool) {
        pinState.isPinned = isPinned
    }
    
    func updateFrame(imageData: Data, width: Int, height: Int) {
        if let image = NSImage(data: imageData) {
            image.size = NSSize(width: width, height: height)
            imageState.image = image
        }
    }
    
    private func updateContent() {
        let contentView = TrayPopupContentView(
            imageState: imageState,
            pinState: pinState,
            isDarkMode: isDarkMode,
            locale: locale,
            titleBarHeight: titleBarHeight,
            onShowWindow: { [weak self] in self?.onShowWindow?() },
            onHideWindow: { [weak self] in self?.onHideWindow?() },
            onExitApp: { [weak self] in self?.onExitApp?() },
            onPinToggle: { [weak self] in self?.onPinToggle?() }
        )
        
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
        
        // Set preferred content size from Dart constants
        preferredContentSize = popupSize
    }
}

/// Observable object to hold the current preview image
class ImageState: ObservableObject {
    @Published var image: NSImage?
}

/// Observable object to hold the pin state
class PinState: ObservableObject {
    @Published var isPinned: Bool = false
}

/// SwiftUI view for the tray popup content
struct TrayPopupContentView: View {
    @ObservedObject var imageState: ImageState
    @ObservedObject var pinState: PinState
    let isDarkMode: Bool
    let locale: String
    let titleBarHeight: CGFloat
    let onShowWindow: () -> Void
    let onHideWindow: () -> Void
    let onExitApp: () -> Void
    let onPinToggle: () -> Void
    
    private var title: String {
        locale == "zh" ? "赛博修仙" : "Cyber Cultivation"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            titleBar
            
            Divider()
                .opacity(0.3)
            
            // Preview area
            previewArea
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
            // Center: Title
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isDarkMode ? Color.white : Color.black)
            
            // Left and Right buttons
            HStack {
                // Left: Show/Hide buttons
                HStack(spacing: 12) {
                    TrayIconButton(
                        icon: "eye",
                        tooltip: locale == "zh" ? "显示窗口" : "Show Window",
                        isDarkMode: isDarkMode,
                        action: onShowWindow
                    )
                    TrayIconButton(
                        icon: "eye.slash",
                        tooltip: locale == "zh" ? "隐藏窗口" : "Hide Window",
                        isDarkMode: isDarkMode,
                        action: onHideWindow
                    )
                }
                
                Spacer()
                
                // Right: Pin button and Exit button
                HStack(spacing: 12) {
                    TrayIconButton(
                        icon: pinState.isPinned ? "pin.fill" : "pin",
                        tooltip: locale == "zh" ? (pinState.isPinned ? "取消固定" : "固定窗口") : (pinState.isPinned ? "Unpin" : "Pin Window"),
                        isActive: pinState.isPinned,
                        isDarkMode: isDarkMode,
                        action: onPinToggle
                    )
                    TrayIconButton(
                        icon: "power",
                        tooltip: locale == "zh" ? "退出游戏" : "Exit Game",
                        isDestructive: true,
                        isDarkMode: isDarkMode,
                        action: onExitApp
                    )
                }
            }
        }
        .padding(.horizontal, 8)
        .frame(height: titleBarHeight)
    }
    
    private var previewArea: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent background
                (isDarkMode ? Color(white: 0.1, opacity: 0.6) : Color(white: 0.95, opacity: 0.6))
                
                if let image = imageState.image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Loading placeholder
                    VStack(spacing: 8) {
                        TrayLoadingSpinner(isDarkMode: isDarkMode)
                        Text(locale == "zh" ? "加载中..." : "Loading...")
                            .font(.system(size: 11))
                            .foregroundColor(isDarkMode ? Color.white.opacity(0.6) : .secondary)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .padding(4)
    }
}

/// A custom loading spinner that works well in both light and dark modes
struct TrayLoadingSpinner: View {
    let isDarkMode: Bool
    
    @State private var isAnimating = false
    
    private var spinnerColor: Color {
        isDarkMode ? Color.white.opacity(0.8) : Color.black.opacity(0.6)
    }
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(spinnerColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: 16, height: 16)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 0.8).repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

/// Icon button for tray popup title bar
struct TrayIconButton: View {
    let icon: String
    let tooltip: String
    var isDestructive: Bool = false
    var isActive: Bool = false
    var isDarkMode: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    private var normalColor: Color {
        isDarkMode ? Color(white: 0.6) : Color(white: 0.4)
    }
    
    private var hoverColor: Color {
        isDarkMode ? Color.white : Color.black
    }
    
    private var activeColor: Color {
        Color.accentColor
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(buttonColor)
        }
        .buttonStyle(.plain)
        .help(tooltip)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var buttonColor: Color {
        if isDestructive {
            return .red
        } else if isActive {
            return activeColor
        } else if isHovered {
            return hoverColor
        } else {
            return normalColor        }
    }
}