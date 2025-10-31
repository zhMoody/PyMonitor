//
//  ScriptExecutionView.swift
//  pyStart
//
//  Created by 张浩 on 2025/10/31.
//

// MARK: - ScriptExecutionView.swift

import SwiftUI

struct ScriptExecutionView: View {
  // 让视图可以观察传入的 ProcessRunner 对象的变化并自动刷新。
  @ObservedObject var runner: ProcessRunner

  // 从环境中获取 ProcessManager，以便调用 stop/remove 方法
  @EnvironmentObject var processManager: ProcessManager

  // 传入的脚本模型，包含了ID和名称
  let script: RunningScript

  // 控制输出区域是否展开的状态
  @State private var isExpanded: Bool = true

  // 为了在 @ObservedObject 中使用 runner，需要一个自定义的 init
  init(script: RunningScript) {
    self.script = script
    self._runner = ObservedObject(wrappedValue: script.runner)
  }

  var body: some View {
    // DisclosureGroup 是实现可折叠视图的完美原生组件
    DisclosureGroup(isExpanded: $isExpanded) {
      // 折叠区域的内容：实时输出
      ScrollView {
        Text(runner.output.isEmpty ? "等待脚本输出..." : runner.output)
          .font(.system(.body, design: .monospaced))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(8)
      }
      .frame(height: 150)
      .background(Color(NSColor.textBackgroundColor))
      .cornerRadius(6)
      .padding(.top, 4)
    } label: {
      // 折叠区域的标签（始终可见的部分）
      headerLabel
    }
    .padding(10)
    .background(Color(NSColor.windowBackgroundColor))
    .cornerRadius(8)
    .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
  }

  // 标签视图，包含状态、名称和控制按钮
  private var headerLabel: some View {
    HStack {
      // 状态指示灯
      Circle()
        .frame(width: 10, height: 10)
        .foregroundColor(statusColor)

      // 脚本名称和状态信息
      VStack(alignment: .leading) {
        Text(script.scriptName)
          .font(.headline)
          .lineLimit(1)
        Text(statusMessage)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      // 根据状态显示不同的按钮
      if runner.state.isRunning {
        Button("停止", role: .destructive) {
          processManager.stopScript(id: script.id)
        }
        .buttonStyle(.bordered)
      } else {
        Button("清除", role: .cancel) {
          processManager.removeScript(id: script.id)
        }
        .buttonStyle(.bordered)
        .tint(.secondary)
      }
    }
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation {
        isExpanded.toggle()
      }
    }
  }

  // --- 动态计算属性 ---
  private var statusColor: Color {
    switch runner.state {
    case .idle: return .gray
    case .running: return .green
    case .stopped: return .red
    }
  }

  private var statusMessage: String {
    switch runner.state {
    case .idle: return "正在准备..."
    case .running: return "运行中..."
    case .stopped(let reason): return reason
    }
  }
}
