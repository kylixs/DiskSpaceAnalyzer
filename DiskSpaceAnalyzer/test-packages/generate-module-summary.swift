#!/usr/bin/env swift

import Foundation

/// 独立的模块汇总生成脚本
/// 可以在不运行测试的情况下，基于测试结果文件生成模块汇总
/// 
/// 使用方法:
/// ./generate-module-summary.swift ModuleName [test-results.json]

struct TestResult {
    let className: String
    let testName: String
    let success: Bool
    let error: String?
}

struct ModuleSummary {
    let moduleName: String
    let testClasses: [TestClassSummary]
    let totalTests: Int
    let successfulTests: Int
    let failedTests: Int
    let successRate: Double
    
    init(moduleName: String, testResults: [TestResult]) {
        self.moduleName = moduleName
        
        // 按测试类分组
        let groupedResults = Dictionary(grouping: testResults) { $0.className }
        
        self.testClasses = groupedResults.map { (className, results) in
            TestClassSummary(className: className, results: results)
        }.sorted { $0.className < $1.className }
        
        self.totalTests = testResults.count
        self.successfulTests = testResults.filter { $0.success }.count
        self.failedTests = totalTests - successfulTests
        self.successRate = totalTests > 0 ? Double(successfulTests) / Double(totalTests) * 100 : 0.0
    }
}

struct TestClassSummary {
    let className: String
    let totalTests: Int
    let successfulTests: Int
    let failedTests: Int
    let successRate: Double
    let failedTestDetails: [(testName: String, error: String)]
    
    init(className: String, results: [TestResult]) {
        self.className = className
        self.totalTests = results.count
        self.successfulTests = results.filter { $0.success }.count
        self.failedTests = totalTests - successfulTests
        self.successRate = totalTests > 0 ? Double(successfulTests) / Double(totalTests) * 100 : 0.0
        
        self.failedTestDetails = results
            .filter { !$0.success }
            .map { (testName: $0.testName, error: $0.error ?? "测试失败") }
            .sorted { $0.testName < $1.testName }
    }
}

func printModuleSummary(_ summary: ModuleSummary) {
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

// 解析命令行参数
let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    print("使用方法: \(arguments[0]) <ModuleName> [test-results.json]")
    print("示例: \(arguments[0]) CommonModule test-results.json")
    exit(1)
}

let moduleName = arguments[1]
let resultsFile = arguments.count > 2 ? arguments[2] : "test-results.json"

// 模拟测试结果（实际使用时应该从文件或其他数据源读取）
let sampleResults = [
    TestResult(className: "SharedConstantsTests", testName: "testAnimationConstants", success: true, error: nil),
    TestResult(className: "SharedConstantsTests", testName: "testApplicationConstants", success: true, error: nil),
    TestResult(className: "SharedEnumsTests", testName: "testErrorSeverity", success: true, error: nil),
    TestResult(className: "SharedEnumsTests", testName: "testFileType", success: false, error: "断言失败"),
    TestResult(className: "SharedUtilitiesTests", testName: "testFormatFileSize", success: true, error: nil),
]

// 生成并打印模块汇总
let summary = ModuleSummary(moduleName: moduleName, testResults: sampleResults)
printModuleSummary(summary)

print("💡 提示: 这是一个示例脚本，实际使用时需要从测试结果文件读取数据")
print("📄 可以扩展此脚本以支持从JSON文件、数据库或其他数据源读取测试结果")
