# DiskSpaceAnalyzer Makefile
# 简化构建命令的快捷方式

.PHONY: help clean debug release test package dev watch ci all

# 默认目标
help:
	@echo "DiskSpaceAnalyzer 构建系统"
	@echo ""
	@echo "可用命令:"
	@echo "  make help      - 显示此帮助信息"
	@echo "  make clean     - 清理构建目录"
	@echo "  make debug     - 构建Debug版本"
	@echo "  make release   - 构建Release版本"
	@echo "  make test      - 运行测试"
	@echo "  make package   - 打包应用程序"
	@echo "  make dev       - 开发模式（构建并运行）"
	@echo "  make watch     - 监视文件变化并自动重新构建"
	@echo "  make ci        - 运行CI流程"
	@echo "  make all       - 完整构建流程"
	@echo ""
	@echo "示例:"
	@echo "  make debug     # 快速构建Debug版本"
	@echo "  make all       # 完整构建和打包"

# 清理构建目录
clean:
	@echo "🧹 清理构建目录..."
	@./scripts/build.sh --clean

# 构建Debug版本
debug:
	@echo "🔨 构建Debug版本..."
	@./scripts/build.sh --debug

# 构建Release版本
release:
	@echo "🚀 构建Release版本..."
	@./scripts/build.sh --release

# 运行测试
test:
	@echo "🧪 运行测试..."
	@./scripts/build.sh --test

# 打包应用程序
package: release
	@echo "📦 打包应用程序..."
	@./scripts/build.sh --package
	@./scripts/package.sh --all

# 开发模式
dev:
	@echo "👨‍💻 开发模式..."
	@./scripts/dev-build.sh --run

# 监视模式
watch:
	@echo "👀 监视文件变化..."
	@./scripts/dev-build.sh --watch

# CI流程
ci:
	@echo "🤖 运行CI流程..."
	@./scripts/ci-build.sh --full

# 完整构建流程
all:
	@echo "🎯 完整构建流程..."
	@./scripts/build.sh --all
	@./scripts/package.sh --all

# 快速运行（不重新构建）
run:
	@echo "▶️ 运行应用程序..."
	@if [ -f .build/debug/DiskSpaceAnalyzer ]; then \
		./.build/debug/DiskSpaceAnalyzer; \
	else \
		echo "❌ Debug版本不存在，请先运行 make debug"; \
	fi

# 安装到系统（可选）
install: release
	@echo "📥 安装到系统..."
	@if [ -f .build/release/DiskSpaceAnalyzer ]; then \
		sudo cp .build/release/DiskSpaceAnalyzer /usr/local/bin/; \
		echo "✅ 已安装到 /usr/local/bin/DiskSpaceAnalyzer"; \
	else \
		echo "❌ Release版本不存在，请先运行 make release"; \
	fi

# 卸载（可选）
uninstall:
	@echo "🗑️ 从系统卸载..."
	@if [ -f /usr/local/bin/DiskSpaceAnalyzer ]; then \
		sudo rm /usr/local/bin/DiskSpaceAnalyzer; \
		echo "✅ 已从系统卸载"; \
	else \
		echo "ℹ️ 系统中未找到安装的版本"; \
	fi

# 显示构建信息
info:
	@echo "📊 项目信息:"
	@echo "  项目名称: DiskSpaceAnalyzer"
	@echo "  版本: 1.0.0"
	@echo "  平台: macOS 13.0+"
	@echo "  语言: Swift 5.9+"
	@echo "  架构: 模块化设计（10个模块）"
	@echo ""
	@echo "📁 目录结构:"
	@find sources -type d -maxdepth 1 | sort
	@echo ""
	@echo "🧪 测试模块:"
	@find tests -type d -maxdepth 1 | sort
