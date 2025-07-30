import XCTest
@testable import Core

class UserInterfaceTests: XCTestCase {
    
    func testMainWindowController() {
        let controller = MainWindowController()
        XCTAssertNotNil(controller.window)
    }
    
    func testMenuBarManager() {
        let manager = MenuBarManager.shared
        XCTAssertNotNil(manager)
        
        // 测试最近路径功能
        manager.addRecentPath("/tmp/test")
        // 由于是私有属性，这里只能测试不崩溃
    }
    
    func testDialogManager() {
        let manager = DialogManager.shared
        XCTAssertNotNil(manager)
    }
    
    func testThemeManager() {
        let manager = ThemeManager.shared
        XCTAssertNotNil(manager.currentTheme)
        
        // 测试主题设置
        manager.setTheme(.light)
        XCTAssertEqual(manager.currentTheme, .light)
        
        manager.setTheme(.dark)
        XCTAssertEqual(manager.currentTheme, .dark)
    }
    
    func testSystemIntegration() {
        let integration = SystemIntegration.shared
        XCTAssertNotNil(integration)
        
        // 测试剪贴板功能
        integration.copyToClipboard("test")
        
        // 测试Dock徽章
        integration.updateDockBadge("1")
        integration.updateDockBadge(nil)
    }
    
    func testUserInterface() {
        let ui = UserInterface.shared
        let state = ui.getUIState()
        
        XCTAssertNotNil(state["isInitialized"])
        XCTAssertNotNil(state["currentTheme"])
        XCTAssertNotNil(state["isDarkMode"])
    }
    
    func testThemeEnum() {
        XCTAssertEqual(Theme.light.displayName, "浅色")
        XCTAssertEqual(Theme.dark.displayName, "深色")
        XCTAssertEqual(Theme.system.displayName, "跟随系统")
        
        XCTAssertEqual(Theme.allCases.count, 3)
    }
}
