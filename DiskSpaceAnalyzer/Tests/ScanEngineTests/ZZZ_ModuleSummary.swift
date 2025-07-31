import XCTest
@testable import ScanEngine
@testable import DataModel
@testable import PerformanceOptimizer
@testable import Common

/// 模块汇总测试类
/// 使用ZZZ前缀确保在所有其他测试类之后运行
/// 职责：调用ModuleTestSummary工具生成模块汇总报告
final class ZZZ_ModuleSummary: BaseTestCase {
    
    /// 模块汇总测试
    /// 这个测试会在最后运行，输出整个模块的测试汇总
    func testZZZ_PrintModuleSummary() throws {
        // 等待一小段时间，确保其他测试类的统计都已完成
        Thread.sleep(forTimeInterval: 0.5)
        
        // 使用ModuleTestSummary工具生成并打印模块汇总
        ModuleTestSummary.printModuleSummary(moduleName: "Common模块")
        
        // 这个测试总是成功，它的目的只是触发汇总输出
        XCTAssertTrue(true, "模块汇总完成")
    }
}
