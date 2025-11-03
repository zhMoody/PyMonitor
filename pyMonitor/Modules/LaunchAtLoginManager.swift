//
//  LaunchAtLoginManager.swift
//  pyMonitor
//
//  Created by 张浩 on 2025/11/3.
//
import Foundation
import ServiceManagement
import Combine

class LaunchAtLoginManager: ObservableObject {
    @Published var isEnabled: Bool = SMAppService.mainApp.status == .enabled {
        didSet {
            do {
                if isEnabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("🚨 无法 \(isEnabled ? "启用" : "禁用") 开机自启服务: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isEnabled.toggle()
                }
            }
        }
    }
}
