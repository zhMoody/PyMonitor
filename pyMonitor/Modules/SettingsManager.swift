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
}
