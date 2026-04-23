//
//  pyStartApp.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

import SwiftUI
import UserNotifications

@main
struct pyStartApp: App {
  @StateObject private var processManager = ProcessManager()
  @StateObject private var settingsManager = SettingsManager()
  @StateObject private var launchManager = LaunchAtLoginManager()

  var body: some Scene {
    MenuBarExtra {
      AppMenuView()
        .environmentObject(processManager)
        .environmentObject(settingsManager)
        .environmentObject(launchManager)
        .onAppear {
          UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    } label: {
      Image(systemName: processManager.hasRunningScripts ? "terminal.fill" : "terminal")
    }
    .menuBarExtraStyle(.window)

//    Settings {
//      SettingsView()
//        .environmentObject(settingsManager)
//        .environmentObject(launchManager)
//    }
  }
}
