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
  @State private var scriptArguments: String = ""
  @State private var showArgumentsSuggestions: Bool = false
  @FocusState private var isArgumentsFieldFocused: Bool

  var body: some View {
    VStack(spacing: 0) {
      headerView
        .padding(.horizontal, 16)
        .padding(.vertical, 12)

      Divider()

      scriptSelectionView
        .padding(.horizontal, 16)
        .padding(.top, 16)

      // 主内容区域是一个脚本列表
      ScrollView {
        if processManager.runningScripts.isEmpty {
          emptyStateView
        } else {
          VStack(spacing: 10) {
            ForEach(processManager.runningScripts) { script in
              ScriptExecutionView(script: script)
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
        }
      }

      Divider()

      footerView
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    .frame(width: 500, height: 650)
    .background(Color(NSColor.windowBackgroundColor))
    .onAppear(perform: scanForScripts)
    .onChange(of: settingsManager.scriptFolderPath) { _, _ in scanForScripts() }
  }
}

// MARK: - 视图构建
extension AppMenuView {
  fileprivate var headerView: some View {
    HStack(spacing: 12) {
      Text("Python 脚本监控器")
        .font(.headline)

      Spacer()

      Button(action: { openSettings() }) {
        Image(systemName: "gearshape")
      }
      .buttonStyle(.plain)
      .help("设置")
    }
  }

  fileprivate var scriptSelectionView: some View {
    HStack(spacing: 8) {
      // 脚本选择器
      Picker("", selection: $selectedScript) {
        Text("选择脚本...").tag(nil as String?)
        ForEach(pythonScripts, id: \.self) { script in
          Text(script).tag(script as String?)
        }
      }
      .labelsHidden()
      .frame(width: 180)

      // 参数输入框（使用 overlay 实现浮层联想）
      TextField("启动参数（可选）", text: $scriptArguments)
        .textFieldStyle(.roundedBorder)
        .focused($isArgumentsFieldFocused)
        .onChange(of: scriptArguments) { _, _ in
          showArgumentsSuggestions = !scriptArguments.isEmpty && !filteredArgumentsHistory.isEmpty
        }
        .onChange(of: isArgumentsFieldFocused) { _, focused in
          if !focused {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              showArgumentsSuggestions = false
            }
          }
        }
        .onSubmit {
          startNewScript()
        }
        .overlay(alignment: .topLeading) {
          // 联想建议浮层（绝对定位，不影响布局）
          if showArgumentsSuggestions && isArgumentsFieldFocused {
            VStack(alignment: .leading, spacing: 0) {
              ForEach(filteredArgumentsHistory.prefix(5), id: \.self) { suggestion in
                Button(action: {
                  scriptArguments = suggestion
                  showArgumentsSuggestions = false
                  isArgumentsFieldFocused = false
                }) {
                  Text(suggestion)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if suggestion != filteredArgumentsHistory.prefix(5).last {
                  Divider()
                }
              }
            }
            .background(.background)
            .cornerRadius(6)
            .shadow(radius: 4)
            .offset(y: 28)
            .zIndex(1000)
          }
        }

      // 启动按钮
      Button(action: startNewScript) {
        Text("启动")
      }
      .disabled(selectedScript == nil)
    }
  }

  fileprivate var emptyStateView: some View {
    VStack(spacing: 12) {
      Image(systemName: "tray")
        .font(.system(size: 48))
        .foregroundStyle(.secondary)

      Text("暂无运行中的脚本")
        .font(.body)
        .foregroundStyle(.secondary)

      Text("从上方选择脚本并点击启动")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.vertical, 60)
  }

  fileprivate var footerView: some View {
    HStack(spacing: 12) {
      let runningCount = processManager.runningScripts.filter { $0.runner.state.isRunning }.count
      if runningCount > 0 {
        HStack(spacing: 6) {
          Circle()
            .fill(.green)
            .frame(width: 8, height: 8)
          Text("\(runningCount) 个脚本运行中")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      Button(action: { NSApplication.shared.terminate(nil) }) {
        Text("退出应用")
          .font(.caption)
      }
      .buttonStyle(.plain)
    }
  }
}

// MARK: - 逻辑与方法
extension AppMenuView {
  fileprivate func startNewScript() {
    guard let scriptName = selectedScript else { return }

    // 将参数字符串分割成数组
    let args = scriptArguments
      .split(separator: " ")
      .map { String($0) }
      .filter { !$0.isEmpty }

    processManager.startScript(
      scriptName: scriptName,
      folderPath: settingsManager.scriptFolderPath,
      pythonPath: settingsManager.pythonPath,
      arguments: args
    )

    // 保存参数到历史记录（不清空输入框）
    if !scriptArguments.isEmpty {
      settingsManager.addArgumentsToHistory(scriptArguments)
    }

    // 隐藏联想列表
    showArgumentsSuggestions = false
  }

  // 过滤历史记录用于联想
  fileprivate var filteredArgumentsHistory: [String] {
    if scriptArguments.isEmpty {
      return settingsManager.argumentsHistory
    }
    return settingsManager.argumentsHistory.filter {
      $0.localizedCaseInsensitiveContains(scriptArguments)
    }
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
