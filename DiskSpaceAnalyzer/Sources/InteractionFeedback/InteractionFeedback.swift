import Foundation
import AppKit
import Common

// MARK: - InteractionFeedback Module
// 交互反馈模块 - 提供完整的用户交互反馈系统

/// InteractionFeedback模块信息
public struct InteractionFeedbackModule {
    public static let version = "1.0.0"
    public static let description = "交互反馈系统"
    
    public static func initialize() {
        print("🖱️ InteractionFeedback模块初始化")
        print("📋 包含: MouseInteractionHandler、TooltipManager、HighlightRenderer、ContextMenuManager")
        print("📊 版本: \(version)")
        print("✅ InteractionFeedback模块初始化完成")
    }
}

// MARK: - 交互状态

/// 交互状态枚举
public enum InteractionState {
    case idle           // 空闲状态
    case hovering       // 悬停状态
    case clicking       // 点击状态
    case dragging       // 拖拽状态
    case contextMenu    // 右键菜单状态
}

/// 交互事件类型
public enum InteractionEventType {
    case mouseEnter
    case mouseMove
    case mouseExit
    case leftClick
    case doubleClick
    case rightClick
    case dragStart
    case dragMove
    case dragEnd
}

/// 交互事件
public struct InteractionEvent {
    public let type: InteractionEventType
    public let location: CGPoint
    public let timestamp: Date
    
    public init(type: InteractionEventType, location: CGPoint, timestamp: Date) {
        self.type = type
        self.location = location
        self.timestamp = timestamp
    }
}

// MARK: - 基础交互管理器

/// 基础交互管理器 - 简化版本，用于测试
public class BasicInteractionManager {
    public static let shared = BasicInteractionManager()
    
    private var currentState: InteractionState = .idle
    private var lastEvent: InteractionEvent?
    
    private init() {}
    
    /// 处理交互事件
    public func handleEvent(_ event: InteractionEvent) {
        lastEvent = event
        
        switch event.type {
        case .mouseEnter:
            currentState = .hovering
        case .mouseMove:
            if currentState == .idle {
                currentState = .hovering
            }
        case .mouseExit:
            currentState = .idle
        case .leftClick, .doubleClick:
            currentState = .clicking
        case .rightClick:
            currentState = .contextMenu
        case .dragStart:
            currentState = .dragging
        case .dragMove:
            if currentState != .dragging {
                currentState = .dragging
            }
        case .dragEnd:
            currentState = .idle
        }
    }
    
    /// 获取当前状态
    public func getCurrentState() -> InteractionState {
        return currentState
    }
    
    /// 获取最后一个事件
    public func getLastEvent() -> InteractionEvent? {
        return lastEvent
    }
    
    /// 重置状态
    public func resetState() {
        currentState = .idle
        lastEvent = nil
    }
}
