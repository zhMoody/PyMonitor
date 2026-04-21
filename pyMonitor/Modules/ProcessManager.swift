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

  @Published private(set) var runningScripts: [RunningScript] = []

  // 存储每个 runner 的订阅，runner 状态变化时触发 ProcessManager 自身刷新
  private var cancellables = Set<AnyCancellable>()

  var hasRunningScripts: Bool {
    runningScripts.contains { $0.runner.state.isRunning }
  }

  func startScript(scriptName: String, folderPath: String, pythonPath: String, arguments: [String] = []) {
    let newRunner = ProcessRunner()
    let newScript = RunningScript(scriptName: scriptName, arguments: arguments, runner: newRunner)

    runningScripts.append(newScript)

    // 监听 runner 的变化，让 ProcessManager 也能感知到，从而刷新依赖它的视图
    newRunner.objectWillChange
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.objectWillChange.send()
      }
      .store(in: &cancellables)

    let folderURL = URL(fileURLWithPath: (folderPath as NSString).expandingTildeInPath)
    let scriptURL = folderURL.appendingPathComponent(scriptName)
    newRunner.start(executablePath: pythonPath, scriptPath: scriptURL.path, arguments: arguments)
  }

  func stopScript(id: UUID) {
    if let script = runningScripts.first(where: { $0.id == id }) {
      script.runner.stop()
    }
  }

  func removeScript(id: UUID) {
    runningScripts.removeAll { $0.id == id }
  }
}
