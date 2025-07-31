#!/bin/bash

# DiskSpaceAnalyzer 开发构建脚本
# 用于快速开发和测试

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 项目配置
PROJECT_NAME="DiskSpaceAnalyzer"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

print_info() {
    echo -e "${BLUE}[DEV]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 快速构建和运行
quick_build_and_run() {
    print_info "快速构建Debug版本..."
    cd "$PROJECT_ROOT"
    
    # 构建
    swift build --configuration debug
    
    if [ $? -eq 0 ]; then
        print_success "构建成功！"
        
        # 运行程序
        print_info "启动应用程序..."
        ./.build/debug/$PROJECT_NAME
    else
        print_error "构建失败"
        exit 1
    fi
}

# 监视文件变化并自动重新构建
watch_and_build() {
    print_info "启动文件监视模式..."
    print_warning "需要安装 fswatch: brew install fswatch"
    
    if ! command -v fswatch &> /dev/null; then
        print_warning "fswatch 未安装，请运行: brew install fswatch"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
    
    # 初始构建
    swift build --configuration debug
    
    # 监视源文件变化
    fswatch -o sources/ | while read f; do
        print_info "检测到文件变化，重新构建..."
        swift build --configuration debug
        if [ $? -eq 0 ]; then
            print_success "重新构建完成"
        fi
    done
}

# 运行特定测试
run_specific_test() {
    local test_name="$1"
    if [ -z "$test_name" ]; then
        print_info "运行所有测试..."
        swift test
    else
        print_info "运行测试: $test_name"
        swift test --filter "$test_name"
    fi
}

# 显示帮助
show_help() {
    echo "DiskSpaceAnalyzer 开发构建脚本"
    echo ""
    echo "用法: $0 [选项] [测试名称]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -r, --run           快速构建并运行"
    echo "  -w, --watch         监视文件变化并自动重新构建"
    echo "  -t, --test [名称]   运行测试（可选指定测试名称）"
    echo ""
    echo "示例:"
    echo "  $0 --run                    # 快速构建并运行"
    echo "  $0 --watch                  # 监视模式"
    echo "  $0 --test                   # 运行所有测试"
    echo "  $0 --test CommonTests       # 运行特定测试"
}

# 主函数
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            ;;
        -r|--run)
            quick_build_and_run
            ;;
        -w|--watch)
            watch_and_build
            ;;
        -t|--test)
            run_specific_test "$2"
            ;;
        "")
            quick_build_and_run
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
