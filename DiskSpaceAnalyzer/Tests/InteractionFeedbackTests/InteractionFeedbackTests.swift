import XCTest
@testable import Core

class InteractionFeedbackTests: XCTestCase {
    
    func testMouseInteractionHandler() {
        let view = NSView()
        let handler = MouseInteractionHandler(targetView: view)
        
        XCTAssertNotNil(handler.targetView)
        XCTAssertEqual(handler.treeMapRects.count, 0)
    }
    
    func testTooltipManager() {
        let manager = TooltipManager.shared
        let stats = manager.getTooltipStatistics()
        
        XCTAssertNotNil(stats["isVisible"])
        XCTAssertNotNil(stats["showDelay"])
    }
    
    func testHighlightRenderer() {
        let renderer = HighlightRenderer.shared
        let count = renderer.getHighlightCount()
        
        XCTAssertEqual(count, 0)
    }
    
    func testContextMenuManager() {
        let manager = ContextMenuManager.shared
        let stats = manager.getMenuStatistics()
        
        XCTAssertNotNil(stats["hasCurrentMenu"])
    }
    
    func testInteractionFeedback() {
        let feedback = InteractionFeedback.shared
        let stats = feedback.getInteractionStatistics()
        
        XCTAssertNotNil(stats["mouseHandler"])
        XCTAssertNotNil(stats["tooltipManager"])
        XCTAssertNotNil(stats["highlightRenderer"])
        XCTAssertNotNil(stats["contextMenuManager"])
    }
}
