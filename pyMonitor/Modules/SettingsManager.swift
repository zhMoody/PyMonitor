//
//  SettingsManager.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

import Combine
import Foundation
import SwiftUI

class SettingsManager: ObservableObject {

  @Published var pythonPath: String =
    UserDefaults.standard.string(forKey: "pythonPath") ?? "/usr/bin/python3"
  {
    didSet { UserDefaults.standard.set(pythonPath, forKey: "pythonPath") }
  }

  @Published var scriptFolderPath: String =
    UserDefaults.standard.string(forKey: "scriptFolderPath") ?? ""
  {
    didSet {
      UserDefaults.standard.set(scriptFolderPath, forKey: "scriptFolderPath")
      allHistory = Self.loadAllHistory(from: scriptFolderPath)
    }
  }

  // 全量历史，key 是脚本文件名
  @Published private(set) var allHistory: [String: [String]] = [:]

  init() {
    allHistory = Self.loadAllHistory(from:
      UserDefaults.standard.string(forKey: "scriptFolderPath") ?? ""
    )
  }

  // 获取指定脚本的参数历史
  func history(for scriptName: String) -> [String] {
    allHistory[scriptName] ?? []
  }

  // 添加参数到指定脚本的历史记录
  func addArgumentsToHistory(_ args: String, for scriptName: String) {
    guard !args.isEmpty else { return }
    var list = allHistory[scriptName] ?? []
    list.removeAll { $0 == args }
    list.insert(args, at: 0)
    if list.count > 50 { list = Array(list.prefix(50)) }
    allHistory[scriptName] = list
    saveAllHistory()
  }

  // MARK: - 文件读写（JSON 格式，key 为脚本文件名）

  private var historyFileURL: URL? {
    guard !scriptFolderPath.isEmpty else { return nil }
    let expanded = (scriptFolderPath as NSString).expandingTildeInPath
    return URL(fileURLWithPath: expanded).appendingPathComponent(".script_command")
  }

  private static func loadAllHistory(from folderPath: String) -> [String: [String]] {
    guard !folderPath.isEmpty else { return [:] }
    let expanded = (folderPath as NSString).expandingTildeInPath
    let url = URL(fileURLWithPath: expanded).appendingPathComponent(".script_command")
    guard let data = try? Data(contentsOf: url),
          let dict = try? JSONDecoder().decode([String: [String]].self, from: data)
    else { return [:] }
    return dict
  }

  private func saveAllHistory() {
    guard let url = historyFileURL,
          let data = try? JSONEncoder().encode(allHistory)
    else { return }
    try? data.write(to: url, options: .atomic)
  }
}
