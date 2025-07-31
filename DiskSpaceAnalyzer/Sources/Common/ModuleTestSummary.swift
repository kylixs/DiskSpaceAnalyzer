import Foundation

/// 模块测试汇总工具
/// 职责：负责收集和汇总整个模块的测试结果
public class ModuleTestSummary {
    
    /// 模块测试汇总数据
    public struct ModuleSummaryData {
        public let moduleName: String
        public let testClasses: [TestClassSummary]
        public let totalTests: Int
        public let successfulTests: Int
        public let failedTests: Int
        public let successRate: Double
        
        public init(moduleName: String, testClasses: [TestClassSummary]) {
            self.moduleName = moduleName
            self.testClasses = testClasses
            self.totalTests = testClasses.reduce(0) { $0 + $1.totalTests }
            self.successfulTests = testClasses.reduce(0) { $0 + $1.successfulTests }
            self.failedTests = testClasses.reduce(0) { $0 + $1.failedTests }
            self.successRate = totalTests > 0 ? Double(successfulTests) / Double(totalTests) * 100 : 0.0
        }
    }
    
    /// 测试类汇总数据
    public struct TestClassSummary {
        public let className: String
        public let totalTests: Int
        public let successfulTests: Int
        public let failedTests: Int
        public let successRate: Double
        public let failedTestDetails: [(testName: String, error: String)]
        
        public init(className: String, results: [String: Bool], errors: [String: String]) {
            self.className = className
            self.totalTests = results.count
            self.successfulTests = results.values.filter { $0 }.count
            self.failedTests = totalTests - successfulTests
            self.successRate = totalTests > 0 ? Double(successfulTests) / Double(totalTests) * 100 : 0.0
            
            // 收集失败测试的详细信息
            var failedDetails: [(String, String)] = []
            for (testName, success) in results {
                if !success {
                    let cleanTestName = testName.replacingOccurrences(of: "-[\(className) ", with: "").replacingOccurrences(of: "]", with: "")
                    let errorMessage = errors[testName] ?? "测试失败"
                    failedDetails.append((cleanTestName, errorMessage))
                }
            }
            self.failedTestDetails = failedDetails.sorted { (first: (String, String), second: (String, String)) -> Bool in
                return first.0 < second.0
            }
        }
    }
    
    /// 从BaseTestCase收集测试结果并生成模块汇总
    /// - Parameter moduleName: 模块名称
    /// - Returns: 模块汇总数据
    public static func generateSummary(moduleName: String) -> ModuleSummaryData {
        let allResults = BaseTestCase.getAllTestResults()
        let allErrors = BaseTestCase.getAllTestErrors()
        
        var testClasses: [TestClassSummary] = []
        
        for (className, results) in allResults.sorted(by: { $0.key < $1.key }) {
            let errors = allErrors[className] ?? [:]
            let classSummary = TestClassSummary(className: className, results: results, errors: errors)
            testClasses.append(classSummary)
        }
        
        return ModuleSummaryData(moduleName: moduleName, testClasses: testClasses)
    }
    
    /// 打印模块汇总报告
    /// - Parameter summary: 模块汇总数据
    public static func printSummary(_ summary: ModuleSummaryData) {
        print("\n🏆 \(summary.moduleName) 整体测试汇总")
        print(String(repeating: "=", count: 60))
        
        // 显示每个测试类的汇总
        for testClass in summary.testClasses {
            let status = testClass.failedTests == 0 ? "✅" : "❌"
            print("\(status) \(testClass.className): \(testClass.successfulTests)/\(testClass.totalTests) (\(String(format: "%.1f%%", testClass.successRate)))")
        }
        
        print("\n📊 总计:")
        print("📈 总测试数: \(summary.totalTests)")
        print("✅ 成功: \(summary.successfulTests)")
        print("❌ 失败: \(summary.failedTests)")
        print("📊 整体成功率: \(String(format: "%.1f%%", summary.successRate))")
        
        // 只显示有失败测试的类的详细信息
        let failedClasses = summary.testClasses.filter { $0.failedTests > 0 }
        if !failedClasses.isEmpty {
            print("\n🔍 失败详情:")
            for testClass in failedClasses {
                print("  ❌ \(testClass.className): \(testClass.failedTests)/\(testClass.totalTests) 个测试失败")
                
                // 显示具体失败的测试方法
                for (testName, errorMessage) in testClass.failedTestDetails {
                    print("     • \(testName): \(errorMessage)")
                }
            }
        }
        
        print(String(repeating: "=", count: 60))
        if summary.successfulTests == summary.totalTests && summary.totalTests > 0 {
            print("🎉 \(summary.moduleName) 所有测试通过!")
        } else if summary.totalTests == 0 {
            print("⚠️  没有运行任何测试")
        } else {
            print("⚠️  \(summary.moduleName) 存在 \(summary.failedTests) 个测试失败")
        }
        print()
    }
    
    /// 生成并打印模块汇总（便捷方法）
    /// - Parameter moduleName: 模块名称
    public static func printModuleSummary(moduleName: String) {
        let summary = generateSummary(moduleName: moduleName)
        printSummary(summary)
    }
}
