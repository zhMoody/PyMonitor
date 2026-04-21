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
  @State private var isExpanded: Bool = false
  
  // 为了在 @ObservedObject 中使用 runner，需要一个自定义的 init
  init(script: RunningScript) {
    self.script = script
    self._runner = ObservedObject(wrappedValue: script.runner)
  }
  
  var body: some View {
    DisclosureGroup(isExpanded: $isExpanded) {
      ScrollView {
        ScrollViewReader { proxy in
          Text(runner.output.isEmpty ? "等待脚本输出..." : runner.output)
            .font(.system(.body, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .textSelection(.enabled)
            .id("output_bottom")
            .onChange(of: runner.output) { _, _ in
              withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("output_bottom", anchor: .bottom)
              }
            }
        }
      }
      .frame(height: 150)
      .background(Color(NSColor.textBackgroundColor))
      .cornerRadius(6)
      .padding(.top, 4)
    } label: {
      headerLabel
    }
    .padding(10)
    .background(Color(NSColor.windowBackgroundColor))
    .cornerRadius(8)
    .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
  }

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
        if !script.arguments.isEmpty {
          Text("参数: \(script.arguments.joined(separator: " "))")
            .font(.caption2)
            .foregroundColor(.blue)
            .lineLimit(1)
        }
        Text(statusMessage)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      // 通知开关（仅在运行中显示）
      if runner.state.isRunning {
        Toggle(isOn: $runner.notifyOnFinish) {
          Image(systemName: runner.notifyOnFinish ? "bell.fill" : "bell.slash")
        }
        .toggleStyle(.button)
        .buttonStyle(.borderless)
        .help(runner.notifyOnFinish ? "完成后通知（点击关闭）" : "完成后不通知（点击开启）")
      }

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
