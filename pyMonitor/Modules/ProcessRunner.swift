//
//  ProcessRunner.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

import Combine
import Foundation
import SwiftUI

class ProcessRunner: ObservableObject {
  @Published var state: ProcessState = .idle
  @Published var output: String = ""  // 用于存储脚本的实时输出

  private var process: Process?
  private var outputPipe: Pipe?  // Pipe 必须在每次运行时重新创建，所以设为可选

  // 启动脚本
  func start(executablePath: String, scriptPath: String) {
    // 只要当前没有进程在运行，就允许启动
    guard !state.isRunning else { return }

    // --- 路径处理与验证 ---
    let expandedExecutablePath = (executablePath as NSString).expandingTildeInPath
    let expandedScriptPath = (scriptPath as NSString).expandingTildeInPath

    guard !expandedExecutablePath.isEmpty,
      FileManager.default.isExecutableFile(atPath: expandedExecutablePath)
    else {
      self.state = .stopped(reason: "错误：Python 解释器路径无效或文件不可执行。")
      return
    }

    guard !expandedScriptPath.isEmpty, FileManager.default.fileExists(atPath: expandedScriptPath)
    else {
      self.state = .stopped(reason: "错误：脚本文件未找到。")
      return
    }

    // --- 进程与管道配置 ---
    process = Process()

    // 每次启动都必须创建一个全新的 Pipe 对象
    self.outputPipe = Pipe()

    // 安全地解包新创建的 pipe
    guard let outputPipe = self.outputPipe else {
      self.state = .stopped(reason: "内部错误：无法创建管道。")
      return
    }

    process?.executableURL = URL(fileURLWithPath: expandedExecutablePath)
    process?.arguments = [expandedScriptPath]

    // 将标准输出和标准错误都重定向到同一个新创建的管道
    process?.standardOutput = outputPipe
    process?.standardError = outputPipe

    // --- 异步读取输出 ---
    // 为新管道的文件句柄设置处理器
    outputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
      let data = fileHandle.availableData
      if !data.isEmpty, let newOutput = String(data: data, encoding: .utf8) {
        // 将新输出追加到我们的 output 属性中，UI会自动更新
        DispatchQueue.main.async {
          self?.output.append(newOutput)
        }
      }
    }

    // --- 进程终止处理器 ---
    // 设置一个处理器，当进程因为任何原因终止时，它就会被调用
    process?.terminationHandler = { [weak self] process in
      DispatchQueue.main.async {
        let reason: String
        switch process.terminationReason {
        case .exit:
          reason = "进程已正常退出，退出码: \(process.terminationStatus)。"
        case .uncaughtSignal:
          reason = "进程因未捕获的信号而异常终止。"
        @unknown default:
          reason = "进程因未知原因终止。"
        }
        self?.state = .stopped(reason: reason)
        self?.cleanup()  // 统一清理资源
      }
    }

    // --- 运行进程 ---
    do {
      output = ""  // 每次启动前清空之前的输出
      try process?.run()
      self.state = .running
    } catch {
      self.state = .stopped(reason: "启动进程失败: \(error.localizedDescription)")
    }
  }

  // 停止脚本
  func stop() {
    guard let process = process, process.isRunning else { return }
    process.terminate()  // 发送终止信号
    self.state = .stopped(reason: "已手动停止。")
    cleanup()  // 统一清理资源
  }

  // 清理所有与进程相关的资源
  private func cleanup() {
    // 移除文件句柄的处理器，防止内存泄漏
    outputPipe?.fileHandleForReading.readabilityHandler = nil
    // 释放进程对象
    process = nil
    // 释放管道对象，确保下次 start 会创建全新的实例
    outputPipe = nil
  }
}

// 扩展 ProcessState，方便在 View 中直接判断
extension ProcessState {
  var isRunning: Bool {
    if case .running = self { return true }
    return false
  }
}
