# Sources Directory Structure

This directory contains all the source code for the DiskSpaceAnalyzer application, organized by modules according to the project architecture.

## Module Organization

```
Sources/
├── App/                        # 应用程序入口和配置
│   ├── main.swift             # 应用程序入口点
│   ├── AppDelegate.swift      # 应用程序委托
│   └── Info.plist             # 应用程序信息配置
│
├── Core/                       # 核心基础设施模块
│   ├── DataModel/             # 数据模型模块
│   ├── PerformanceOptimizer/  # 性能优化模块
│   └── CoordinateSystem/      # 坐标系统模块
│
├── Engine/                     # 业务逻辑引擎
│   └── ScanEngine/            # 扫描引擎模块
│
├── UI/                         # 用户界面模块
│   ├── Components/            # UI组件
│   ├── Views/                 # 视图控制器
│   ├── DirectoryTreeView/     # 目录树显示模块
│   ├── TreeMapVisualization/  # TreeMap可视化模块
│   ├── InteractionFeedback/   # 交互反馈模块
│   └── UserInterface/         # 用户界面管理模块
│
├── Services/                   # 服务层
│   └── SessionManager/        # 会话管理模块
│
├── Shared/                     # 共享代码
│   ├── Extensions/            # Swift扩展
│   ├── Utilities/             # 工具类
│   ├── Constants/             # 常量定义
│   └── Protocols/             # 协议定义
│
└── Resources/                  # 嵌入式资源
    ├── Assets.xcassets        # 图像资源
    ├── Localizable.strings    # 本地化字符串
    └── Fonts/                 # 字体文件
```

## Module Dependencies

- **Core modules** (DataModel, PerformanceOptimizer, CoordinateSystem) have no dependencies
- **Engine modules** depend on Core modules
- **UI modules** depend on Core and Engine modules
- **Services modules** coordinate all other modules
- **Shared code** can be used by any module

## Coding Standards

- Follow Swift API Design Guidelines
- Use meaningful names for types, methods, and variables
- Add comprehensive documentation comments
- Maintain consistent code formatting
- Write unit tests for all public APIs
