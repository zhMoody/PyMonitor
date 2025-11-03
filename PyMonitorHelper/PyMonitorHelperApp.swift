//
//  PyMonitorHelperApp.swift
//  PyMonitorHelper
//
//  Created by 张浩 on 2025/11/3.
//

import SwiftUI
import AppKit

@main
struct PyMonitorHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings { }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let mainAppIdentifier = "cn.coder.pyMonitor"
        let runningApps = NSWorkspace.shared.runningApplications
        let isMainAppRunning = !runningApps.filter { $0.bundleIdentifier == mainAppIdentifier }.isEmpty
        if !isMainAppRunning {
            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast(4)
            let mainAppURL = NSURL.fileURL(withPath: components.joined(separator: "/"))
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: mainAppURL, configuration: configuration)
        }
        
        NSApp.terminate(nil)
    }
}
