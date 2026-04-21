//
//  SettingsView.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
  @EnvironmentObject var settingsManager: SettingsManager
  @EnvironmentObject var launchManager: LaunchAtLoginManager

  @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined

  var body: some View {
    Form {
      Section(header: Text("Python 环境配置").font(.headline)) {
        Text("请输入你的 Python 解释器可执行文件的完整路径。")
          .font(.caption)
          .foregroundColor(.secondary)

        LabeledContent {
          TextField("", text: $settingsManager.pythonPath)
        } label: {
          Text("解释器路径:")
        }
      }

      Divider().padding(.vertical, 8)

      Section(header: Text("脚本文件夹配置").font(.headline)) {
        Text("选择一个包含你想要运行的 .py 脚本的文件夹。")
          .font(.caption)
          .foregroundColor(.secondary)

        LabeledContent {
          HStack {
            Text(
              settingsManager.scriptFolderPath.isEmpty
                ? "尚未选择文件夹" : settingsManager.scriptFolderPath
            )
            .foregroundColor(settingsManager.scriptFolderPath.isEmpty ? .secondary : .primary)
            Spacer()
            Button("选择文件夹...") {
              openFolderSelectionPanel()
            }
          }
        } label: {
          Text("脚本目录:")
        }
      }

      Divider().padding(.vertical, 8)

      Section(header: Text("通用设置").font(.headline)) {
        Toggle("开机时自动启动", isOn: $launchManager.isEnabled)
          .toggleStyle(.switch)

        LabeledContent {
          HStack(spacing: 8) {
            switch notificationAuthStatus {
            case .authorized:
              Label("已允许", systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
              Button("前往系统设置") { openNotificationSettings() }
            case .denied:
              Label("已拒绝", systemImage: "xmark.circle.fill")
                .foregroundColor(.red)
              Button("前往系统设置开启") { openNotificationSettings() }
            case .notDetermined:
              Label("未请求", systemImage: "questionmark.circle")
                .foregroundColor(.secondary)
              Button("请求权限") { requestNotificationPermission() }
            default:
              Label("未知", systemImage: "questionmark.circle")
                .foregroundColor(.secondary)
            }
          }
        } label: {
          Text("完成通知:")
        }
      }
    }
    .padding()
    .frame(width: 500, height: 380)
    .onAppear { checkNotificationStatus() }
  }
}

// MARK: - 视图辅助方法
extension SettingsView {
  fileprivate func openFolderSelectionPanel() {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false

    if panel.runModal() == .OK {
      if let url = panel.url {
        let path = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
        settingsManager.scriptFolderPath = path
      }
    }
  }

  fileprivate func checkNotificationStatus() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        notificationAuthStatus = settings.authorizationStatus
      }
    }
  }

  fileprivate func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
      checkNotificationStatus()
    }
  }

  fileprivate func openNotificationSettings() {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
      NSWorkspace.shared.open(url)
    }
  }
}
