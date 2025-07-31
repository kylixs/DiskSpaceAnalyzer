# 隐藏测试类功能使用指南

## 概述

BaseTestCase支持隐藏特定的测试类，使其不参与统计和汇总。这个功能主要用于隐藏辅助性的测试类，如模块汇总触发器、测试工具类等，避免它们干扰真正的测试统计。

## 功能特性

### ✅ 自动隐藏
- **ZZZ_ModuleSummary**：默认隐藏所有模块汇总触发器
- **模式匹配**：支持前缀、后缀、包含匹配

### ✅ 完全隐藏
- 不参与单个测试类的统计和汇总
- 不出现在模块汇总报告中
- 不影响测试总数和成功率计算

### ✅ 灵活配置
- 支持精确名称匹配
- 支持模式匹配
- 支持动态添加和移除

## 默认隐藏规则

### 精确匹配
```swift
private static var hiddenTestClasses: Set<String> = [
    "ZZZ_ModuleSummary"  // 模块汇总触发器
]
```

### 模式匹配
```swift
private static var hiddenTestClassPatterns: [String] = [
    "ZZZ_",     // 以ZZZ_开头的测试类
    "_Summary"  // 以_Summary结尾的测试类
]
```

## 使用方法

### 1. 创建会被自动隐藏的测试类

```swift
// 这些测试类会被自动隐藏
final class ZZZ_ModuleSummary: BaseTestCase { ... }      // 匹配ZZZ_前缀
final class ZZZ_TestHelper: BaseTestCase { ... }         // 匹配ZZZ_前缀
final class ModuleSummary: BaseTestCase { ... }          // 匹配_Summary后缀
final class TestSummary: BaseTestCase { ... }            // 匹配_Summary后缀
```

### 2. 手动添加隐藏的测试类

```swift
// 在测试开始前添加
BaseTestCase.addHiddenTestClass("MyHelperTests")
BaseTestCase.addHiddenTestClass("MockDataTests")
```

### 3. 添加隐藏模式

```swift
// 隐藏所有以Helper_开头的测试类
BaseTestCase.addHiddenTestClassPattern("Helper_")

// 隐藏所有以_Mock结尾的测试类
BaseTestCase.addHiddenTestClassPattern("_Mock")

// 隐藏所有包含Utility的测试类
BaseTestCase.addHiddenTestClassPattern("Utility")
```

### 4. 检查测试类是否被隐藏

```swift
let isHidden = BaseTestCase.isTestClassHidden("ZZZ_ModuleSummary")
print("ZZZ_ModuleSummary is hidden: \(isHidden)")  // true
```

## API 参考

### 精确匹配管理

```swift
// 添加需要隐藏的测试类
public static func addHiddenTestClass(_ className: String)

// 移除隐藏的测试类
public static func removeHiddenTestClass(_ className: String)
```

### 模式匹配管理

```swift
// 添加隐藏模式
public static func addHiddenTestClassPattern(_ pattern: String)

// 移除隐藏模式
public static func removeHiddenTestClassPattern(_ pattern: String)
```

### 查询方法

```swift
// 检查测试类是否被隐藏
public static func isTestClassHidden(_ className: String) -> Bool
```

## 模式匹配规则

### 前缀匹配
```swift
// 模式以_结尾，匹配前缀
BaseTestCase.addHiddenTestClassPattern("ZZZ_")

// 匹配：ZZZ_ModuleSummary, ZZZ_Helper, ZZZ_Anything
// 不匹配：TestZZZ_, MyZZZ_Test
```

### 后缀匹配
```swift
// 模式以_开头，匹配后缀
BaseTestCase.addHiddenTestClassPattern("_Summary")

// 匹配：Module_Summary, Test_Summary, Any_Summary
// 不匹配：_SummaryTest, Summary_Test
```

