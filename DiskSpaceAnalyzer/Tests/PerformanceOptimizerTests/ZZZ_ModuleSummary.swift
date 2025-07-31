import XCTest
@testable import PerformanceOptimizer
@testable import Common

final class ZZZ_ModuleSummary: BaseTestCase {
    
    func testZZZ_PrintModuleSummary() throws {
        // 这个测试会在所有其他测试完成后运行，用于输出模块测试汇总
        // ZZZ_ 前缀确保它最后执行
        
        // 等待一小段时间确保所有测试完成
        Thread.sleep(forTimeInterval: 0.5)
        
        // 输出会由BaseTestCase自动处理
        XCTAssertTrue(true, "模块测试汇总完成")
    }
}
