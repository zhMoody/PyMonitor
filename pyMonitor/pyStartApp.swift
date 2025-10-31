//
//  pyStartApp.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

import SwiftUI

@main
struct pyStartApp: App {
  // MARK: - 状态管理

  @StateObject private var processManager = ProcessManager()
  @StateObject private var settingsManager = SettingsManager()

  var body: some Scene {
    MenuBarExtra {
      // 注入 ProcessManager
      AppMenuView()
        .environmentObject(processManager)
        .environmentObject(settingsManager)
    } label: {
      // 可以根据是否有任何脚本在运行来改变
      Image(systemName: processManager.hasRunningScripts ? "terminal.fill" : "terminal")
    }
    .menuBarExtraStyle(.window)

    Settings {
      SettingsView()
        .environmentObject(settingsManager)
    }
  }
}
