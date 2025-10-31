//
//  ProcessManager.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

// MARK: - ProcessManager.swift

import Combine
import Foundation
import SwiftUI

class ProcessManager: ObservableObject {

  // 持有一个 RunningScript 实例的数组，任何对这个数组的改动都会通知视图更新
  @Published private(set) var runningScripts: [RunningScript] = []

  // 计算属性，方便视图判断是否有任何脚本在运行
  var hasRunningScripts: Bool {
    // 只要数组中有一个脚本的 runner.state 是 .running，就返回 true
    runningScripts.contains { $0.runner.state.isRunning }
  }

  // 启动一个新脚本
  func startScript(scriptName: String, folderPath: String, pythonPath: String) {
    let newRunner = ProcessRunner()
    let newScript = RunningScript(scriptName: scriptName, runner: newRunner)

    // 将新脚本添加到数组中，UI 会自动刷新
    runningScripts.append(newScript)

    // 拼接完整的脚本路径并启动它
    let folderURL = URL(fileURLWithPath: (folderPath as NSString).expandingTildeInPath)
    let scriptURL = folderURL.appendingPathComponent(scriptName)

    newRunner.start(executablePath: pythonPath, scriptPath: scriptURL.path)
  }

  // 停止一个指定的脚本
  func stopScript(id: UUID) {
    // 通过 ID 找到对应的脚本
    if let script = runningScripts.first(where: { $0.id == id }) {
      script.runner.stop()
    }
  }

  // 从列表中移除一个（通常是已停止的）脚本
  func removeScript(id: UUID) {
    // 使用 removeAll(where:) 来安全地移除匹配项
    runningScripts.removeAll { $0.id == id }
  }
}
