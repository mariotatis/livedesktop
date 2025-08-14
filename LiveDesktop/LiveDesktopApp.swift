//
//  LiveDesktopApp.swift
//  LiveDesktop
//
//  Created by Mayo Tatis on 13/08/25.
//

import SwiftUI

@main
struct LiveDesktopApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings { // No main window needed
            EmptyView()
        }
    }
}
