# 独立测试包使用指南

## 概述

`test-packages` 目录包含每个模块的独立测试包，可以单独运行测试，方便开发和调试。每个测试包都有自己的 `Package.swift` 文件和符号链接到源码和测试代码。

## 目录结构

```
test-packages/
├── CommonTests/
│   ├── Package.swift           # CommonTests独立包配置
│   ├── Sources -> ../../sources (符号链接)
│   └── Tests -> ../../tests     (符号链接)
├── DataModelTests/
│   ├── Package.swift           # DataModelTests独立包配置
│   ├── Sources -> ../../sources
│   └── Tests -> ../../tests
├── CoordinateSystemTests/
│   ├── Package.swift
│   ├── Sources -> ../../sources
│   └── Tests -> ../../tests
├── PerformanceOptimizerTests/
│   ├── Package.swift
│   ├── Sources -> ../../sources
│   └── Tests -> ../../tests
├── ScanEngineTests/
│   ├── Package.swift
│   ├── Sources -> ../../sources
│   └── Tests -> ../../tests
├── DirectoryTreeViewTests/
│   ├── Package.swift
│   ├── Sources -> ../../sources
│   └── Tests -> ../../tests
├── TreeMapVisualizationTests/
│   ├── Package.swift
│   ├── Sources -> ../../sources
│   └── Tests -> ../../tests
├── InteractionFeedbackTests/
│   ├── Package.swift
│   ├── Sources -> ../../sources
│   └── Tests -> ../../tests
├── SessionManagerTests/
│   ├── Package.swift
│   ├── Sources -> ../../sources
│   └── Tests -> ../../tests
├── UserInterfaceTests/
│   ├── Package.swift
│   ├── Sources -> ../../sources
│   └── Tests -> ../../tests
└── README.md                   # 本文档
```

## 使用方法

### 1. 运行单个模块的测试

进入对应的测试包目录，直接运行 `swift test`：

```bash
# 测试Common模块
cd test-packages/CommonTests
swift test

# 测试DataModel模块
cd test-packages/DataModelTests
swift test

# 测试ScanEngine模块
cd test-packages/ScanEngineTests
swift test

# 测试其他模块...
```

### 2. 编译单个模块

```bash
# 编译Common模块
cd test-packages/CommonTests
swift build

# 编译DataModel模块
cd test-packages/DataModelTests
swift build
```

### 3. 运行特定测试

```bash
# 运行特定测试类
cd test-packages/CommonTests
swift test --filter SharedConstantsTests

# 运行特定测试方法
cd test-packages/CommonTests
swift test --filter testAnimationConstants
```

### 4. 清理构建缓存

```bash
cd test-packages/CommonTests
swift package clean
```

## 优势

### 1. 工程目录整洁
- 测试包与源码分离
- 不在测试代码目录创建额外文件
- 保持原有项目结构清晰

### 2. 快速测试
- 只编译和测试当前模块及其依赖
- 避免编译整个项目
- 测试反馈更快

### 3. 独立开发
- 可以专注于单个模块的开发
- 不受其他模块编译错误影响
- 便于模块化开发

### 4. 持续集成友好
- 可以并行运行不同模块的测试
- 更细粒度的测试报告
- 便于定位问题

## 依赖关系

每个测试包的Package.swift都包含了必要的依赖关系：

### 基础模块
- **CommonTests**: 只依赖Common模块
- **DataModelTests**: 依赖Common + DataModel
- **CoordinateSystemTests**: 依赖Common + CoordinateSystem
- **PerformanceOptimizerTests**: 依赖Common + PerformanceOptimizer

### 中级模块
- **ScanEngineTests**: 依赖Common + DataModel + PerformanceOptimizer + ScanEngine
- **DirectoryTreeViewTests**: 依赖Common + DataModel + PerformanceOptimizer + DirectoryTreeView

### 高级模块
- **TreeMapVisualizationTests**: 依赖Common + DataModel + CoordinateSystem + PerformanceOptimizer + TreeMapVisualization
- **InteractionFeedbackTests**: 依赖多个可视化和交互模块
- **SessionManagerTests**: 依赖会话管理相关模块
- **UserInterfaceTests**: 依赖几乎所有UI相关模块

## 符号链接说明

每个测试包目录中的 `Sources` 和 `Tests` 都是符号链接：
- `Sources -> ../../sources` 指向项目的源码目录
- `Tests -> ../../tests` 指向项目的测试目录

这样设计的好处：
- 不需要复制代码
- 修改源码后立即生效
- 保持单一数据源

## BaseTestCase使用

所有测试类都应该继承自Common模块的BaseTestCase：

```swift
import XCTest
@testable import Common

final class YourTests: BaseTestCase {
    func testSomething() {
        // 测试代码...
    }
}
```

## 示例：运行CommonTests

```bash
# 进入CommonTests目录
cd test-packages/CommonTests

# 运行所有测试
swift test

# 运行特定测试类
swift test --filter SharedConstantsTests

# 查看详细输出
swift test --verbose
```

## 示例输出

```
📊 SharedConstantsTests 测试总结
============================================================
📈 总测试数: 13
✅ 成功: 13
❌ 失败: 0
⚠️  错误: 0
📊 成功率: 100.0%
============================================================
🎉 所有测试通过!
```

## 注意事项

1. **符号链接依赖**: 确保在macOS/Linux系统上运行，Windows可能需要特殊处理
2. **路径正确性**: 符号链接路径是相对的，确保目录结构正确
3. **依赖同步**: 如果主Package.swift中的依赖关系发生变化，需要同步更新对应测试包的Package.swift
4. **构建缓存**: 每个测试包有独立的 `.build` 目录，可以独立清理

这种独立测试包的设计既保持了工程目录的整洁，又提供了快速测试的便利！
