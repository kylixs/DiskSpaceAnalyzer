#!/bin/bash

# DiskSpaceAnalyzer Clean Script
# 清理构建产物和临时文件的脚本

set -e

# =============================================================================
# 配置变量
# =============================================================================

PROJECT_NAME="DiskSpaceAnalyzer"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# 工具函数
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo "============================================================================="
    echo -e "${BLUE}$1${NC}"
    echo "============================================================================="
}

# =============================================================================
# 清理函数
# =============================================================================

clean_build_directory() {
    log_info "清理构建目录..."
    
    if [[ -d "build" ]]; then
        rm -rf build
        log_success "已删除构建目录"
    else
        log_info "构建目录不存在，跳过"
    fi
}

clean_xcode_derived_data() {
    log_info "清理 Xcode DerivedData..."
    
    # 获取项目的 DerivedData 路径
    DERIVED_DATA_PATH=$(xcodebuild -showBuildSettings -project "${PROJECT_NAME}.xcodeproj" 2>/dev/null | grep "BUILD_DIR" | head -n 1 | sed 's/.*= //' | sed 's|/Build/Products||')
    
    if [[ -n "$DERIVED_DATA_PATH" && -d "$DERIVED_DATA_PATH" ]]; then
        rm -rf "$DERIVED_DATA_PATH"
        log_success "已清理 DerivedData: $DERIVED_DATA_PATH"
    else
        log_info "未找到 DerivedData 目录"
    fi
}

clean_xcode_archives() {
    log_info "清理 Xcode Archives..."
    
    ARCHIVES_PATH="$HOME/Library/Developer/Xcode/Archives"
    
    if [[ -d "$ARCHIVES_PATH" ]]; then
        # 查找项目相关的 archives
        find "$ARCHIVES_PATH" -name "*${PROJECT_NAME}*" -type d -exec rm -rf {} + 2>/dev/null || true
        log_success "已清理项目相关的 Archives"
    else
        log_info "Archives 目录不存在"
    fi
}

clean_swift_package_cache() {
    log_info "清理 Swift Package 缓存..."
    
    if [[ -d ".build" ]]; then
        rm -rf .build
        log_success "已删除 .build 目录"
    fi
    
    # 清理全局 Swift Package 缓存
    SWIFT_CACHE_PATH="$HOME/Library/Caches/org.swift.swiftpm"
    if [[ -d "$SWIFT_CACHE_PATH" ]]; then
        rm -rf "$SWIFT_CACHE_PATH"
        log_success "已清理 Swift Package 全局缓存"
    fi
}

clean_temporary_files() {
    log_info "清理临时文件..."
    
    # 清理 .DS_Store 文件
    find . -name ".DS_Store" -delete 2>/dev/null || true
    
    # 清理临时文件
    find . -name "*.tmp" -delete 2>/dev/null || true
    find . -name "*.temp" -delete 2>/dev/null || true
    
    # 清理日志文件
    find . -name "*.log" -delete 2>/dev/null || true
    
    log_success "已清理临时文件"
}

clean_test_results() {
    log_info "清理测试结果..."
    
    # 清理测试结果目录
    if [[ -d "TestResults" ]]; then
        rm -rf TestResults
        log_success "已删除测试结果目录"
    fi
    
    # 清理覆盖率报告
    if [[ -d "coverage" ]]; then
        rm -rf coverage
        log_success "已删除覆盖率报告目录"
    fi
}

clean_documentation() {
    log_info "清理生成的文档..."
    
    if [[ -d "Documentation/Generated" ]]; then
        rm -rf Documentation/Generated
        log_success "已删除生成的文档"
    fi
}

reset_version_info() {
    log_info "重置版本信息..."
    
    # 重置 Info.plist 中的构建号为默认值
    if [[ -f "Sources/App/Info.plist" ]]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1" Sources/App/Info.plist 2>/dev/null || true
        log_success "已重置版本信息"
    fi
}

show_disk_usage() {
    log_info "显示磁盘使用情况..."
    
    echo ""
    echo "当前目录磁盘使用情况:"
    du -sh . 2>/dev/null || echo "无法获取磁盘使用情况"
    echo ""
}

# =============================================================================
# 主函数
# =============================================================================

main() {
    print_header "DiskSpaceAnalyzer 清理脚本"
    
    # 解析命令行参数
    DEEP_CLEAN=false
    RESET_VERSION=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --deep)
                DEEP_CLEAN=true
                shift
                ;;
            --reset-version)
                RESET_VERSION=true
                shift
                ;;
            --help|-h)
                echo "用法: $0 [选项]"
                echo ""
                echo "选项:"
                echo "  --deep          深度清理（包括 DerivedData 和 Archives）"
                echo "  --reset-version 重置版本信息到默认值"
                echo "  --help, -h      显示此帮助信息"
                exit 0
                ;;
            *)
                log_warning "未知选项: $1，忽略"
                shift
                ;;
        esac
    done
    
    # 显示清理前的磁盘使用情况
    show_disk_usage
    
    # 基本清理
    clean_build_directory
    clean_swift_package_cache
    clean_temporary_files
    clean_test_results
    clean_documentation
    
    # 深度清理
    if [[ "$DEEP_CLEAN" == true ]]; then
        log_info "执行深度清理..."
        clean_xcode_derived_data
        clean_xcode_archives
    fi
    
    # 重置版本信息
    if [[ "$RESET_VERSION" == true ]]; then
        reset_version_info
    fi
    
    print_header "清理完成"
    
    # 显示清理后的磁盘使用情况
    show_disk_usage
    
    echo "🧹 清理操作完成！"
    echo ""
    echo "已清理的内容:"
    echo "  ✅ 构建目录 (build/)"
    echo "  ✅ Swift Package 缓存"
    echo "  ✅ 临时文件"
    echo "  ✅ 测试结果"
    echo "  ✅ 生成的文档"
    
    if [[ "$DEEP_CLEAN" == true ]]; then
        echo "  ✅ Xcode DerivedData"
        echo "  ✅ Xcode Archives"
    fi
    
    if [[ "$RESET_VERSION" == true ]]; then
        echo "  ✅ 版本信息重置"
    fi
    
    echo ""
    echo "💡 提示:"
    echo "  - 使用 --deep 选项进行深度清理"
    echo "  - 使用 --reset-version 重置版本信息"
    echo "  - 运行 ./Scripts/build.sh 重新构建项目"
}

# 执行主函数
main "$@"
