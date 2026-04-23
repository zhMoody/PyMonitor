//
//  SettingsView.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

import AVFoundation
import SwiftUI
import UserNotifications

struct SettingsView: View {
  @EnvironmentObject var settingsManager: SettingsManager
  @EnvironmentObject var launchManager: LaunchAtLoginManager

  @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined
  @State private var micStatus: AVAuthorizationStatus = .notDetermined
  @State private var cameraStatus: AVAuthorizationStatus = .notDetermined
  @State private var screenCaptureGranted: Bool = false
  @State private var accessibilityGranted: Bool = false

  var body: some View {
    let labelWidth: CGFloat = 90
    VStack(alignment: .leading, spacing: 0) {

      // MARK: Python 环境配置
      Text("Python 环境配置").font(.headline)
      Text("请输入你的 Python 解释器可执行文件的完整路径。")
        .font(.caption).foregroundColor(.secondary).padding(.top, 2)
      row(label: "解释器路径:", labelWidth: labelWidth) {
        TextField("", text: $settingsManager.pythonPath)
          .textFieldStyle(.roundedBorder)
      }

      Divider().padding(.vertical, 12)

      // MARK: 脚本文件夹配置
      Text("脚本文件夹配置").font(.headline)
      Text("选择一个包含你想要运行的 .py 脚本的文件夹。")
        .font(.caption).foregroundColor(.secondary).padding(.top, 2)
      row(label: "脚本目录:", labelWidth: labelWidth) {
        HStack {
          Text(settingsManager.scriptFolderPath.isEmpty ? "尚未选择文件夹" : settingsManager.scriptFolderPath)
            .foregroundColor(settingsManager.scriptFolderPath.isEmpty ? .secondary : .primary)
            .lineLimit(1)
          Spacer()
          Button("选择文件夹...") { openFolderSelectionPanel() }
        }
      }

      Divider().padding(.vertical, 12)

      // MARK: 通用设置
      Text("通用设置").font(.headline)
      row(label: "开机启动:", labelWidth: labelWidth) {
        Toggle("开机时自动启动", isOn: $launchManager.isEnabled).toggleStyle(.switch)
      }

      Divider().padding(.vertical, 12)

      // MARK: 权限管理
      Text("权限管理").font(.headline)
      Text("以下权限供脚本按需使用，未用到的可忽略。")
        .font(.caption).foregroundColor(.secondary).padding(.top, 2)

      permissionRow2("完成通知:", labelWidth: labelWidth, status: notificationStatus, url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Notifications")
      permissionRow2("麦克风:", labelWidth: labelWidth, status: avStatus(micStatus), url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
      permissionRow2("摄像头:", labelWidth: labelWidth, status: avStatus(cameraStatus), url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera")
      permissionRow2("屏幕录制:", labelWidth: labelWidth, status: boolStatus(screenCaptureGranted), url: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
      permissionRow2("辅助功能:", labelWidth: labelWidth, status: boolStatus(accessibilityGranted), url: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }
    .padding(20)
    .frame(width: 500)
    .onAppear { refreshAllStatuses() }
    .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
      NSApp.windows.filter { $0.canBecomeKey }.forEach { $0.makeKeyAndOrderFront(nil) }
    }
  }

  // MARK: - 通用行布局

  private func row<C: View>(label: String, labelWidth: CGFloat, @ViewBuilder content: () -> C) -> some View {
    HStack(alignment: .center, spacing: 12) {
      Text(label)
        .frame(width: labelWidth, alignment: .trailing)
        .foregroundColor(.secondary)
      content()
    }
    .padding(.top, 8)
  }

  private func permissionRow2(_ label: String, labelWidth: CGFloat, status: (String, String, Color), url: String) -> some View {
    HStack(alignment: .center, spacing: 12) {
      Text(label)
        .frame(width: labelWidth, alignment: .trailing)
        .foregroundColor(.secondary)
      Label(status.0, systemImage: status.1)
        .foregroundColor(status.2)
      Spacer()
      Button("前往授权") {
        if let u = URL(string: url) { NSWorkspace.shared.open(u) }
      }
      .buttonStyle(.borderless)
      .foregroundColor(.accentColor)
    }
    .padding(.top, 8)
  }

  // MARK: - 状态计算

  private var notificationStatus: (String, String, Color) {
    switch notificationAuthStatus {
    case .authorized: return ("已允许", "checkmark.circle.fill", .green)
    case .denied: return ("已拒绝", "xmark.circle.fill", .red)
    default: return ("未授权", "questionmark.circle", .secondary)
    }
  }

  private func avStatus(_ s: AVAuthorizationStatus) -> (String, String, Color) {
    switch s {
    case .authorized: return ("已允许", "checkmark.circle.fill", .green)
    case .denied, .restricted: return ("已拒绝", "xmark.circle.fill", .red)
    default: return ("未授权", "questionmark.circle", .secondary)
    }
  }

  private func boolStatus(_ granted: Bool) -> (String, String, Color) {
    granted
      ? ("已允许", "checkmark.circle.fill", .green)
      : ("未授权", "questionmark.circle", .secondary)
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

  fileprivate func refreshAllStatuses() {
    // 通知
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async { notificationAuthStatus = settings.authorizationStatus }
    }
    // 麦克风 / 摄像头
    micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    // 屏幕录制
    screenCaptureGranted = CGPreflightScreenCaptureAccess()
    // 辅助功能
    accessibilityGranted = AXIsProcessTrusted()
  }

  fileprivate func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
      refreshAllStatuses()
    }
  }
}
