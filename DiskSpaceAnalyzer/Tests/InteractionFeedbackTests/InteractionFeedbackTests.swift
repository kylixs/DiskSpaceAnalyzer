import XCTest
import AppKit
@testable import InteractionFeedback
@testable import Common

final class InteractionFeedbackTests: BaseTestCase {
    
    // MARK: - Test Properties
    
    var interactionManager: BasicInteractionManager!
    var testView: NSView!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        // 创建测试视图
        testView = NSView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        testView.wantsLayer = true
        
        // 初始化交互管理器
        interactionManager = BasicInteractionManager.shared
        interactionManager.resetState()
    }
    
    override func tearDownWithError() throws {
        interactionManager.resetState()
        interactionManager = nil
        testView = nil
    }
    
    // MARK: - Module Initialization Tests
    
    func testModuleInitialization() throws {
        // 测试模块信息
        XCTAssertEqual(InteractionFeedbackModule.version, "1.0.0")
        XCTAssertEqual(InteractionFeedbackModule.description, "交互反馈系统")
        
        // 测试初始化不会崩溃
        XCTAssertNoThrow(InteractionFeedbackModule.initialize())
        
        // 测试单例模式
        XCTAssertTrue(BasicInteractionManager.shared === interactionManager)
    }
    
    // MARK: - InteractionState Tests
    
    func testInteractionStateEnum() throws {
        let states: [InteractionState] = [.idle, .hovering, .clicking, .dragging, .contextMenu]
        
        // 验证所有状态都存在
        XCTAssertEqual(states.count, 5)
        
        // 测试状态比较
        XCTAssertEqual(InteractionState.idle, InteractionState.idle)
        XCTAssertNotEqual(InteractionState.idle, InteractionState.hovering)
    }
    
    // MARK: - InteractionEventType Tests
    
    func testInteractionEventTypeEnum() throws {
        let eventTypes: [InteractionEventType] = [
            .mouseEnter, .mouseMove, .mouseExit,
            .leftClick, .doubleClick, .rightClick,
            .dragStart, .dragMove, .dragEnd
        ]
        
        // 验证所有事件类型都存在
        XCTAssertEqual(eventTypes.count, 9)
        
        // 测试事件类型比较
        XCTAssertEqual(InteractionEventType.leftClick, InteractionEventType.leftClick)
        XCTAssertNotEqual(InteractionEventType.leftClick, InteractionEventType.rightClick)
    }
    
    // MARK: - InteractionEvent Tests
    
    func testInteractionEventCreation() throws {
        let timestamp = Date()
        let location = CGPoint(x: 100, y: 100)
        
        let event = InteractionEvent(
            type: .leftClick,
            location: location,
            timestamp: timestamp
        )
        
        XCTAssertEqual(event.type, .leftClick)
        XCTAssertEqual(event.location.x, 100)
        XCTAssertEqual(event.location.y, 100)
        XCTAssertEqual(event.timestamp, timestamp)
    }
    
    // MARK: - BasicInteractionManager Tests
    
    func testBasicInteractionManagerInitialState() throws {
        XCTAssertEqual(interactionManager.getCurrentState(), .idle)
        XCTAssertNil(interactionManager.getLastEvent())
    }
    
    func testBasicInteractionManagerHandleMouseEnter() throws {
        let event = InteractionEvent(
            type: .mouseEnter,
            location: CGPoint(x: 100, y: 100),
            timestamp: Date()
        )
        
        interactionManager.handleEvent(event)
        
        XCTAssertEqual(interactionManager.getCurrentState(), .hovering)
        XCTAssertNotNil(interactionManager.getLastEvent())
        XCTAssertEqual(interactionManager.getLastEvent()?.type, .mouseEnter)
    }
    
    func testBasicInteractionManagerHandleLeftClick() throws {
        let event = InteractionEvent(
            type: .leftClick,
            location: CGPoint(x: 150, y: 150),
            timestamp: Date()
        )
        
        interactionManager.handleEvent(event)
        
        XCTAssertEqual(interactionManager.getCurrentState(), .clicking)
        XCTAssertEqual(interactionManager.getLastEvent()?.type, .leftClick)
    }
    
    func testBasicInteractionManagerHandleDragSequence() throws {
        // 开始拖拽
        let dragStartEvent = InteractionEvent(
            type: .dragStart,
            location: CGPoint(x: 100, y: 100),
            timestamp: Date()
        )
        
        interactionManager.handleEvent(dragStartEvent)
        XCTAssertEqual(interactionManager.getCurrentState(), .dragging)
        
        // 拖拽移动
        let dragMoveEvent = InteractionEvent(
            type: .dragMove,
            location: CGPoint(x: 120, y: 120),
            timestamp: Date()
        )
        
        interactionManager.handleEvent(dragMoveEvent)
        XCTAssertEqual(interactionManager.getCurrentState(), .dragging)
        
        // 结束拖拽
        let dragEndEvent = InteractionEvent(
            type: .dragEnd,
            location: CGPoint(x: 140, y: 140),
            timestamp: Date()
        )
        
        interactionManager.handleEvent(dragEndEvent)
        XCTAssertEqual(interactionManager.getCurrentState(), .idle)
    }
    
    func testBasicInteractionManagerResetState() throws {
        // 先设置一些状态
        let event = InteractionEvent(
            type: .leftClick,
            location: CGPoint(x: 100, y: 100),
            timestamp: Date()
        )
        
        interactionManager.handleEvent(event)
        XCTAssertEqual(interactionManager.getCurrentState(), .clicking)
        XCTAssertNotNil(interactionManager.getLastEvent())
        
        // 重置状态
        interactionManager.resetState()
        
        XCTAssertEqual(interactionManager.getCurrentState(), .idle)
        XCTAssertNil(interactionManager.getLastEvent())
    }
    
    // MARK: - State Transition Tests
    
    func testStateTransitionSequence() throws {
        // 测试完整的状态转换序列
        let events = [
            InteractionEvent(type: .mouseEnter, location: CGPoint(x: 100, y: 100), timestamp: Date()),
            InteractionEvent(type: .mouseMove, location: CGPoint(x: 110, y: 110), timestamp: Date()),
            InteractionEvent(type: .leftClick, location: CGPoint(x: 110, y: 110), timestamp: Date()),
            InteractionEvent(type: .dragStart, location: CGPoint(x: 110, y: 110), timestamp: Date()),
            InteractionEvent(type: .dragMove, location: CGPoint(x: 120, y: 120), timestamp: Date()),
            InteractionEvent(type: .dragEnd, location: CGPoint(x: 130, y: 130), timestamp: Date()),
            InteractionEvent(type: .mouseExit, location: CGPoint(x: 140, y: 140), timestamp: Date())
        ]
        
        let expectedStates: [InteractionState] = [
            .hovering,    // mouseEnter
            .hovering,    // mouseMove
            .clicking,    // leftClick
            .dragging,    // dragStart
            .dragging,    // dragMove
            .idle,        // dragEnd
            .idle         // mouseExit
        ]
        
        for (index, event) in events.enumerated() {
            interactionManager.handleEvent(event)
            XCTAssertEqual(interactionManager.getCurrentState(), expectedStates[index], 
                          "状态转换失败，事件: \(event.type), 期望状态: \(expectedStates[index])")
        }
    }
    
    // MARK: - Performance Tests
    
    func testInteractionEventCreationPerformance() throws {
        measure {
            for i in 0..<1000 {
                let event = InteractionEvent(
                    type: .mouseMove,
                    location: CGPoint(x: i, y: i),
                    timestamp: Date()
                )
                XCTAssertNotNil(event)
            }
        }
    }
    
    func testInteractionManagerPerformance() throws {
        let events = (0..<1000).map { i in
            InteractionEvent(
                type: i % 2 == 0 ? .mouseMove : .leftClick,
                location: CGPoint(x: i, y: i),
                timestamp: Date()
            )
        }
        
        measure {
            for event in events {
                interactionManager.handleEvent(event)
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testInteractionEventWithExtremeValues() throws {
        let extremeLocations = [
            CGPoint(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude),
            CGPoint(x: -CGFloat.greatestFiniteMagnitude, y: -CGFloat.greatestFiniteMagnitude),
            CGPoint(x: 0, y: 0)
        ]
        
        for location in extremeLocations {
            let event = InteractionEvent(
                type: .mouseMove,
                location: location,
                timestamp: Date()
            )
            
            XCTAssertNoThrow(interactionManager.handleEvent(event))
            XCTAssertEqual(interactionManager.getLastEvent()?.location, location)
        }
    }
    
    func testRapidStateChanges() throws {
        let eventTypes: [InteractionEventType] = [
            .mouseEnter, .mouseMove, .leftClick, .dragStart, .dragEnd, .mouseExit
        ]
        
        for _ in 0..<100 {
            for eventType in eventTypes {
                let event = InteractionEvent(
                    type: eventType,
                    location: CGPoint(x: 100, y: 100),
                    timestamp: Date()
                )
                
                XCTAssertNoThrow(interactionManager.handleEvent(event))
            }
        }
        
        // 最终应该是idle状态（因为最后一个事件是mouseExit）
        XCTAssertEqual(interactionManager.getCurrentState(), .idle)
    }
    
    func testConcurrentAccess() throws {
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10
        
        for i in 0..<10 {
            DispatchQueue.global().async {
                let event = InteractionEvent(
                    type: .mouseMove,
                    location: CGPoint(x: i * 10, y: i * 10),
                    timestamp: Date()
                )
                
                self.interactionManager.handleEvent(event)
                _ = self.interactionManager.getCurrentState()
                _ = self.interactionManager.getLastEvent()
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteInteractionWorkflow() throws {
        // 模拟完整的用户交互工作流
        
        // 1. 鼠标进入
        let enterEvent = InteractionEvent(type: .mouseEnter, location: CGPoint(x: 100, y: 100), timestamp: Date())
        interactionManager.handleEvent(enterEvent)
        XCTAssertEqual(interactionManager.getCurrentState(), .hovering)
        
        // 2. 鼠标移动
        let moveEvent = InteractionEvent(type: .mouseMove, location: CGPoint(x: 110, y: 110), timestamp: Date())
        interactionManager.handleEvent(moveEvent)
        XCTAssertEqual(interactionManager.getCurrentState(), .hovering)
        
        // 3. 左键点击
        let clickEvent = InteractionEvent(type: .leftClick, location: CGPoint(x: 110, y: 110), timestamp: Date())
        interactionManager.handleEvent(clickEvent)
        XCTAssertEqual(interactionManager.getCurrentState(), .clicking)
        
        // 4. 开始拖拽
        let dragStartEvent = InteractionEvent(type: .dragStart, location: CGPoint(x: 110, y: 110), timestamp: Date())
        interactionManager.handleEvent(dragStartEvent)
        XCTAssertEqual(interactionManager.getCurrentState(), .dragging)
        
        // 5. 拖拽移动
        let dragMoveEvent = InteractionEvent(type: .dragMove, location: CGPoint(x: 150, y: 150), timestamp: Date())
        interactionManager.handleEvent(dragMoveEvent)
        XCTAssertEqual(interactionManager.getCurrentState(), .dragging)
        
        // 6. 结束拖拽
        let dragEndEvent = InteractionEvent(type: .dragEnd, location: CGPoint(x: 200, y: 200), timestamp: Date())
        interactionManager.handleEvent(dragEndEvent)
        XCTAssertEqual(interactionManager.getCurrentState(), .idle)
        
        // 7. 鼠标离开
        let exitEvent = InteractionEvent(type: .mouseExit, location: CGPoint(x: 250, y: 250), timestamp: Date())
        interactionManager.handleEvent(exitEvent)
        XCTAssertEqual(interactionManager.getCurrentState(), .idle)
        
        // 验证最后一个事件
        XCTAssertEqual(interactionManager.getLastEvent()?.type, .mouseExit)
        XCTAssertEqual(interactionManager.getLastEvent()?.location, CGPoint(x: 250, y: 250))
    }
}
