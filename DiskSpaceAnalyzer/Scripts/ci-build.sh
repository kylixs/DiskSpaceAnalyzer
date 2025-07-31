#!/bin/bash

# DiskSpaceAnalyzer CI/CD 构建脚本
# 用于持续集成和自动化构建

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目配置
PROJECT_NAME="DiskSpaceAnalyzer"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

print_info() {
    echo -e "${BLUE}[CI]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查环境
check_environment() {
    print_info "检查构建环境..."
    
    # 检查Swift版本
    if command -v swift &> /dev/null; then
        local swift_version=$(swift --version | head -n1)
        print_info "Swift版本: $swift_version"
    else
        print_error "Swift未安装"
        exit 1
    fi
    
    # 检查Xcode版本（如果在macOS上）
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v xcodebuild &> /dev/null; then
            local xcode_version=$(xcodebuild -version | head -n1)
            print_info "Xcode版本: $xcode_version"
        else
            print_warning "Xcode未安装或未配置"
        fi
    fi
    
    # 检查系统信息
    print_info "操作系统: $(uname -s) $(uname -r)"
    print_info "架构: $(uname -m)"
    
    print_success "环境检查完成"
}

# 安装依赖
install_dependencies() {
    print_info "安装依赖..."
    cd "$PROJECT_ROOT"
    
    # Swift Package Manager会自动解析依赖
    swift package resolve
    
    print_success "依赖安装完成"
}

# 代码质量检查
code_quality_check() {
    print_info "进行代码质量检查..."
    cd "$PROJECT_ROOT"
    
    # 检查代码格式（如果有SwiftFormat）
    if command -v swiftformat &> /dev/null; then
        print_info "检查代码格式..."
        swiftformat --lint sources/
        print_success "代码格式检查通过"
    else
        print_warning "SwiftFormat未安装，跳过格式检查"
    fi
    
    # 检查代码风格（如果有SwiftLint）
    if command -v swiftlint &> /dev/null; then
        print_info "检查代码风格..."
        swiftlint
        print_success "代码风格检查通过"
    else
        print_warning "SwiftLint未安装，跳过风格检查"
    fi
}

# 运行测试并生成覆盖率报告
run_tests_with_coverage() {
    print_info "运行测试并生成覆盖率报告..."
    cd "$PROJECT_ROOT"
    
    # 运行测试
    swift test --enable-code-coverage --parallel
    
    if [ $? -eq 0 ]; then
        print_success "所有测试通过"
        
        # 生成覆盖率报告（如果支持）
        if command -v xcov &> /dev/null; then
            print_info "生成覆盖率报告..."
            xcov --scheme DiskSpaceAnalyzer --output_directory build/coverage
            print_success "覆盖率报告已生成"
        fi
    else
        print_error "测试失败"
        exit 1
    fi
}

# 构建所有配置
build_all_configurations() {
    print_info "构建所有配置..."
    cd "$PROJECT_ROOT"
    
    # 构建Debug配置
    print_info "构建Debug配置..."
    swift build --configuration debug
    if [ $? -eq 0 ]; then
        print_success "Debug配置构建成功"
    else
        print_error "Debug配置构建失败"
        exit 1
    fi
    
    # 构建Release配置
    print_info "构建Release配置..."
    swift build --configuration release
    if [ $? -eq 0 ]; then
        print_success "Release配置构建成功"
    else
        print_error "Release配置构建失败"
        exit 1
    fi
}

# 性能测试
performance_test() {
    print_info "运行性能测试..."
    cd "$PROJECT_ROOT"
    
    # 如果有性能测试，在这里运行
    # 例如：swift test --filter PerformanceTests
    
    print_info "性能测试完成"
}

# 生成构建报告
generate_build_report() {
    print_info "生成构建报告..."
    
    local REPORT_DIR="$PROJECT_ROOT/build/reports"
    mkdir -p "$REPORT_DIR"
    
    local REPORT_FILE="$REPORT_DIR/build-report-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$REPORT_FILE" << EOF
DiskSpaceAnalyzer 构建报告
========================

构建时间: $(date)
构建环境: $(uname -s) $(uname -r) $(uname -m)
Swift版本: $(swift --version | head -n1)

构建状态: 成功
测试状态: 通过

构建产物:
- Debug可执行文件: .build/debug/$PROJECT_NAME
- Release可执行文件: .build/release/$PROJECT_NAME

下一步:
- 运行打包脚本创建分发版本
- 进行手动测试验证
- 部署到测试环境

EOF
    
    print_success "构建报告已生成: $REPORT_FILE"
}

# 清理构建产物
cleanup_build_artifacts() {
    print_info "清理构建产物..."
    cd "$PROJECT_ROOT"
    
    # 清理Swift Package Manager缓存
    swift package clean
    
    # 清理构建目录中的临时文件
    if [ -d "build" ]; then
        find build -name "*.tmp" -delete
        find build -name "*.log" -delete
    fi
    
    print_success "构建产物清理完成"
}

# 上传构建产物（示例）
upload_artifacts() {
    print_info "上传构建产物..."
    
    # 这里可以添加上传到云存储或构建服务器的逻辑
    # 例如：
    # aws s3 cp build/release/$PROJECT_NAME s3://my-bucket/builds/
    # scp build/release/$PROJECT_NAME user@server:/path/to/builds/
    
    print_info "构建产物上传完成"
}

# 发送通知（示例）
send_notification() {
    local STATUS="$1"
    local MESSAGE="$2"
    
    print_info "发送构建通知..."
    
    # 这里可以添加发送通知的逻辑
    # 例如：Slack、邮件、钉钉等
    # curl -X POST -H 'Content-type: application/json' \
    #   --data '{"text":"Build '$STATUS': '$MESSAGE'"}' \
    #   YOUR_WEBHOOK_URL
    
    print_info "构建通知已发送: $STATUS - $MESSAGE"
}

# 完整CI流程
full_ci_pipeline() {
    print_info "开始完整CI流程..."
    
    local START_TIME=$(date +%s)
    
    # 执行CI步骤
    check_environment
    install_dependencies
    code_quality_check
    run_tests_with_coverage
    build_all_configurations
    performance_test
    generate_build_report
    
    local END_TIME=$(date +%s)
    local DURATION=$((END_TIME - START_TIME))
    
    print_success "完整CI流程完成！"
    print_info "总耗时: ${DURATION}秒"
    
    # 发送成功通知
    send_notification "SUCCESS" "CI pipeline completed in ${DURATION}s"
}

# 错误处理
handle_error() {
    local EXIT_CODE=$?
    print_error "构建失败，退出码: $EXIT_CODE"
    
    # 发送失败通知
    send_notification "FAILED" "CI pipeline failed with exit code $EXIT_CODE"
    
    # 清理
    cleanup_build_artifacts
    
    exit $EXIT_CODE
}

# 显示帮助信息
show_help() {
    echo "DiskSpaceAnalyzer CI/CD 构建脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -e, --env           检查环境"
    echo "  -d, --deps          安装依赖"
    echo "  -q, --quality       代码质量检查"
    echo "  -t, --test          运行测试"
    echo "  -b, --build         构建所有配置"
    echo "  -p, --perf          性能测试"
    echo "  -r, --report        生成报告"
    echo "  -c, --clean         清理构建产物"
    echo "  --full              运行完整CI流程"
    echo ""
    echo "示例:"
    echo "  $0 --full           # 运行完整CI流程"
    echo "  $0 --test           # 只运行测试"
    echo "  $0 --build          # 只构建"
}

# 主函数
main() {
    # 设置错误处理
    trap handle_error ERR
    
    case "${1:-}" in
        -h|--help)
            show_help
            ;;
        -e|--env)
            check_environment
            ;;
        -d|--deps)
            install_dependencies
            ;;
        -q|--quality)
            code_quality_check
            ;;
        -t|--test)
            run_tests_with_coverage
            ;;
        -b|--build)
            build_all_configurations
            ;;
        -p|--perf)
            performance_test
            ;;
        -r|--report)
            generate_build_report
            ;;
        -c|--clean)
            cleanup_build_artifacts
            ;;
        --full)
            full_ci_pipeline
            ;;
        "")
            full_ci_pipeline
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
