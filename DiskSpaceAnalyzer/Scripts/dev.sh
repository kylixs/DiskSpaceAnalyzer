#!/bin/bash

# DiskSpaceAnalyzer Development Script
# 开发环境管理和快速开发任务的脚本

set -e

# =============================================================================
# 配置变量
# =============================================================================

PROJECT_NAME="DiskSpaceAnalyzer"
SCHEME_NAME="DiskSpaceAnalyzer"
PROJECT_FILE="${PROJECT_NAME}.xcodeproj"

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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo "============================================================================="
    echo -e "${BLUE}$1${NC}"
    echo "============================================================================="
}

# =============================================================================
# 开发环境函数
# =============================================================================

setup_dev_environment() {
    print_header "设置开发环境"
    
    log_info "检查开发工具..."
    
    # 检查 Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode 未安装，请从 App Store 安装 Xcode"
        exit 1
    fi
    
    # 检查 Swift
    if ! command -v swift &> /dev/null; then
        log_error "Swift 编译器未找到"
        exit 1
    fi
    
    # 检查并安装有用的开发工具
    log_info "检查开发工具..."
    
    # xcpretty - 美化 xcodebuild 输出
    if ! command -v xcpretty &> /dev/null; then
        log_warning "xcpretty 未安装，建议安装以获得更好的构建输出"
        echo "安装命令: gem install xcpretty"
    else
        log_success "xcpretty 已安装"
    fi
    
    # swiftlint - Swift 代码风格检查
    if ! command -v swiftlint &> /dev/null; then
        log_warning "SwiftLint 未安装，建议安装以保持代码质量"
        echo "安装命令: brew install swiftlint"
    else
        log_success "SwiftLint 已安装"
    fi
    
    # swiftformat - Swift 代码格式化
    if ! command -v swiftformat &> /dev/null; then
        log_warning "SwiftFormat 未安装，建议安装以自动格式化代码"
        echo "安装命令: brew install swiftformat"
    else
        log_success "SwiftFormat 已安装"
    fi
    
    log_success "开发环境检查完成"
}

create_dev_directories() {
    log_info "创建开发目录结构..."
    
    # 创建开发相关目录
    mkdir -p "Development/Playground"
    mkdir -p "Development/Prototypes"
    mkdir -p "Development/Experiments"
    mkdir -p "Development/Benchmarks"
    
    log_success "开发目录结构创建完成"
}

generate_xcode_project() {
    print_header "生成/更新 Xcode 项目"
    
    log_info "检查项目文件..."
    
    if [[ -f "$PROJECT_FILE/project.pbxproj" ]]; then
        log_info "项目文件已存在"
    else
        log_info "创建新的 Xcode 项目..."
        # 这里可以添加项目创建逻辑
        log_warning "请手动创建 Xcode 项目文件"
    fi
    
    log_success "Xcode 项目检查完成"
}

# =============================================================================
# 代码质量函数
# =============================================================================

run_linter() {
    print_header "运行代码风格检查"
    
    if command -v swiftlint &> /dev/null; then
        log_info "运行 SwiftLint..."
        swiftlint lint --reporter xcode
        log_success "SwiftLint 检查完成"
    else
        log_warning "SwiftLint 未安装，跳过代码风格检查"
    fi
}

format_code() {
    print_header "格式化代码"
    
    if command -v swiftformat &> /dev/null; then
        log_info "运行 SwiftFormat..."
        swiftformat Sources/ Tests/ --verbose
        log_success "代码格式化完成"
    else
        log_warning "SwiftFormat 未安装，跳过代码格式化"
    fi
}

analyze_code() {
    print_header "静态代码分析"
    
    log_info "运行 Xcode 静态分析器..."
    
    xcodebuild analyze \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -configuration Debug \
        -destination "platform=macOS" \
        | xcpretty --report html --output "Development/analysis_report.html" 2>/dev/null || \
    xcodebuild analyze \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -configuration Debug \
        -destination "platform=macOS"
    
    log_success "静态代码分析完成"
}

# =============================================================================
# 快速开发函数
# =============================================================================

quick_build() {
    print_header "快速构建"
    
    log_info "执行快速构建（Debug 配置）..."
    
    local build_command="xcodebuild build \
        -project '$PROJECT_FILE' \
        -scheme '$SCHEME_NAME' \
        -configuration Debug \
        -destination 'platform=macOS'"
    
    if command -v xcpretty &> /dev/null; then
        eval "$build_command" | xcpretty
    else
        eval "$build_command"
    fi
    
    if [[ $? -eq 0 ]]; then
        log_success "快速构建完成"
    else
        log_error "快速构建失败"
        exit 1
    fi
}

quick_test() {
    print_header "快速测试"
    
    log_info "运行快速测试（仅单元测试）..."
    
    ./Scripts/test.sh --unit-only --no-coverage
}

