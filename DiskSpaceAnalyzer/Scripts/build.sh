#!/bin/bash

# DiskSpaceAnalyzer Build Script
# 支持重复构建和生成可执行文件的完整构建脚本

set -e  # 遇到错误立即退出

# =============================================================================
# 配置变量
# =============================================================================

PROJECT_NAME="DiskSpaceAnalyzer"
SCHEME_NAME="DiskSpaceAnalyzer"
WORKSPACE_NAME="${PROJECT_NAME}.xcworkspace"
PROJECT_FILE="${PROJECT_NAME}.xcodeproj"

# 构建配置
BUILD_CONFIG="Release"
ARCHIVE_PATH="build/archives"
EXPORT_PATH="build/exports"
APP_PATH="build/app"
DMG_PATH="build/dmg"

# 版本信息
VERSION=$(grep -A1 "CFBundleShortVersionString" Sources/App/Info.plist | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "1.0.0")
BUILD_NUMBER=$(date +%Y%m%d%H%M%S)

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
    log_info "检查构建环境..."
    
    # 检查 Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "xcodebuild 未找到，请安装 Xcode"
        exit 1
    fi
    
    # 检查 Swift
    if ! command -v swift &> /dev/null; then
        log_error "Swift 编译器未找到"
        exit 1
    fi
    
    # 检查项目文件
    if [[ ! -f "$PROJECT_FILE/project.pbxproj" ]]; then
        log_error "项目文件 $PROJECT_FILE 未找到"
        exit 1
    fi
    
    log_success "构建环境检查通过"
}

clean_build_directory() {
    log_info "清理构建目录..."
    
    if [[ -d "build" ]]; then
        rm -rf build
        log_info "已删除旧的构建目录"
    fi
    
    # 创建构建目录结构
    mkdir -p "$ARCHIVE_PATH"
    mkdir -p "$EXPORT_PATH"
    mkdir -p "$APP_PATH"
    mkdir -p "$DMG_PATH"
    
    log_success "构建目录已准备完成"
}

update_version_info() {
    log_info "更新版本信息..."
    
    # 更新 Info.plist 中的构建号
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" Sources/App/Info.plist
    
    log_info "版本: $VERSION, 构建号: $BUILD_NUMBER"
    log_success "版本信息更新完成"
}

# =============================================================================
# 构建函数
# =============================================================================

build_project() {
    print_header "开始构建项目"
    
    log_info "执行 xcodebuild archive..."
    
    xcodebuild archive \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -configuration "$BUILD_CONFIG" \
        -archivePath "$ARCHIVE_PATH/$PROJECT_NAME.xcarchive" \
        -destination "generic/platform=macOS" \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO
    
    if [[ $? -eq 0 ]]; then
        log_success "项目构建完成"
    else
        log_error "项目构建失败"
        exit 1
    fi
}

export_app() {
    print_header "导出应用程序"
    
    log_info "创建导出配置文件..."
    
    # 创建导出配置 plist
    cat > build/ExportOptions.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>destination</key>
    <string>export</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF
    
    log_info "导出应用程序..."
    
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH/$PROJECT_NAME.xcarchive" \
        -exportPath "$EXPORT_PATH" \
        -exportOptionsPlist build/ExportOptions.plist
    
    if [[ $? -eq 0 ]]; then
        # 复制 .app 文件到指定目录
        if [[ -d "$EXPORT_PATH/$PROJECT_NAME.app" ]]; then
            cp -R "$EXPORT_PATH/$PROJECT_NAME.app" "$APP_PATH/"
            log_success "应用程序导出完成: $APP_PATH/$PROJECT_NAME.app"
        else
            log_error "导出的应用程序未找到"
            exit 1
        fi
    else
        log_error "应用程序导出失败"
        exit 1
    fi
}

create_dmg() {
    print_header "创建 DMG 安装包"
    
    log_info "准备 DMG 内容..."
    
    DMG_TEMP_DIR="build/dmg_temp"
    mkdir -p "$DMG_TEMP_DIR"
    
    # 复制应用程序到临时目录
    cp -R "$APP_PATH/$PROJECT_NAME.app" "$DMG_TEMP_DIR/"
    
    # 创建 Applications 链接
    ln -s /Applications "$DMG_TEMP_DIR/Applications"
    
    # 创建 DMG
    DMG_NAME="${PROJECT_NAME}-${VERSION}-${BUILD_NUMBER}.dmg"
    
    log_info "创建 DMG 文件: $DMG_NAME"
    
    hdiutil create -volname "$PROJECT_NAME" \
        -srcfolder "$DMG_TEMP_DIR" \
        -ov -format UDZO \
        "$DMG_PATH/$DMG_NAME"
    
    if [[ $? -eq 0 ]]; then
        # 清理临时目录
        rm -rf "$DMG_TEMP_DIR"
        log_success "DMG 创建完成: $DMG_PATH/$DMG_NAME"
    else
        log_error "DMG 创建失败"
        exit 1
    fi
}

