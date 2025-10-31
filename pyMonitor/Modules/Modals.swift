//
//  Modals.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

import Combine
import Foundation
import SwiftUI

// 使用枚举来清晰地表示脚本的几种可能状态
enum ProcessState {
  case idle  // 待机
  case running  // 运行中
  case stopped(reason: String)  // 已停止（包含原因）
}