### 包含匹配
```swift
// 模式不以_开头或结尾，匹配包含
BaseTestCase.addHiddenTestClassPattern("Helper")

// 匹配：HelperTests, TestHelper, MyHelperClass
```

## 输出对比

### 隐藏前
```
📊 ZZZ_ModuleSummary 测试总结
============================================================
📈 总测试数: 1
✅ 成功: 1
❌ 失败: 0
📊 成功率: 100.0%
============================================================
🎉 所有测试通过!

🏆 Common模块 整体测试汇总
============================================================
✅ SharedConstantsTests: 13/13 (100.0%)
✅ SharedEnumsTests: 29/29 (100.0%)
✅ SharedStructsTests: 32/32 (100.0%)
✅ SharedUtilitiesTests: 19/19 (100.0%)
✅ ZZZ_ModuleSummary: 1/1 (100.0%)    ← 干扰统计

📊 总计:
📈 总测试数: 94    ← 包含了辅助测试
✅ 成功: 94
❌ 失败: 0
📊 整体成功率: 100.0%
============================================================
```

### 隐藏后
```
🏆 Common模块 整体测试汇总
============================================================
✅ SharedConstantsTests: 13/13 (100.0%)
✅ SharedEnumsTests: 29/29 (100.0%)
✅ SharedStructsTests: 32/32 (100.0%)
✅ SharedUtilitiesTests: 19/19 (100.0%)

📊 总计:
📈 总测试数: 93    ← 只统计真实测试
✅ 成功: 93
❌ 失败: 0
📊 整体成功率: 100.0%
============================================================
```

## 最佳实践

### 1. 命名约定

**推荐的隐藏测试类命名**：
```swift
// 汇总触发器
ZZZ_ModuleSummary
ZZZ_TestSummary

// 测试工具类
ZZZ_TestHelper
ZZZ_MockData
ZZZ_TestUtility

// 性能基准测试
ZZZ_PerformanceBenchmark
ZZZ_LoadTest
```

### 2. 模块汇总触发器

每个模块创建一个汇总触发器：
```swift
// tests/YourModuleTests/ZZZ_ModuleSummary.swift
final class ZZZ_ModuleSummary: BaseTestCase {
    func testZZZ_PrintModuleSummary() throws {
        Thread.sleep(forTimeInterval: 0.5)
        ModuleTestSummary.printModuleSummary(moduleName: "YourModule模块")
        XCTAssertTrue(true, "模块汇总完成")
    }
}
```

### 3. 测试工具类

创建辅助测试工具时使用隐藏前缀：
```swift
// tests/YourModuleTests/ZZZ_TestHelper.swift
final class ZZZ_TestHelper: BaseTestCase {
    func testZZZ_SetupTestData() throws {
        // 设置测试数据
        // 这个测试不会出现在统计中
    }
}
```

### 4. 动态配置

在特定场景下动态添加隐藏规则：
```swift
// 在测试套件开始前
override class func setUp() {
    super.setUp()
    
    // 在CI环境中隐藏性能测试
    if ProcessInfo.processInfo.environment["CI"] != nil {
        BaseTestCase.addHiddenTestClassPattern("Performance")
    }
    
    // 隐藏特定的调试测试
    BaseTestCase.addHiddenTestClass("DebugOnlyTests")
}
```

## 注意事项

### 1. 执行但不统计
- 隐藏的测试类仍然会执行
- 只是不参与统计和汇总
- 测试失败仍然会导致整体测试失败

### 2. 模式匹配优先级
- 精确匹配优先于模式匹配
- 多个模式匹配时，任意一个匹配即隐藏

### 3. 性能影响
- 隐藏功能对测试性能影响极小
- 只在测试类设置和结束时进行检查

### 4. 调试建议
- 使用`isTestClassHidden`方法检查隐藏状态
- 在开发阶段可以临时移除隐藏规则进行调试

这个隐藏功能让测试统计更加准确和清晰，避免了辅助测试类对真实测试结果的干扰！🎯