run_tests() {
    print_header "运行单元测试"
    
    log_info "执行单元测试..."
    
    xcodebuild test \
        -project "$PROJECT_FILE" \
        -scheme "$SCHEME_NAME" \
        -configuration Debug \
        -destination "platform=macOS"
    
    if [[ $? -eq 0 ]]; then
        log_success "所有测试通过"
    else
        log_warning "部分测试失败，但继续构建过程"
    fi
}

generate_build_info() {
    print_header "生成构建信息"
    
    BUILD_INFO_FILE="build/build_info.txt"
    
    cat > "$BUILD_INFO_FILE" << EOF
DiskSpaceAnalyzer 构建信息
========================

项目名称: $PROJECT_NAME
版本号: $VERSION
构建号: $BUILD_NUMBER
构建配置: $BUILD_CONFIG
构建时间: $(date)
构建主机: $(hostname)
Xcode 版本: $(xcodebuild -version | head -n 1)
Swift 版本: $(swift --version | head -n 1)

构建产物:
- 应用程序: $APP_PATH/$PROJECT_NAME.app
- DMG 安装包: $DMG_PATH/${PROJECT_NAME}-${VERSION}-${BUILD_NUMBER}.dmg

文件大小:
- 应用程序: $(du -h "$APP_PATH/$PROJECT_NAME.app" | cut -f1)
- DMG 文件: $(du -h "$DMG_PATH"/*.dmg | cut -f1)

EOF
    
    log_success "构建信息已保存到: $BUILD_INFO_FILE"
}

show_summary() {
    print_header "构建完成摘要"
    
    echo "🎉 构建成功完成！"
    echo ""
    echo "📦 构建产物:"
    echo "   应用程序: $APP_PATH/$PROJECT_NAME.app"
    echo "   DMG 安装包: $DMG_PATH/${PROJECT_NAME}-${VERSION}-${BUILD_NUMBER}.dmg"
    echo ""
    echo "📊 文件信息:"
    if [[ -d "$APP_PATH/$PROJECT_NAME.app" ]]; then
        echo "   应用程序大小: $(du -h "$APP_PATH/$PROJECT_NAME.app" | cut -f1)"
    fi
    if [[ -f "$DMG_PATH"/*.dmg ]]; then
        echo "   DMG 文件大小: $(du -h "$DMG_PATH"/*.dmg | cut -f1)"
    fi
    echo ""
    echo "🚀 可以通过以下方式运行应用程序:"
    echo "   open $APP_PATH/$PROJECT_NAME.app"
    echo ""
    echo "💿 可以通过以下方式安装 DMG:"
    echo "   open $DMG_PATH/${PROJECT_NAME}-${VERSION}-${BUILD_NUMBER}.dmg"
}

# =============================================================================
# 主函数
# =============================================================================

main() {
    print_header "DiskSpaceAnalyzer 构建脚本"
    
    # 解析命令行参数
    SKIP_TESTS=false
    SKIP_DMG=false
    CLEAN_ONLY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-tests)
                SKIP_TESTS=true
                shift
                ;;
            --skip-dmg)
                SKIP_DMG=true
                shift
                ;;
            --clean-only)
                CLEAN_ONLY=true
                shift
                ;;
            --help|-h)
                echo "用法: $0 [选项]"
                echo ""
                echo "选项:"
                echo "  --skip-tests    跳过单元测试"
                echo "  --skip-dmg      跳过 DMG 创建"
                echo "  --clean-only    仅清理构建目录"
                echo "  --help, -h      显示此帮助信息"
                exit 0
                ;;
            *)
                log_error "未知选项: $1"
                exit 1
                ;;
        esac
    done
    
    # 检查构建环境
    check_requirements
    
    # 清理构建目录
    clean_build_directory
    
    if [[ "$CLEAN_ONLY" == true ]]; then
        log_success "构建目录清理完成"
        exit 0
    fi
    
    # 更新版本信息
    update_version_info
    
    # 运行测试（如果未跳过）
    if [[ "$SKIP_TESTS" == false ]]; then
        run_tests
    else
        log_warning "跳过单元测试"
    fi
    
    # 构建项目
    build_project
    
    # 导出应用程序
    export_app
    
    # 创建 DMG（如果未跳过）
    if [[ "$SKIP_DMG" == false ]]; then
        create_dmg
    else
        log_warning "跳过 DMG 创建"
    fi
    
    # 生成构建信息
    generate_build_info
    
    # 显示构建摘要
    show_summary
}

# 执行主函数
main "$@"
