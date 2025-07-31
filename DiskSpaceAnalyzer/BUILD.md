# DiskSpaceAnalyzer 构建指南

本文档介绍如何构建和打包 DiskSpaceAnalyzer GUI 应用程序。

## 快速开始

### 使用 Makefile（推荐）

```bash
# 显示所有可用命令
make help

# 构建Debug版本并运行
make dev

# 构建Release版本
make release

# 运行测试
make test

# 完整构建和打包
make all
```

### 使用构建脚本

```bash
# 完整构建流程
./scripts/build.sh --all

# 开发模式
./scripts/dev-build.sh --run

# 打包分发
./scripts/package.sh --all
```

## 构建脚本说明

### 1. build.sh - 主构建脚本

主要的构建脚本，支持多种构建选项：

```bash
# 显示帮助
./scripts/build.sh --help

# 清理构建目录
./scripts/build.sh --clean

# 构建Debug版本
./scripts/build.sh --debug

# 构建Release版本
./scripts/build.sh --release

# 运行测试
./scripts/build.sh --test

# 创建应用程序包
./scripts/build.sh --package

# 完整构建流程
./scripts/build.sh --all
```

**功能特性：**
- 自动创建构建目录结构
- 支持Debug和Release配置
- 集成测试运行
- 创建macOS应用程序包(.app)
- 彩色输出和详细日志

### 2. dev-build.sh - 开发构建脚本

用于快速开发和测试的脚本：

```bash
# 快速构建并运行
./scripts/dev-build.sh --run

# 监视文件变化并自动重新构建
./scripts/dev-build.sh --watch

# 运行特定测试
./scripts/dev-build.sh --test CommonTests
```

**功能特性：**
- 快速构建Debug版本
- 自动运行应用程序
- 文件监视和自动重新构建
- 支持运行特定测试

### 3. package.sh - 打包脚本

用于创建分发版本的脚本：

```bash
# 创建DMG镜像
./scripts/package.sh --dmg

# 创建ZIP压缩包
./scripts/package.sh --zip

# 代码签名（需要开发者证书）
./scripts/package.sh --sign "Developer ID Application: Your Name"

# 应用程序公证（需要Apple ID）
./scripts/package.sh --notarize "your@apple.id" "app-password" "TEAM_ID"

# 创建所有分发格式
./scripts/package.sh --all
```

**功能特性：**
- 创建DMG磁盘镜像
- 创建ZIP压缩包
- 支持代码签名
- 支持应用程序公证
- 自动生成README文件

### 4. ci-build.sh - CI/CD脚本

用于持续集成的自动化构建脚本：

```bash
# 运行完整CI流程
./scripts/ci-build.sh --full

# 检查构建环境
./scripts/ci-build.sh --env

# 代码质量检查
./scripts/ci-build.sh --quality

# 运行测试并生成覆盖率报告
./scripts/ci-build.sh --test
```

**功能特性：**
- 环境检查和依赖安装
- 代码质量检查（SwiftLint、SwiftFormat）
- 测试覆盖率报告
- 性能测试
- 构建报告生成
- 错误处理和通知

## 构建产物

构建完成后，产物将位于以下位置：

```
build/
├── DiskSpaceAnalyzer_debug          # Debug可执行文件
├── DiskSpaceAnalyzer_release        # Release可执行文件
├── Export/
│   └── DiskSpaceAnalyzer.app        # macOS应用程序包
├── Distribution/
│   ├── DiskSpaceAnalyzer_v1.0.0.dmg # DMG镜像
│   └── DiskSpaceAnalyzer_v1.0.0.zip # ZIP压缩包
└── reports/
    └── build-report-*.txt           # 构建报告
```

## 系统要求

### 开发环境
- macOS 13.0 或更高版本
- Xcode 15.0 或更高版本
- Swift 5.9 或更高版本

### 可选工具
- SwiftLint：代码风格检查
- SwiftFormat：代码格式化
- fswatch：文件监视（用于开发模式）

```bash
# 安装可选工具
brew install swiftlint swiftformat fswatch
```

## 常见问题

### Q: 构建失败，提示找不到模块
A: 确保所有源文件都在正确的目录中，并且Package.swift配置正确。

### Q: 应用程序无法启动
A: 检查Info.plist配置，确保所有必需的权限描述都已添加。

### Q: 代码签名失败
A: 确保你有有效的开发者证书，并且证书标识符正确。

### Q: DMG创建失败
A: 确保有足够的磁盘空间，并且没有其他进程占用临时文件。

## 开发工作流

### 日常开发
```bash
# 1. 快速构建和测试
make dev

# 2. 运行测试
make test

# 3. 监视文件变化
make watch
```

### 发布准备
```bash
# 1. 运行完整CI流程
make ci

# 2. 构建Release版本
make release

# 3. 创建分发包
make package
```

### 持续集成
```bash
# 在CI环境中运行
./scripts/ci-build.sh --full
```

## 自定义配置

你可以通过修改脚本顶部的配置变量来自定义构建：

```bash
# 在build.sh中
PROJECT_NAME="DiskSpaceAnalyzer"
BUNDLE_ID="com.diskspaceanalyzer.app"
VERSION="1.0.0"
BUILD_NUMBER="1"
```

## 故障排除

### 清理构建环境
```bash
# 清理所有构建产物
make clean

# 清理Swift Package Manager缓存
swift package clean
swift package reset
```

### 重新生成项目
```bash
# 重新解析依赖
swift package resolve

# 重新生成Xcode项目（如果需要）
swift package generate-xcodeproj
```

## 贡献指南

在提交代码前，请确保：

1. 运行所有测试：`make test`
2. 检查代码质量：`./scripts/ci-build.sh --quality`
3. 确保构建成功：`make all`

## 许可证

本项目采用 MIT 许可证。详见 LICENSE 文件。
