//
//  SettingsManager.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

import Combine
import Foundation
import SwiftUI

// 这是一个专门管理用户配置的 ObservableObject
class SettingsManager: ObservableObject {
  // @AppStorage 将属性与 UserDefaults 绑定，实现持久化存储

  @Published var pythonPath: String =
    UserDefaults.standard.string(forKey: "pythonPath") ?? "/usr/bin/python3"
  {
    didSet {
      UserDefaults.standard.set(pythonPath, forKey: "pythonPath")
    }
  }

  @Published var scriptFolderPath: String =
    UserDefaults.standard.string(forKey: "scriptFolderPath") ?? ""
  {
    didSet {
      UserDefaults.standard.set(scriptFolderPath, forKey: "scriptFolderPath")
    }
  }

  @Published var argumentsHistory: [String] =
    UserDefaults.standard.stringArray(forKey: "argumentsHistory") ?? []
  {
    didSet {
      UserDefaults.standard.set(argumentsHistory, forKey: "argumentsHistory")
    }
  }

  // 添加参数到历史记录（去重并限制数量）
  func addArgumentsToHistory(_ args: String) {
    guard !args.isEmpty else { return }

    // 如果已存在，先移除旧的
    argumentsHistory.removeAll { $0 == args }
    // 添加到最前面
    argumentsHistory.insert(args, at: 0)
    // 限制最多保存 20 条
    if argumentsHistory.count > 20 {
      argumentsHistory = Array(argumentsHistory.prefix(20))
    }
  }
}
