//
//  AppMenuView.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//
// MARK: - AppMenuView.swift

import SwiftUI

struct AppMenuView: View {
  @EnvironmentObject var processManager: ProcessManager
  @EnvironmentObject var settingsManager: SettingsManager
  @Environment(\.openSettings) private var openSettings

  @State private var pythonScripts: [String] = []
  @State private var selectedScript: String?

  var body: some View {
    VStack(spacing: 12) {
      headerView
      Divider()
      scriptSelectionView

      // 主内容区域是一个脚本列表
      ScrollView {
        if processManager.runningScripts.isEmpty {
          emptyStateView
        } else {
          // 遍历所有被监控的脚本，为每个脚本创建一个独立的视图
          ForEach(processManager.runningScripts) { script in
            ScriptExecutionView(script: script)
              .padding(.bottom, 6)
          }
        }
      }

      Divider()
      footerView
    }
    .padding()
    .frame(width: 450, height: 600)
    .onAppear(perform: scanForScripts)
    .onChange(of: settingsManager.scriptFolderPath) { _, _ in scanForScripts() }
  }
}

// MARK: - 视图构建
extension AppMenuView {
  fileprivate var headerView: some View {
    HStack {
      Text("Python 脚本监控器")
        .font(.title2)
      Spacer()
      Button(action: { openSettings() }) {
        Image(systemName: "gearshape.fill")
      }.buttonStyle(.plain)
    }
  }

  fileprivate var scriptSelectionView: some View {
    GroupBox("执行控制") {
      HStack {
        // 脚本选择器
        Picker("选择脚本", selection: $selectedScript) {
          Text("请选择一个脚本").tag(nil as String?)
          ForEach(pythonScripts, id: \.self) { Text($0).tag($0 as String?) }
        }
        .labelsHidden()
        .frame(maxWidth: .infinity)

        // 启动按钮
        Button("启动新脚本", action: startNewScript)
          .disabled(selectedScript == nil)
      }
    }
  }

  fileprivate var emptyStateView: some View {
    Text("没有正在运行的脚本。\n请从上方选择一个脚本并启动。")
      .font(.callout)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.center)
      .padding(.vertical, 50)
  }

  fileprivate var footerView: some View {
    HStack {
      Spacer()
      Button("退出应用") { NSApplication.shared.terminate(nil) }
    }
  }
}

// MARK: - 逻辑与方法
extension AppMenuView {
  fileprivate func startNewScript() {
    guard let scriptName = selectedScript else { return }
    processManager.startScript(
      scriptName: scriptName,
      folderPath: settingsManager.scriptFolderPath,
      pythonPath: settingsManager.pythonPath
    )
  }

  fileprivate func scanForScripts() {
    let scripts = FileScanner.scanPythonScripts(in: settingsManager.scriptFolderPath)
    self.pythonScripts = scripts
    if !scripts.contains(selectedScript ?? "") {
      self.selectedScript = nil
    }
    // 默认选中第一个
    if selectedScript == nil, let firstScript = scripts.first {
      self.selectedScript = firstScript
    }
  }
}
