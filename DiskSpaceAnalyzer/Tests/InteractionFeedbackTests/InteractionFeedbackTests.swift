import XCTest
import AppKit
@testable import InteractionFeedback
@testable import Common
@testable import CoordinateSystem
@testable import DirectoryTreeView
@testable import TreeMapVisualization
@testable import PerformanceOptimizer

final class InteractionFeedbackTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var interactionFeedback: InteractionFeedback!
    var mouseHandler: MouseInteractionHandler!
    var tooltipManager: TooltipManager!
    var highlightRenderer: HighlightRenderer!
    var contextMenuManager: ContextMenuManager!
    var interactionCoordinator: InteractionCoordinator!
    
    var testView: NSView!
    var testTreeMapView: TreeMapView!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        interactionFeedback = InteractionFeedback.shared
        mouseHandler = MouseInteractionHandler.shared
        tooltipManager = TooltipManager.shared
        highlightRenderer = HighlightRenderer.shared
        contextMenuManager = ContextMenuManager.shared
        interactionCoordinator = InteractionCoordinator.shared
        
        // 创建测试视图
        testView = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        testTreeMapView = TreeMapView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        
        // 设置视图
        interactionFeedback.setTreeMapView(testTreeMapView)
    }
    
    override func tearDownWithError() throws {
        mouseHandler.resetState()
        tooltipManager.hideTooltip()
        highlightRenderer.removeHighlight()
        
        interactionFeedback = nil
        mouseHandler = nil
        tooltipManager = nil
        highlightRenderer = nil
        contextMenuManager = nil
        interactionCoordinator = nil
        testView = nil
        testTreeMapView = nil
    }
    
    // MARK: - InteractionFeedback Tests
    
    func testInteractionFeedbackInitialization() throws {
        XCTAssertNotNil(interactionFeedback, "InteractionFeedback应该能够正确初始化")
        XCTAssertNotNil(InteractionFeedback.shared, "InteractionFeedback.shared应该存在")
        XCTAssertTrue(InteractionFeedback.shared === interactionFeedback, "应该是单例模式")
    }
    
    func testSetTreeMapView() throws {
        let treeMapView = TreeMapView(frame: NSRect(x: 0, y: 0, width: 200, height: 200))
        
        XCTAssertNoThrow(interactionFeedback.setTreeMapView(treeMapView), "设置TreeMap视图不应该抛出异常")
    }
    
    func testGetCurrentState() throws {
        let state = interactionFeedback.getCurrentState()
        XCTAssertEqual(state, .idle, "初始状态应该是idle")
    }
    
    func testResetState() throws {
        XCTAssertNoThrow(interactionFeedback.resetState(), "重置状态不应该抛出异常")
        
        let state = interactionFeedback.getCurrentState()
        XCTAssertEqual(state, .idle, "重置后状态应该是idle")
    }
    
    // MARK: - InteractionState Tests
    
    func testInteractionStateEnum() throws {
        let states: [InteractionState] = [.idle, .hovering, .clicking, .dragging, .contextMenu]
        
        XCTAssertEqual(states.count, 5, "应该有5种交互状态")
    }
    
    // MARK: - InteractionEventType Tests
    
    func testInteractionEventTypeEnum() throws {
        let eventTypes: [InteractionEventType] = [
            .mouseEnter, .mouseMove, .mouseExit, .leftClick, .doubleClick,
            .rightClick, .dragStart, .dragMove, .dragEnd
        ]
        
        XCTAssertEqual(eventTypes.count, 9, "应该有9种交互事件类型")
    }
    
    // MARK: - InteractionEvent Tests
    
    func testInteractionEventInitialization() throws {
        let location = CGPoint(x: 100, y: 200)
        let event = InteractionEvent(type: .leftClick, location: location)
        
        XCTAssertEqual(event.type, .leftClick)
        XCTAssertEqual(event.location, location)
        XCTAssertTrue(event.timestamp.timeIntervalSinceNow < 1.0, "时间戳应该是最近的")
        XCTAssertEqual(event.modifierFlags, [])
    }
    
    func testInteractionEventWithModifiers() throws {
        let location = CGPoint(x: 50, y: 75)
        let modifiers: NSEvent.ModifierFlags = [.command, .shift]
        let event = InteractionEvent(type: .rightClick, location: location, modifierFlags: modifiers)
        
        XCTAssertEqual(event.type, .rightClick)
        XCTAssertEqual(event.location, location)
        XCTAssertEqual(event.modifierFlags, modifiers)
    }
    
    // MARK: - MouseInteractionHandler Tests
    
    func testMouseInteractionHandlerInitialization() throws {
        XCTAssertNotNil(mouseHandler, "MouseInteractionHandler应该能够正确初始化")
        XCTAssertNotNil(MouseInteractionHandler.shared, "MouseInteractionHandler.shared应该存在")
        XCTAssertTrue(MouseInteractionHandler.shared === mouseHandler, "应该是单例模式")
    }
    
    func testMouseInteractionHandlerGetCurrentState() throws {
        let state = mouseHandler.getCurrentState()
        XCTAssertEqual(state, .idle, "初始状态应该是idle")
    }
    
    func testMouseInteractionHandlerResetState() throws {
        mouseHandler.resetState()
        
        let state = mouseHandler.getCurrentState()
        XCTAssertEqual(state, .idle, "重置后状态应该是idle")
    }
    
    func testMouseInteractionHandlerCallbacks() throws {
        var eventReceived: InteractionEvent?
        var stateReceived: InteractionState?
        var oldStateReceived: InteractionState?
        var newStateReceived: InteractionState?
        
        mouseHandler.onInteractionEvent = { event, state in
            eventReceived = event
            stateReceived = state
        }
        
        mouseHandler.onStateChanged = { oldState, newState in
            oldStateReceived = oldState
            newStateReceived = newState
        }
        
        // 创建模拟鼠标事件
        let mouseEvent = NSEvent.mouseEvent(
            with: .mouseMoved,
            location: CGPoint(x: 100, y: 100),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1.0
        )
        
        if let event = mouseEvent {
            mouseHandler.handleMouseEvent(event, in: testView)
        }
        
        // 验证回调设置
        XCTAssertNotNil(mouseHandler.onInteractionEvent, "交互事件回调应该被设置")
        XCTAssertNotNil(mouseHandler.onStateChanged, "状态变化回调应该被设置")
    }
    
    // MARK: - TooltipManager Tests
    
    func testTooltipManagerInitialization() throws {
        XCTAssertNotNil(tooltipManager, "TooltipManager应该能够正确初始化")
        XCTAssertNotNil(TooltipManager.shared, "TooltipManager.shared应该存在")
        XCTAssertTrue(TooltipManager.shared === tooltipManager, "应该是单例模式")
    }
    
    func testTooltipManagerShowHide() throws {
        let location = CGPoint(x: 100, y: 100)
        let text = "测试tooltip"
        
        XCTAssertNoThrow(tooltipManager.showTooltip(text, at: location, in: testView), "显示tooltip不应该抛出异常")
        XCTAssertNoThrow(tooltipManager.hideTooltip(), "隐藏tooltip不应该抛出异常")
    }
    
    func testTooltipManagerUpdatePosition() throws {
        let location1 = CGPoint(x: 100, y: 100)
        let location2 = CGPoint(x: 150, y: 150)
        let text = "测试tooltip"
        
        tooltipManager.showTooltip(text, at: location1, in: testView)
        
        XCTAssertNoThrow(tooltipManager.updateTooltipPosition(location2, in: testView), "更新tooltip位置不应该抛出异常")
        
        tooltipManager.hideTooltip()
    }
    
    // MARK: - HighlightRenderer Tests
    
    func testHighlightRendererInitialization() throws {
        XCTAssertNotNil(highlightRenderer, "HighlightRenderer应该能够正确初始化")
        XCTAssertNotNil(HighlightRenderer.shared, "HighlightRenderer.shared应该存在")
        XCTAssertTrue(HighlightRenderer.shared === highlightRenderer, "应该是单例模式")
    }
    
    func testHighlightRendererSetRemoveHighlight() throws {
        // 创建测试矩形
        let testNode = FileNode(name: "test", path: "/test", size: 1000, isDirectory: false)
        let testRect = TreeMapRect(
            node: testNode,
            rect: CGRect(x: 10, y: 10, width: 100, height: 80),
            color: NSColor.blue
        )
        
        // 设置高亮
        XCTAssertNoThrow(highlightRenderer.setHighlight(testRect, in: testView), "设置高亮不应该抛出异常")
        
        let currentHighlight = highlightRenderer.getCurrentHighlight()
        XCTAssertNotNil(currentHighlight, "应该有当前高亮")
        XCTAssertEqual(currentHighlight?.node.id, testNode.id, "高亮节点应该匹配")
        
        // 移除高亮
        XCTAssertNoThrow(highlightRenderer.removeHighlight(), "移除高亮不应该抛出异常")
        
        let removedHighlight = highlightRenderer.getCurrentHighlight()
        XCTAssertNil(removedHighlight, "高亮应该被移除")
    }
    
    func testHighlightRendererSetNilHighlight() throws {
        XCTAssertNoThrow(highlightRenderer.setHighlight(nil, in: testView), "设置nil高亮不应该抛出异常")
        
        let currentHighlight = highlightRenderer.getCurrentHighlight()
        XCTAssertNil(currentHighlight, "nil高亮应该清除当前高亮")
    }
    
    // MARK: - ContextMenuManager Tests
    
    func testContextMenuManagerInitialization() throws {
        XCTAssertNotNil(contextMenuManager, "ContextMenuManager应该能够正确初始化")
        XCTAssertNotNil(ContextMenuManager.shared, "ContextMenuManager.shared应该存在")
        XCTAssertTrue(ContextMenuManager.shared === contextMenuManager, "应该是单例模式")
    }
    
    func testContextMenuManagerCallbacks() throws {
        var openInFinderCalled = false
        var selectInTreeCalled = false
        var copyPathCalled = false
        var showInfoCalled = false
        
        contextMenuManager.onOpenInFinder = { _ in
            openInFinderCalled = true
        }
        
        contextMenuManager.onSelectInTree = { _ in
            selectInTreeCalled = true
        }
        
        contextMenuManager.onCopyPath = { _ in
            copyPathCalled = true
        }
        
        contextMenuManager.onShowInfo = { _ in
            showInfoCalled = true
        }
        
        // 验证回调设置
        XCTAssertNotNil(contextMenuManager.onOpenInFinder, "onOpenInFinder回调应该被设置")
        XCTAssertNotNil(contextMenuManager.onSelectInTree, "onSelectInTree回调应该被设置")
        XCTAssertNotNil(contextMenuManager.onCopyPath, "onCopyPath回调应该被设置")
        XCTAssertNotNil(contextMenuManager.onShowInfo, "onShowInfo回调应该被设置")
    }
    
    // MARK: - InteractionCoordinator Tests
    
    func testInteractionCoordinatorInitialization() throws {
        XCTAssertNotNil(interactionCoordinator, "InteractionCoordinator应该能够正确初始化")
        XCTAssertNotNil(InteractionCoordinator.shared, "InteractionCoordinator.shared应该存在")
        XCTAssertTrue(InteractionCoordinator.shared === interactionCoordinator, "应该是单例模式")
    }
    
    func testInteractionCoordinatorSetViews() throws {
        let treeMapView = TreeMapView(frame: NSRect(x: 0, y: 0, width: 200, height: 200))
        let directoryTreeView = DirectoryTreeView.shared
        
        interactionCoordinator.treeMapView = treeMapView
        interactionCoordinator.directoryTreeView = directoryTreeView
        
        XCTAssertTrue(interactionCoordinator.treeMapView === treeMapView, "TreeMapView应该被设置")
        XCTAssertTrue(interactionCoordinator.directoryTreeView === directoryTreeView, "DirectoryTreeView应该被设置")
    }
    
    // MARK: - Integration Tests
    
    func testMouseEventHandling() throws {
        // 创建鼠标移动事件
        let mouseMoveEvent = NSEvent.mouseEvent(
            with: .mouseMoved,
            location: CGPoint(x: 100, y: 100),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1.0
        )
        
        if let event = mouseMoveEvent {
            XCTAssertNoThrow(interactionFeedback.handleMouseEvent(event, in: testView), "处理鼠标事件不应该抛出异常")
        }
    }
    
    func testTooltipIntegration() throws {
        let location = CGPoint(x: 100, y: 100)
        let text = "集成测试tooltip"
        
        XCTAssertNoThrow(interactionFeedback.showTooltip(text, at: location, in: testView), "显示tooltip不应该抛出异常")
        
        // 等待一小段时间
        let expectation = XCTestExpectation(description: "tooltip显示")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertNoThrow(interactionFeedback.hideTooltip(), "隐藏tooltip不应该抛出异常")
    }
    
    func testHighlightIntegration() throws {
        // 创建测试矩形
        let testNode = FileNode(name: "integration_test", path: "/test/integration", size: 2000, isDirectory: true)
        let testRect = TreeMapRect(
            node: testNode,
            rect: CGRect(x: 20, y: 20, width: 120, height: 100),
            color: NSColor.green
        )
        
        XCTAssertNoThrow(interactionFeedback.setHighlight(testRect, in: testView), "设置高亮不应该抛出异常")
        
        // 验证高亮状态
        let currentHighlight = highlightRenderer.getCurrentHighlight()
        XCTAssertNotNil(currentHighlight, "应该有当前高亮")
        XCTAssertEqual(currentHighlight?.node.id, testNode.id, "高亮节点应该匹配")
        
        // 清除高亮
        XCTAssertNoThrow(interactionFeedback.setHighlight(nil, in: testView), "清除高亮不应该抛出异常")
    }
    
    func testStateTransitions() throws {
        // 初始状态
        XCTAssertEqual(interactionFeedback.getCurrentState(), .idle, "初始状态应该是idle")
        
        // 重置状态
        interactionFeedback.resetState()
        XCTAssertEqual(interactionFeedback.getCurrentState(), .idle, "重置后状态应该是idle")
    }
    
    // MARK: - Performance Tests
    
    func testMouseEventHandlingPerformance() throws {
        let mouseEvents = (0..<100).compactMap { i in
            NSEvent.mouseEvent(
                with: .mouseMoved,
                location: CGPoint(x: i, y: i),
                modifierFlags: [],
                timestamp: TimeInterval(i),
                windowNumber: 0,
                context: nil,
                eventNumber: i,
                clickCount: 1,
                pressure: 1.0
            )
        }
        
        measure {
            for event in mouseEvents {
                interactionFeedback.handleMouseEvent(event, in: testView)
            }
        }
    }
    
    func testTooltipPerformance() throws {
        let locations = (0..<50).map { i in
            CGPoint(x: i * 10, y: i * 10)
        }
        
        measure {
            for (index, location) in locations.enumerated() {
                interactionFeedback.showTooltip("测试tooltip \(index)", at: location, in: testView)
                interactionFeedback.hideTooltip()
            }
        }
    }
    
    func testHighlightPerformance() throws {
        let testRects = (0..<50).map { i in
            let testNode = FileNode(name: "perf_test_\(i)", path: "/test/perf_\(i)", size: Int64(i * 1000), isDirectory: i % 2 == 0)
            return TreeMapRect(
                node: testNode,
                rect: CGRect(x: i * 10, y: i * 10, width: 50, height: 40),
                color: i % 2 == 0 ? NSColor.blue : NSColor.orange
            )
        }
        
        measure {
            for rect in testRects {
                interactionFeedback.setHighlight(rect, in: testView)
                interactionFeedback.setHighlight(nil, in: testView)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidMouseEvent() throws {
        // 测试处理无效的鼠标事件
        let invalidEvent = NSEvent.mouseEvent(
            with: .otherMouseDown,
            location: CGPoint(x: -100, y: -100),
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            eventNumber: 0,
            clickCount: 1,
            pressure: 1.0
        )
        
        if let event = invalidEvent {
            XCTAssertNoThrow(interactionFeedback.handleMouseEvent(event, in: testView), "处理无效鼠标事件不应该抛出异常")
        }
    }
    
    func testNilViewHandling() throws {
        let location = CGPoint(x: 100, y: 100)
        let text = "测试nil视图"
        
        // 创建一个临时视图然后设为nil
        var tempView: NSView? = NSView(frame: NSRect(x: 0, y: 0, width: 100, height: 100))
        
        // 在视图存在时显示tooltip
        if let view = tempView {
            XCTAssertNoThrow(interactionFeedback.showTooltip(text, at: location, in: view), "在有效视图中显示tooltip不应该抛出异常")
        }
        
        tempView = nil
        
        // 隐藏tooltip应该仍然工作
        XCTAssertNoThrow(interactionFeedback.hideTooltip(), "隐藏tooltip不应该抛出异常")
    }
}
