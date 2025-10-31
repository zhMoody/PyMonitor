//
//  RunningScript.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

// MARK: - RunningScript.swift

import Foundation

// 定义一个结构体来表示一个正在被监控的脚本实例
struct RunningScript: Identifiable {
  let id = UUID()  // 唯一的标识符
  let scriptName: String  // 脚本的文件名

  // 每个脚本实例都拥有自己独立的 ProcessRunner
  let runner: ProcessRunner
}
