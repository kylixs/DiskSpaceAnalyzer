# Sources Directory Structure

This directory contains all the source code for the DiskSpaceAnalyzer application, organized by modules according to the modular architecture design.

## Current Module Organization

```
Sources/
├── App/                        # 应用程序入口和配置
│   ├── main.swift             # 应用程序入口点
│   ├── AppDelegate.swift      # 应用程序委托
│   └── Info.plist             # 应用程序信息配置
│
├── Common/                     # 共享基础模块 (无依赖)
│   ├── Common.swift           # 模块入口和信息
│   ├── SharedConstants.swift  # 应用程序常量定义
│   ├── SharedEnums.swift      # 共享枚举类型
│   ├── SharedStructs.swift    # 共享结构体类型
│   └── SharedUtilities.swift  # 共享工具函数
│
├── DataModel/                  # 数据模型模块 (依赖: Common)
│   ├── DataModel.swift        # 模块入口和核心数据模型
│   ├── FileNode.swift         # 文件节点数据结构
│   ├── DirectoryTree.swift    # 目录树数据结构
│   ├── ScanSession.swift      # 扫描会话管理
│   └── DataPersistence.swift  # 数据持久化功能
│
├── CoordinateSystem/           # 坐标系统模块 (依赖: Common)
│   ├── CoordinateSystem.swift     # 模块入口和基础坐标系统
│   ├── CoordinateTransformer.swift # 坐标变换引擎
│   ├── HiDPIManager.swift         # 高DPI显示器支持
│   └── MultiDisplayHandler.swift  # 多显示器环境处理
│
└── PerformanceOptimizer/       # 性能优化模块 (依赖: Common)
    └── PerformanceOptimizer.swift # 性能优化工具和策略
```

## Module Architecture Overview

### 🏗️ 架构设计原则

1. **模块化设计**: 每个模块都有明确的职责和边界
2. **依赖管理**: 清晰的依赖层次，避免循环依赖
3. **可测试性**: 每个模块都有对应的单元测试
4. **可扩展性**: 易于添加新模块和功能

### 📦 模块详细说明

#### Common 模块
- **职责**: 提供所有模块共享的基础设施
- **包含**: 常量、枚举、结构体、工具函数
- **依赖**: 无 (基础模块)
- **特点**: 所有其他模块的基础依赖

#### DataModel 模块  
- **职责**: 数据模型定义和数据持久化
- **包含**: 文件节点、目录树、扫描会话、数据存储
- **依赖**: Common
- **特点**: 核心数据结构和业务逻辑

#### CoordinateSystem 模块
- **职责**: 坐标系统变换和显示器适配
- **包含**: 坐标变换、HiDPI支持、多显示器处理
- **依赖**: Common
- **特点**: 处理复杂的图形坐标计算

#### PerformanceOptimizer 模块
- **职责**: 性能监控和优化策略
- **包含**: 性能分析、内存管理、缓存策略
- **依赖**: Common
- **特点**: 提升应用程序运行效率

## Module Dependencies Graph

```
┌─────────────┐
│     App     │ (主应用程序)
└─────┬───────┘
      │
      ▼
┌─────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ DataModel   │    │ CoordinateSystem │    │PerformanceOpt. │
└─────┬───────┘    └────────┬─────────┘    └────────┬────────┘
      │                     │                       │
      │                     │                       │
      └─────────────────────┼───────────────────────┘
                            ▼
                    ┌─────────────┐
                    │   Common    │ (基础模块)
                    └─────────────┘
```

## Development Guidelines

### 🔧 编码规范

- 遵循 Swift API 设计指南
- 使用有意义的类型、方法和变量名称
- 添加完整的文档注释
- 保持一致的代码格式
- 为所有公共API编写单元测试

### 📝 模块开发规则

1. **单一职责**: 每个模块只负责一个明确的功能领域
2. **接口清晰**: 模块间通过明确定义的接口通信
3. **向下依赖**: 只能依赖层次更低的模块
4. **测试覆盖**: 每个模块都必须有对应的测试套件

### 🧪 测试结构

```
Tests/
├── CommonTests/                # Common模块测试
├── DataModelTests/             # DataModel模块测试
├── CoordinateSystemTests/      # CoordinateSystem模块测试
└── PerformanceOptimizerTests/  # PerformanceOptimizer模块测试
```

## Build and Test

### 编译项目
```bash
swift build
```

### 运行测试
```bash
swift test
```

### 运行应用程序
```bash
swift run DiskSpaceAnalyzer
```

## Future Expansion

### 计划中的模块

- **ScanEngine**: 文件系统扫描引擎
- **UserInterface**: 用户界面管理
- **TreeMapVisualization**: TreeMap可视化
- **InteractionFeedback**: 用户交互反馈
- **SessionManager**: 会话管理服务

### 扩展指南

1. 新模块应放在适当的目录中
2. 更新Package.swift添加新的target
3. 创建对应的测试模块
4. 更新此README文档
5. 确保遵循现有的依赖关系规则

---

*最后更新: 2024年7月31日*  
*架构版本: v2.0 - 模块化重构*
