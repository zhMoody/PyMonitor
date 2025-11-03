//
//  SettingsView.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

import SwiftUI

struct SettingsView: View {
  @EnvironmentObject var settingsManager: SettingsManager
  @EnvironmentObject var launchManager: LaunchAtLoginManager
  
  var body: some View {
    Form {
      // MARK: - Python 解释器设置
      Section(header: Text("Python 环境配置").font(.headline)) {
        Text("请输入你的 Python 解释器可执行文件的完整路径。")
          .font(.caption)
          .foregroundColor(.secondary)

        // 使用 LabeledContent 优化布局
        LabeledContent {
          TextField("", text: $settingsManager.pythonPath)
        } label: {
          Text("解释器路径:")
        }
      }

      Divider().padding(.vertical, 8)

      // MARK: - 脚本文件夹设置
      Section(header: Text("脚本文件夹配置").font(.headline)) {
        Text("选择一个包含你想要运行的 .py 脚本的文件夹。")
          .font(.caption)
          .foregroundColor(.secondary)

        LabeledContent {
          HStack {
            // 显示当前选择的路径，如果是空则提示用户选择
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
           }
    }
    .padding()
    .frame(width: 500, height: 320)  // 给设置窗口一个合适的尺寸
  }
}

// MARK: - 视图辅助方法
extension SettingsView {
  // 打开一个系统标准的文件夹选择面板
  fileprivate func openFolderSelectionPanel() {
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.allowsMultipleSelection = false

    // 显示面板，并处理用户的选择
    if panel.runModal() == .OK {
      if let url = panel.url {
        // 将 file:// URL 转换为 POSIX 路径字符串
        let path = url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
        settingsManager.scriptFolderPath = path
      }
    }
  }
}
