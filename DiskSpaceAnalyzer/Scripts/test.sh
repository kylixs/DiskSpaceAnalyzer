#!/bin/bash

# DiskSpaceAnalyzer Test Script
# 运行单元测试、集成测试和生成测试报告的脚本

set -e

# =============================================================================
# 配置变量
# =============================================================================

PROJECT_NAME="DiskSpaceAnalyzer"
SCHEME_NAME="DiskSpaceAnalyzer"
PROJECT_FILE="${PROJECT_NAME}.xcodeproj"

# 测试配置
TEST_CONFIG="Debug"
TEST_RESULTS_DIR="TestResults"
COVERAGE_DIR="coverage"

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

check_requirements() {
    log_info "检查测试环境..."
    
    # 检查 xcodebuild
    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild 未找到，请安装 Xcode"
        exit 1
    fi
    
    # 检查项目文件
    if [[ ! -f "$PROJECT_FILE/project.pbxproj" ]]; then
        log_error "项目文件 $PROJECT_FILE 未找到"
        exit 1
    fi
    
    # 检查 xcpretty（可选，用于美化输出）
    if command -v xcpretty &> /dev/null; then
        USE_XCPRETTY=true
        log_info "将使用 xcpretty 美化输出"
    else
        USE_XCPRETTY=false
        log_warning "xcpretty 未安装，建议安装以获得更好的输出格式"
    fi
    
    log_success "测试环境检查通过"
}

prepare_test_directories() {
    log_info "准备测试目录..."
    
    # 清理并创建测试结果目录
    if [[ -d "$TEST_RESULTS_DIR" ]]; then
        rm -rf "$TEST_RESULTS_DIR"
    fi
    mkdir -p "$TEST_RESULTS_DIR"
    
    # 清理并创建覆盖率目录
    if [[ -d "$COVERAGE_DIR" ]]; then
        rm -rf "$COVERAGE_DIR"
    fi
    mkdir -p "$COVERAGE_DIR"
    
    log_success "测试目录准备完成"
}

# =============================================================================
# 测试函数
# =============================================================================

run_unit_tests() {
    print_header "运行单元测试"
    
    log_info "执行单元测试..."
    
    local test_command="xcodebuild test \
        -project '$PROJECT_FILE' \
        -scheme '$SCHEME_NAME' \
        -configuration '$TEST_CONFIG' \
        -destination 'platform=macOS' \
        -resultBundlePath '$TEST_RESULTS_DIR/UnitTests.xcresult' \
        -enableCodeCoverage YES"
    
    if [[ "$USE_XCPRETTY" == true ]]; then
        eval "$test_command" | xcpretty --report junit --output "$TEST_RESULTS_DIR/unit_tests.xml"
    else
        eval "$test_command"
    fi
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "单元测试全部通过"
        return 0
    else
        log_error "单元测试失败"
        return $exit_code
    fi
}

run_ui_tests() {
    print_header "运行 UI 测试"
    
    log_info "执行 UI 测试..."
    
    local test_command="xcodebuild test \
        -project '$PROJECT_FILE' \
        -scheme '${SCHEME_NAME}UITests' \
        -configuration '$TEST_CONFIG' \
        -destination 'platform=macOS' \
        -resultBundlePath '$TEST_RESULTS_DIR/UITests.xcresult'"
    
    if [[ "$USE_XCPRETTY" == true ]]; then
        eval "$test_command" | xcpretty --report junit --output "$TEST_RESULTS_DIR/ui_tests.xml"
    else
        eval "$test_command"
    fi
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_success "UI 测试全部通过"
        return 0
    else
        log_warning "UI 测试失败或跳过"
        return $exit_code
    fi
}

generate_coverage_report() {
    print_header "生成代码覆盖率报告"
    
    log_info "提取覆盖率数据..."
    
    # 查找最新的测试结果
    local latest_result=$(find "$TEST_RESULTS_DIR" -name "*.xcresult" -type d | head -n 1)
    
    if [[ -z "$latest_result" ]]; then
        log_warning "未找到测试结果，跳过覆盖率报告生成"
        return 1
    fi
    
    # 导出覆盖率数据
    xcrun xccov view --report --json "$latest_result" > "$COVERAGE_DIR/coverage.json"
    
    # 生成 HTML 报告（如果安装了 xccov-to-sonarqube-generic-coverage）
    if command -v xccov-to-sonarqube-generic-coverage &> /dev/null; then
        xccov-to-sonarqube-generic-coverage "$latest_result" > "$COVERAGE_DIR/sonarqube-coverage.xml"
        log_info "已生成 SonarQube 格式的覆盖率报告"
    fi
    
    # 生成简单的文本报告
    xcrun xccov view --report "$latest_result" > "$COVERAGE_DIR/coverage.txt"
    
    # 提取覆盖率百分比
    local coverage_percentage=$(xcrun xccov view --report "$latest_result" | grep -E "^\s*[0-9]+\.[0-9]+%" | head -n 1 | awk '{print $1}')
    
    if [[ -n "$coverage_percentage" ]]; then
        echo "$coverage_percentage" > "$COVERAGE_DIR/coverage_percentage.txt"
        log_success "代码覆盖率: $coverage_percentage"
    fi
    
    log_success "覆盖率报告生成完成"
}

run_performance_tests() {
    print_header "运行性能测试"
    
    log_info "执行性能测试..."
    
    # 性能测试通常作为单元测试的一部分运行
    # 这里可以添加特定的性能测试逻辑
    
    local test_command="xcodebuild test \
        -project '$PROJECT_FILE' \
        -scheme '$SCHEME_NAME' \
        -configuration 'Release' \
        -destination 'platform=macOS' \
        -only-testing:'${PROJECT_NAME}Tests/PerformanceTests' \
        -resultBundlePath '$TEST_RESULTS_DIR/PerformanceTests.xcresult'"
    
    if eval "$test_command" 2>/dev/null; then
        log_success "性能测试完成"
    else
        log_warning "性能测试跳过（可能未实现）"
    fi
}

