//
//  Utilities.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

import Foundation

// 文件扫描工具
struct FileScanner {
  // 扫描指定文件夹路径下的所有 .py 文件
  // 返回一个字符串数组，包含所有找到的 Python 脚本文件名
  static func scanPythonScripts(in folderPath: String) -> [String] {
    // 如果路径为空，直接返回空数组
    guard !folderPath.isEmpty else { return [] }

    let fileManager = FileManager.default
    let expandedPath = (folderPath as NSString).expandingTildeInPath  // 展开 "~"

    do {
      // 获取文件夹下的所有内容
      let items = try fileManager.contentsOfDirectory(atPath: expandedPath)
      // 筛选出以 ".py" 结尾的文件并排序
      return items.filter { $0.hasSuffix(".py") }.sorted()
    } catch {
      // 如果读取目录失败（如权限问题、路径不存在），打印错误并返回空数组
      print("无法读取目录 '\(expandedPath)': \(error.localizedDescription)")
      return []
    }
  }
}
