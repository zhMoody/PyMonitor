//
//  ProcessRunner.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

//
//  ProcessRunner.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

import Combine
import Foundation
import SwiftUI
import DequeModule // [新增] 导入 Swift Collections 库

class ProcessRunner: ObservableObject {
  @Published var state: ProcessState = .idle
  
  // [修改 1/5] 将单一的 String 替换为一个双端队列 Deque<String>
  @Published private(set) var logLines: Deque<String> = []

  // [修改 2/5] 创建一个计算属性来无缝对接视图层
  // 你的视图代码完全不需要任何改动，它会继续访问这个 `output` 变量
  var output: String {
    // Deque 也是一个序列，可以直接用于拼接字符串
    return logLines.joined(separator: "\n")
  }

  private let maxLogLines = 100 // 将 100 定义为一个常量，方便未来修改
  private var process: Process?
  private var outputPipe: Pipe?
  
  // [修改 3/5] 新增一个行缓冲区来处理不完整的日志流
  private var lineBuffer: String = ""

  // 启动脚本
  func start(executablePath: String, scriptPath: String) {
    // 只要当前没有进程在运行，就允许启动
    guard !state.isRunning else { return }

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
    // [修改 4/5] 这是最核心的改动：重写日志处理逻辑以使用 Deque
    outputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
        guard let self = self else { return }
        let data = fileHandle.availableData
        
        if !data.isEmpty, let newOutput = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                // 1. 将新收到的数据追加到行缓冲区
                self.lineBuffer.append(newOutput)
                
                // 2. 循环处理缓冲区中所有完整的行 (以 \n 分隔)
                while let range = self.lineBuffer.range(of: "\n") {
                    let completeLine = String(self.lineBuffer[..<range.lowerBound])
                    
                    // 3. 关键逻辑：如果队列已满，先用 O(1) 的复杂度移除最旧的一条
                    if self.logLines.count >= self.maxLogLines {
                        self.logLines.removeFirst()
                    }
                    // 4. 然后再添加最新的一条
                    self.logLines.append(completeLine)
                    
                    // 从缓冲区中移除已经处理过的行
                    self.lineBuffer.removeSubrange(..<range.upperBound)
                }
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
      // [修改 5/5] 每次启动前，清空日志队列和缓冲区
      logLines.removeAll()
      lineBuffer = ""
      
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
    // 进程结束后，如果缓冲区还有残留内容，也把它作为最后一行加进去
    if !lineBuffer.isEmpty {
        DispatchQueue.main.async {
            if self.logLines.count >= self.maxLogLines {
                self.logLines.removeFirst()
            }
            self.logLines.append(self.lineBuffer)
            self.lineBuffer = "" // 清空缓冲区
        }
    }
      
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
