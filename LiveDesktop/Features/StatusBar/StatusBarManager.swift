import Cocoa
import SwiftUI

protocol StatusBarManagerDelegate: AnyObject {
    func statusBarDidToggleWallpaper()
    func statusBarDidToggleLaunchAtLogin()
    func statusBarDidRequestQuit()
    func statusBarDidOpenDashboard()
    var isWallpaperEnabled: Bool { get }
    var isLaunchAtLoginEnabled: Bool { get }
}

class StatusBarManager: NSObject {
    private var statusItem: NSStatusItem!
    weak var delegate: StatusBarManagerDelegate?
    
    func setupStatusBar() {
        print("📱 StatusBarManager: Setting up status bar item")
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "tv.fill", accessibilityDescription: "LiveDesktop")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
            print("✅ StatusBarManager: Status bar button configured")
        } else {
            print("❌ StatusBarManager: Failed to get status bar button")
        }
    }
    
    @objc private func statusBarButtonClicked() {
        showStatusMenu()
    }
    
    private func showStatusMenu() {
        let menu = NSMenu()
        
        // Title
        let titleItem = NSMenuItem()
        titleItem.attributedTitle = NSAttributedString(
            string: "Live Desktop",
            attributes: [
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.labelColor
            ]
        )
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        // Separator
        menu.addItem(NSMenuItem.separator())
        
        // Dashboard option
        let dashboardItem = NSMenuItem(
            title: "Dashboard",
            action: #selector(openDashboard),
            keyEquivalent: "d"
        )
        dashboardItem.target = self
        menu.addItem(dashboardItem)
        
        // Separator
        menu.addItem(NSMenuItem.separator())
        
        // Toggle switch
        let toggleItem = NSMenuItem()
        let toggleView = createToggleView()
        toggleItem.view = toggleView
        menu.addItem(toggleItem)
        
        // Separator
        menu.addItem(NSMenuItem.separator())
        
        // Launch at Login toggle
        let launchAtLoginItem = NSMenuItem()
        let launchAtLoginView = createLaunchAtLoginToggleView()
        launchAtLoginItem.view = launchAtLoginView
        menu.addItem(launchAtLoginItem)
        
        // Separator
        menu.addItem(NSMenuItem.separator())
        
        // Quit option
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }
    
    private func createToggleView() -> NSView {
        let toggleView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 40))
        
        let isEnabled = delegate?.isWallpaperEnabled ?? false
        
        // Label
        let label = NSTextField(labelWithString: isEnabled ? "Turn Off" : "Turn On")
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = NSColor.labelColor
        label.frame = NSRect(x: 16, y: 12, width: 100, height: 16)
        label.tag = 998
        toggleView.addSubview(label)
        
        // Native switch
        let switchControl = NSSwitch(frame: NSRect(x: 150, y: 10, width: 20, height: 20))
        switchControl.state = isEnabled ? .on : .off
        switchControl.target = self
        switchControl.action = #selector(toggleWallpaper)
        switchControl.tag = 999
        
        toggleView.addSubview(switchControl)
        
        return toggleView
    }
    
    private func createLaunchAtLoginToggleView() -> NSView {
        let toggleView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 40))
        
        let isEnabled = delegate?.isLaunchAtLoginEnabled ?? false
        
        // Label
        let label = NSTextField(labelWithString: "Launch at Login")
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = NSColor.labelColor
        label.frame = NSRect(x: 16, y: 12, width: 120, height: 16)
        label.tag = 996
        toggleView.addSubview(label)
        
        // Native switch
        let switchControl = NSSwitch(frame: NSRect(x: 150, y: 10, width: 20, height: 20))
        switchControl.state = isEnabled ? .on : .off
        switchControl.target = self
        switchControl.action = #selector(toggleLaunchAtLogin)
        switchControl.tag = 997
        
        toggleView.addSubview(switchControl)
        
        return toggleView
    }
    
    func updateToggleControls() {
        // Defer the update to avoid layout recursion
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let menu = self.statusItem.menu else { return }
            let isWallpaperEnabled = self.delegate?.isWallpaperEnabled ?? false
            let isLaunchAtLoginEnabled = self.delegate?.isLaunchAtLoginEnabled ?? false
            
            for item in menu.items {
                if let view = item.view {
                    // Wallpaper toggle controls
                    if let label = view.viewWithTag(998) as? NSTextField {
                        label.stringValue = isWallpaperEnabled ? "Turn Off" : "Turn On"
                    }
                    if let switchControl = view.viewWithTag(999) as? NSSwitch {
                        switchControl.state = isWallpaperEnabled ? .on : .off
                    }
                    
                    // Launch at login toggle controls
                    if let switchControl = view.viewWithTag(997) as? NSSwitch {
                        switchControl.state = isLaunchAtLoginEnabled ? .on : .off
                    }
                }
            }
        }
    }
    
    @objc private func toggleWallpaper() {
        delegate?.statusBarDidToggleWallpaper()
        updateToggleControls()
    }
    
    @objc private func toggleLaunchAtLogin() {
        delegate?.statusBarDidToggleLaunchAtLogin()
        updateToggleControls()
    }
    
    @objc private func openDashboard() {
        print("📋 StatusBarManager: Dashboard menu item clicked")
        delegate?.statusBarDidOpenDashboard()
    }
    
    @objc private func quitApp() {
        delegate?.statusBarDidRequestQuit()
    }
}
