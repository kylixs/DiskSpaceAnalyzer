# 独立测试模块使用指南

## 概述

每个测试模块都有独立的 `Package.swift` 文件，可以单独运行测试，方便开发和调试。

## 目录结构

```
tests/
├── CommonTests/
│   ├── Package.swift           # CommonTests独立包配置
│   ├── SharedConstantsTests.swift
│   ├── SharedEnumsTests.swift
│   ├── SharedStructsTests.swift
│   └── SharedUtilitiesTests.swift
├── DataModelTests/
│   ├── Package.swift           # DataModelTests独立包配置
│   └── DataModelTests.swift
├── CoordinateSystemTests/
│   ├── Package.swift           # CoordinateSystemTests独立包配置
│   └── CoordinateSystemTests.swift
├── PerformanceOptimizerTests/
│   ├── Package.swift           # PerformanceOptimizerTests独立包配置
│   └── PerformanceOptimizerTests.swift
├── ScanEngineTests/
│   ├── Package.swift           # ScanEngineTests独立包配置
│   └── ScanEngineTests.swift
├── DirectoryTreeViewTests/
│   ├── Package.swift           # DirectoryTreeViewTests独立包配置
│   └── DirectoryTreeViewTests.swift
├── TreeMapVisualizationTests/
│   ├── Package.swift           # TreeMapVisualizationTests独立包配置
│   └── TreeMapVisualizationTests.swift
├── InteractionFeedbackTests/
│   ├── Package.swift           # InteractionFeedbackTests独立包配置
│   └── InteractionFeedbackTests.swift
├── SessionManagerTests/
│   ├── Package.swift           # SessionManagerTests独立包配置
│   └── SessionManagerTests.swift
├── UserInterfaceTests/
│   ├── Package.swift           # UserInterfaceTests独立包配置
│   └── UserInterfaceTests.swift
└── README.md                   # 本文档
```

## 使用方法

### 1. 运行单个模块的测试

进入对应的测试目录，直接运行 `swift test`：

```bash
# 测试Common模块
cd tests/CommonTests
swift test

# 测试DataModel模块
cd tests/DataModelTests
swift test

# 测试ScanEngine模块
cd tests/ScanEngineTests
swift test

# 测试其他模块...
```

### 2. 编译单个模块

```bash
# 编译Common模块
cd tests/CommonTests
swift build

# 编译DataModel模块
cd tests/DataModelTests
swift build
```

### 3. 运行特定测试

```bash
# 运行特定测试类
cd tests/CommonTests
swift test --filter SharedConstantsTests

# 运行特定测试方法
cd tests/CommonTests
swift test --filter testAnimationConstants
```

### 4. 清理构建缓存

```bash
cd tests/CommonTests
swift package clean
```

## 依赖关系

每个测试模块的Package.swift都包含了必要的依赖关系：

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

## 优势

### 1. 快速测试
- 只编译和测试当前模块及其依赖
- 避免编译整个项目
- 测试反馈更快

### 2. 独立开发
- 可以专注于单个模块的开发
- 不受其他模块编译错误影响
- 便于模块化开发

### 3. 持续集成
- 可以并行运行不同模块的测试
- 更细粒度的测试报告
- 便于定位问题

### 4. 调试方便
- 减少编译时间
- 更清晰的错误信息
- 便于单步调试

## 注意事项

### 1. 路径依赖
- 所有源码路径都使用相对路径 `../../sources/ModuleName`
- 确保在正确的目录下运行命令

### 2. 依赖同步
- 如果主Package.swift中的依赖关系发生变化
- 需要同步更新对应测试模块的Package.swift

### 3. BaseTestCase使用
- 所有测试类都应该继承自Common模块的BaseTestCase
- 确保导入Common模块：`@testable import Common`

## 示例：运行CommonTests

```bash
# 进入CommonTests目录
cd /path/to/DiskSpaceAnalyzer/tests/CommonTests

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

这种独立测试包的设计大大提高了开发效率和测试体验！
