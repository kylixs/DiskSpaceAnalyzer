import XCTest

/// 通用测试基类，提供测试统计和总结功能
/// 可被所有模块的测试类继承使用
class BaseTestCase: XCTestCase {
    
    // MARK: - Test Statistics
    private static var allTestResults: [String: [String: Bool]] = [:]
    private static var allTestErrors: [String: [String: String]] = [:]
    private static var testClassCounts: [String: Int] = [:]
    private static var completedTestCounts: [String: Int] = [:]
    
    /// 获取当前测试类的名称
    private var testClassName: String {
        return String(describing: type(of: self))
    }
    
    override class func setUp() {
        super.setUp()
        let className = String(describing: self)
        allTestResults[className] = [:]
        allTestErrors[className] = [:]
        
        // 计算该测试类的测试方法数量
        let testCount = self.defaultTestSuite.testCaseCount
        testClassCounts[className] = testCount
        completedTestCounts[className] = 0
    }
    
    override func setUp() {
        super.setUp()
        let className = testClassName
        if BaseTestCase.allTestResults[className] == nil {
            BaseTestCase.allTestResults[className] = [:]
        }
        if BaseTestCase.allTestErrors[className] == nil {
            BaseTestCase.allTestErrors[className] = [:]
        }
    }
    
    override func tearDown() {
        defer { super.tearDown() }
        
        // 记录当前测试的结果
        let className = testClassName
        let testName = self.name
        
        // 检查测试是否有失败的断言
        let testSucceeded = !self.testRun!.hasBeenSkipped && self.testRun!.failureCount == 0
        BaseTestCase.allTestResults[className]?[testName] = testSucceeded
        
        // 只有失败的测试才记录错误信息
        if !testSucceeded {
            BaseTestCase.allTestErrors[className]?[testName] = "测试失败"
        }
        
        // 增加已完成的测试计数
        BaseTestCase.completedTestCounts[className] = (BaseTestCase.completedTestCounts[className] ?? 0) + 1
        
        // 检查是否所有测试都已完成
        let totalTests = BaseTestCase.testClassCounts[className] ?? 0
        let completedTests = BaseTestCase.completedTestCounts[className] ?? 0
        
        if completedTests >= totalTests {
            // 所有测试完成，打印总结
            BaseTestCase.printTestSummary(for: className)
        }
    }
    
    /// 打印指定测试类的测试总结
    private static func printTestSummary(for className: String) {
        guard let testResults = allTestResults[className] else {
            return
        }
        
        let totalTests = testResults.count
        let successfulTests = testResults.values.filter { $0 }.count
        let failedTests = totalTests - successfulTests
        
        // 错误数量应该等于失败数量，不是单独计算
        let errorTests = failedTests
        
        print("\n📊 \(className) 测试总结")
        print("=" * 60)
        print("📈 总测试数: \(totalTests)")
        print("✅ 成功: \(successfulTests)")
        print("❌ 失败: \(failedTests)")
        print("⚠️  错误: \(errorTests)")
        
        if totalTests > 0 {
            let successRate = Double(successfulTests) / Double(totalTests) * 100
            print("📊 成功率: \(String(format: "%.1f%%", successRate))")
        } else {
            print("📊 成功率: 0.0%")
        }
        
        // 显示详细的测试结果
        if totalTests > 0 {
            print("\n📋 详细结果:")
            let sortedResults = testResults.sorted { $0.key < $1.key }
            for (testName, success) in sortedResults {
                let status = success ? "✅" : "❌"
                let cleanTestName = testName.replacingOccurrences(of: "-[\(className) ", with: "").replacingOccurrences(of: "]", with: "")
                print("  \(status) \(cleanTestName)")
            }
        }
        
        // 只显示失败测试的错误详情
        if failedTests > 0 {
            print("\n🔍 错误详情:")
            let failedTestResults = testResults.filter { !$0.value }
            for (testName, _) in failedTestResults {
                let cleanTestName = testName.replacingOccurrences(of: "-[\(className) ", with: "").replacingOccurrences(of: "]", with: "")
                let errorMessage = allTestErrors[className]?[testName] ?? "测试失败"
                print("  • \(cleanTestName): \(errorMessage)")
            }
        }
        
        print("=" * 60)
        if successfulTests == totalTests && totalTests > 0 {
            print("🎉 所有测试通过!")
        } else if totalTests == 0 {
            print("⚠️  没有运行任何测试")
        } else {
            print("⚠️  存在测试失败")
        }
        print()
    }
    
    /// 打印所有测试类的汇总统计
    /// 可用于模块级别的测试汇总
    static func printOverallSummary(moduleName: String = "Tests") {
        var totalTests = 0
        var totalSuccessful = 0
        var totalFailed = 0
        
        print("\n🏆 \(moduleName) 整体测试汇总")
        print("=" * 60)
        
        for (className, results) in allTestResults {
            let classTotal = results.count
            let classSuccessful = results.values.filter { $0 }.count
            let classFailed = classTotal - classSuccessful
            
            totalTests += classTotal
            totalSuccessful += classSuccessful
            totalFailed += classFailed
            
            let successRate = classTotal > 0 ? Double(classSuccessful) / Double(classTotal) * 100 : 0.0
            print("📦 \(className): \(classSuccessful)/\(classTotal) (\(String(format: "%.1f%%", successRate)))")
        }
        
        print("\n📊 总计:")
        print("📈 总测试数: \(totalTests)")
        print("✅ 成功: \(totalSuccessful)")
        print("❌ 失败: \(totalFailed)")
        print("⚠️  错误: \(totalFailed)")  // 错误数量等于失败数量
        
        if totalTests > 0 {
            let overallSuccessRate = Double(totalSuccessful) / Double(totalTests) * 100
            print("📊 整体成功率: \(String(format: "%.1f%%", overallSuccessRate))")
        }
        
        print("=" * 60)
        if totalSuccessful == totalTests && totalTests > 0 {
            print("🎉 \(moduleName) 所有测试通过!")
        } else if totalTests == 0 {
            print("⚠️  没有运行任何测试")
        } else {
            print("⚠️  \(moduleName) 存在测试失败")
        }
        print()
    }
    
    /// 清除所有测试统计数据
    /// 用于重新开始测试统计
    static func clearStatistics() {
        allTestResults.removeAll()
        allTestErrors.removeAll()
        testClassCounts.removeAll()
        completedTestCounts.removeAll()
    }
}

// MARK: - String Extension for Repeat
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}