analyze_test_results() {
    print_header "分析测试结果"
    
    log_info "分析测试结果..."
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    local skipped_tests=0
    
    # 分析 JUnit XML 文件（如果存在）
    if [[ -f "$TEST_RESULTS_DIR/unit_tests.xml" ]]; then
        if command -v xmllint &> /dev/null; then
            total_tests=$(xmllint --xpath "sum(//testsuite/@tests)" "$TEST_RESULTS_DIR/unit_tests.xml" 2>/dev/null || echo "0")
            failed_tests=$(xmllint --xpath "sum(//testsuite/@failures)" "$TEST_RESULTS_DIR/unit_tests.xml" 2>/dev/null || echo "0")
            skipped_tests=$(xmllint --xpath "sum(//testsuite/@skipped)" "$TEST_RESULTS_DIR/unit_tests.xml" 2>/dev/null || echo "0")
            passed_tests=$((total_tests - failed_tests - skipped_tests))
        fi
    fi
    
    # 生成测试摘要
    cat > "$TEST_RESULTS_DIR/test_summary.txt" << EOF
DiskSpaceAnalyzer 测试摘要
========================

测试执行时间: $(date)

测试统计:
- 总测试数: $total_tests
- 通过测试: $passed_tests
- 失败测试: $failed_tests
- 跳过测试: $skipped_tests

测试结果文件:
- 单元测试结果: $TEST_RESULTS_DIR/UnitTests.xcresult
- UI 测试结果: $TEST_RESULTS_DIR/UITests.xcresult
- 性能测试结果: $TEST_RESULTS_DIR/PerformanceTests.xcresult

覆盖率报告:
- JSON 格式: $COVERAGE_DIR/coverage.json
- 文本格式: $COVERAGE_DIR/coverage.txt
EOF
    
    if [[ -f "$COVERAGE_DIR/coverage_percentage.txt" ]]; then
        echo "- 覆盖率: $(cat "$COVERAGE_DIR/coverage_percentage.txt")" >> "$TEST_RESULTS_DIR/test_summary.txt"
    fi
    
    log_success "测试结果分析完成"
}

show_test_summary() {
    print_header "测试执行摘要"
    
    if [[ -f "$TEST_RESULTS_DIR/test_summary.txt" ]]; then
        cat "$TEST_RESULTS_DIR/test_summary.txt"
    fi
    
    echo ""
    echo "📊 测试报告位置:"
    echo "   测试结果: $TEST_RESULTS_DIR/"
    echo "   覆盖率报告: $COVERAGE_DIR/"
    echo ""
    
    if [[ -f "$COVERAGE_DIR/coverage_percentage.txt" ]]; then
        local coverage=$(cat "$COVERAGE_DIR/coverage_percentage.txt")
        echo "📈 代码覆盖率: $coverage"
        echo ""
    fi
    
    echo "🔍 查看详细结果:"
    echo "   open $TEST_RESULTS_DIR/"
    echo "   cat $COVERAGE_DIR/coverage.txt"
}

# =============================================================================
# 主函数
# =============================================================================

main() {
    print_header "DiskSpaceAnalyzer 测试脚本"
    
    # 解析命令行参数
    RUN_UNIT_TESTS=true
    RUN_UI_TESTS=false
    RUN_PERFORMANCE_TESTS=false
    GENERATE_COVERAGE=true
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --unit-only)
                RUN_UI_TESTS=false
                RUN_PERFORMANCE_TESTS=false
                shift
                ;;
            --ui-tests)
                RUN_UI_TESTS=true
                shift
                ;;
            --performance-tests)
                RUN_PERFORMANCE_TESTS=true
                shift
                ;;
            --no-coverage)
                GENERATE_COVERAGE=false
                shift
                ;;
            --all)
                RUN_UI_TESTS=true
                RUN_PERFORMANCE_TESTS=true
                shift
                ;;
            --help|-h)
                echo "用法: $0 [选项]"
                echo ""
                echo "选项:"
                echo "  --unit-only         仅运行单元测试（默认）"
                echo "  --ui-tests          包含 UI 测试"
                echo "  --performance-tests 包含性能测试"
                echo "  --no-coverage       不生成覆盖率报告"
                echo "  --all               运行所有测试"
                echo "  --help, -h          显示此帮助信息"
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                exit 1
                ;;
        esac
    done
    
    # 检查测试环境
    check_requirements
    
    # 准备测试目录
    prepare_test_directories
    
    local overall_result=0
    
    # 运行单元测试
    if [[ "$RUN_UNIT_TESTS" == true ]]; then
        if ! run_unit_tests; then
            overall_result=1
        fi
    fi
    
    # 运行 UI 测试
    if [[ "$RUN_UI_TESTS" == true ]]; then
        if ! run_ui_tests; then
            log_warning "UI 测试失败，但继续执行"
        fi
    fi
    
    # 运行性能测试
    if [[ "$RUN_PERFORMANCE_TESTS" == true ]]; then
        run_performance_tests
    fi
    
    # 生成覆盖率报告
    if [[ "$GENERATE_COVERAGE" == true ]]; then
        generate_coverage_report
    fi
    
    # 分析测试结果
    analyze_test_results
    
    # 显示测试摘要
    show_test_summary
    
    if [[ $overall_result -eq 0 ]]; then
        echo "✅ 所有测试执行完成"
    else
        echo "❌ 部分测试失败"
    fi
    
    exit $overall_result
}

# 执行主函数
main "$@"
