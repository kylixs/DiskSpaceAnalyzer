import XCTest

/// 通用测试基类，提供测试统计和总结功能
/// 职责：只负责单个测试类的统计和汇总
open class BaseTestCase: XCTestCase {
    
    // MARK: - Test Statistics
    private static var allTestResults: [String: [String: Bool]] = [:]
    private static var allTestErrors: [String: [String: String]] = [:]
    private static var testClassCounts: [String: Int] = [:]
    private static var completedTestCounts: [String: Int] = [:]
    
    // MARK: - Hidden Test Classes
    /// 需要隐藏的测试类名称（不参与统计和汇总）
    private static var hiddenTestClasses: Set<String> = [
        "ZZZ_ModuleSummary"  // 模块汇总触发器，不参与统计
    ]
    
    /// 需要隐藏的测试类前缀
    private static var hiddenTestClassPrefixes: [String] = [
        "ZZZ_"      // 以ZZZ_开头的测试类（汇总触发器、辅助工具等）
    ]
    
    /// 需要隐藏的测试类后缀
    private static var hiddenTestClassSuffixes: [String] = [
        "_Summary",  // 以_Summary结尾的测试类
        "_Helper",   // 以_Helper结尾的测试类
        "_Mock"      // 以_Mock结尾的测试类
    ]
    
    /// 获取当前测试类的名称
    private var testClassName: String {
        return String(describing: type(of: self))
    }
    
    /// 检查当前测试类是否应该被隐藏
    private var isHiddenTestClass: Bool {
        return BaseTestCase.isTestClassHidden(testClassName)
    }
    
    /// 检查测试类是否被隐藏（静态方法，供外部使用）
    /// - Parameter className: 测试类名称
    /// - Returns: 是否被隐藏
    public static func isTestClassHidden(_ className: String) -> Bool {
        // 1. 检查精确匹配
        if hiddenTestClasses.contains(className) {
            return true
        }
        
        // 2. 检查前缀匹配
        for prefix in hiddenTestClassPrefixes {
            if className.hasPrefix(prefix) {
                return true
            }
        }
        
        // 3. 检查后缀匹配
        for suffix in hiddenTestClassSuffixes {
            if className.hasSuffix(suffix) {
                return true
            }
        }
        
        return false
    }
    
    override open class func setUp() {
        super.setUp()
        let className = String(describing: self)
        
        // 隐藏的测试类不参与统计
        if BaseTestCase.hiddenTestClasses.contains(className) {
            return
        }
        
        allTestResults[className] = [:]
        allTestErrors[className] = [:]
        
        // 计算该测试类的测试方法数量
        let testCount = self.defaultTestSuite.testCaseCount
        testClassCounts[className] = testCount
        completedTestCounts[className] = 0
    }
    
    override open func setUp() {
        super.setUp()
        let className = testClassName
        
        // 隐藏的测试类不参与统计
        if isHiddenTestClass {
            return
        }
        
        if BaseTestCase.allTestResults[className] == nil {
            BaseTestCase.allTestResults[className] = [:]
        }
        if BaseTestCase.allTestErrors[className] == nil {
            BaseTestCase.allTestErrors[className] = [:]
        }
    }
    
    override open func tearDown() {
        defer { super.tearDown() }
        
        let className = testClassName
        
        // 隐藏的测试类不参与统计和汇总
        if isHiddenTestClass {
            return
        }
        
        // 记录当前测试的结果
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
        
        // 注意：这里移除了单个测试类的汇总输出
        // 只收集数据，不打印单个测试类的总结
        // 模块汇总将由ZZZ_ModuleSummary触发器统一处理
    }
    
    // MARK: - Public API for Module Summary
    
    /// 获取所有测试结果（供模块汇总工具使用）
    /// 自动过滤隐藏的测试类
    public static func getAllTestResults() -> [String: [String: Bool]] {
        return allTestResults.filter { !isTestClassHidden($0.key) }
    }
    
    /// 获取所有测试错误（供模块汇总工具使用）
    /// 自动过滤隐藏的测试类
    public static func getAllTestErrors() -> [String: [String: String]] {
        return allTestErrors.filter { !hiddenTestClasses.contains($0.key) }
    }
    
    /// 添加需要隐藏的测试类
    /// - Parameter className: 测试类名称
    public static func addHiddenTestClass(_ className: String) {
        hiddenTestClasses.insert(className)
    }
    
    /// 移除隐藏的测试类
    /// - Parameter className: 测试类名称
    public static func removeHiddenTestClass(_ className: String) {
        hiddenTestClasses.remove(className)
    }
    
    /// 添加需要隐藏的测试类前缀
    /// - Parameter prefix: 前缀字符串（如"ZZZ_"）
    public static func addHiddenTestClassPrefix(_ prefix: String) {
        if !hiddenTestClassPrefixes.contains(prefix) {
            hiddenTestClassPrefixes.append(prefix)
        }
    }
    
    /// 移除隐藏的测试类前缀
    /// - Parameter prefix: 前缀字符串
    public static func removeHiddenTestClassPrefix(_ prefix: String) {
        hiddenTestClassPrefixes.removeAll { $0 == prefix }
    }
    
    /// 添加需要隐藏的测试类后缀
    /// - Parameter suffix: 后缀字符串（如"_Summary"）
    public static func addHiddenTestClassSuffix(_ suffix: String) {
        if !hiddenTestClassSuffixes.contains(suffix) {
            hiddenTestClassSuffixes.append(suffix)
        }
    }
    
    /// 移除隐藏的测试类后缀
    /// - Parameter suffix: 后缀字符串
    public static func removeHiddenTestClassSuffix(_ suffix: String) {
        hiddenTestClassSuffixes.removeAll { $0 == suffix }
    }
    
    /// 获取所有隐藏规则（用于调试）
    /// - Returns: 包含精确匹配、前缀、后缀的元组
    public static func getHiddenTestClassRules() -> (exact: Set<String>, prefixes: [String], suffixes: [String]) {
        return (hiddenTestClasses, hiddenTestClassPrefixes, hiddenTestClassSuffixes)
    }
    
    /// 清除所有测试统计数据
    /// 用于重新开始测试统计
    public static func clearStatistics() {
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