run_app() {
    print_header "运行应用程序"
    
    log_info "构建并运行应用程序..."
    
    # 先进行快速构建
    quick_build
    
    # 运行应用程序
    log_info "启动应用程序..."
    
    xcodebuild run \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -configuration Debug \
        -destination "platform=macOS" 2>/dev/null || \
    open "build/Debug/${PROJECT_NAME}.app" 2>/dev/null || \
    log_warning "无法自动启动应用程序，请手动运行"
}

# =============================================================================
# 开发工具函数
# =============================================================================

create_playground() {
    print_header "创建 Swift Playground"
    
    local playground_name="${1:-Experiment}"
    local playground_path="Development/Playground/${playground_name}.playground"
    
    if [[ -d "$playground_path" ]]; then
        log_warning "Playground '$playground_name' 已存在"
        return
    fi
    
    mkdir -p "$playground_path"
    
    cat > "$playground_path/Contents.swift" << 'EOF'
import Cocoa
import Foundation

// DiskSpaceAnalyzer Playground
// 用于快速实验和原型开发

print("Hello, DiskSpaceAnalyzer Development!")

// 在这里添加你的实验代码
EOF
    
    cat > "$playground_path/contents.xcplayground" << 'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<playground version='5.0' target-platform='macos' buildActiveScheme='true'>
    <timeline fileName='timeline.xctimeline'/>
</playground>
EOF
    
    log_success "Playground '$playground_name' 创建完成: $playground_path"
    
    # 尝试在 Xcode 中打开
    if command -v open &> /dev/null; then
        open "$playground_path"
    fi
}

generate_docs() {
    print_header "生成文档"
    
    log_info "生成代码文档..."
    
    # 创建文档目录
    mkdir -p "Documentation/Generated"
    
    # 使用 xcodebuild docbuild（如果支持）
    if xcodebuild docbuild \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -destination "platform=macOS" \
        -derivedDataPath "build/DerivedData" 2>/dev/null; then
        
        log_success "文档生成完成"
        
        # 查找生成的文档
        local doc_path=$(find "build/DerivedData" -name "*.doccarchive" -type d | head -n 1)
        if [[ -n "$doc_path" ]]; then
            log_info "文档位置: $doc_path"
            # 复制到文档目录
            cp -R "$doc_path" "Documentation/Generated/"
        fi
    else
        log_warning "文档生成失败或不支持"
    fi
}

benchmark_performance() {
    print_header "性能基准测试"
    
    log_info "运行性能基准测试..."
    
    # 创建基准测试目录
    mkdir -p "Development/Benchmarks"
    
    # 运行性能测试
    ./Scripts/test.sh --performance-tests
    
    # 生成性能报告
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local report_file="Development/Benchmarks/benchmark_${timestamp}.txt"
    
    cat > "$report_file" << EOF
DiskSpaceAnalyzer 性能基准测试报告
================================

测试时间: $(date)
测试配置: Release
测试平台: macOS

性能指标:
- 启动时间: 待测量
- 扫描性能: 待测量
- 内存使用: 待测量
- CPU 使用: 待测量

详细结果请查看测试输出。
EOF
    
    log_success "性能基准测试完成，报告保存到: $report_file"
}

# =============================================================================
# 主函数
# =============================================================================

show_help() {
    echo "DiskSpaceAnalyzer 开发脚本"
    echo ""
    echo "用法: $0 <命令> [选项]"
    echo ""
    echo "命令:"
    echo "  setup           设置开发环境"
    echo "  build           快速构建项目"
    echo "  test            运行快速测试"
    echo "  run             构建并运行应用程序"
    echo "  lint            运行代码风格检查"
    echo "  format          格式化代码"
    echo "  analyze         静态代码分析"
    echo "  playground      创建 Swift Playground"
    echo "  docs            生成文档"
    echo "  benchmark       运行性能基准测试"
    echo "  clean           清理构建产物"
    echo ""
    echo "示例:"
    echo "  $0 setup                    # 设置开发环境"
    echo "  $0 build                    # 快速构建"
    echo "  $0 test                     # 运行测试"
    echo "  $0 run                      # 运行应用程序"
    echo "  $0 playground MyExperiment  # 创建名为 MyExperiment 的 Playground"
}

main() {
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        setup)
            setup_dev_environment
            create_dev_directories
            generate_xcode_project
            ;;
        build)
            quick_build
            ;;
        test)
            quick_test
            ;;
        run)
            run_app
            ;;
        lint)
            run_linter
            ;;
        format)
            format_code
            ;;
        analyze)
            analyze_code
            ;;
        playground)
            create_playground "$1"
            ;;
        docs)
            generate_docs
            ;;
        benchmark)
            benchmark_performance
            ;;
        clean)
            ./Scripts/clean.sh
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
