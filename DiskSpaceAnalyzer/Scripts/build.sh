#!/bin/bash

# DiskSpaceAnalyzer 构建脚本
# 用于编译生成可执行的GUI程序

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="DiskSpaceAnalyzer"
BUNDLE_ID="com.diskspaceanalyzer.app"
VERSION="1.0.0"
BUILD_NUMBER="1"

# 路径配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
DERIVED_DATA_DIR="$BUILD_DIR/DerivedData"
ARCHIVE_DIR="$BUILD_DIR/Archive"
EXPORT_DIR="$BUILD_DIR/Export"

# 函数：打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# 函数：显示帮助信息
show_help() {
    echo "DiskSpaceAnalyzer 构建脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  -c, --clean         清理构建目录"
    echo "  -d, --debug         构建Debug版本"
    echo "  -r, --release       构建Release版本"
    echo "  -a, --archive       创建Archive"
    echo "  -p, --package       打包为.app应用程序"
    echo "  -t, --test          运行测试"
    echo "  --all               执行完整构建流程（清理+测试+Release+打包）"
    echo ""
    echo "示例:"
    echo "  $0 --debug          # 构建Debug版本"
    echo "  $0 --release        # 构建Release版本"
    echo "  $0 --all            # 完整构建流程"
    echo "  $0 --clean          # 清理构建目录"
}

# 函数：清理构建目录
clean_build() {
    print_info "清理构建目录..."
    
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
        print_success "构建目录已清理"
    else
        print_info "构建目录不存在，跳过清理"
    fi
    
    # 清理Swift Package Manager缓存
    cd "$PROJECT_ROOT"
    swift package clean
    print_success "Swift Package Manager缓存已清理"
}

# 函数：创建构建目录
create_build_dirs() {
    print_info "创建构建目录..."
    mkdir -p "$BUILD_DIR"
    mkdir -p "$DERIVED_DATA_DIR"
    mkdir -p "$ARCHIVE_DIR"
    mkdir -p "$EXPORT_DIR"
    print_success "构建目录创建完成"
}

# 函数：运行测试
run_tests() {
    print_info "运行测试..."
    cd "$PROJECT_ROOT"
    
    swift test --parallel
    
    if [ $? -eq 0 ]; then
        print_success "所有测试通过"
    else
        print_error "测试失败"
        exit 1
    fi
}

# 函数：构建Debug版本
build_debug() {
    print_info "构建Debug版本..."
    cd "$PROJECT_ROOT"
    
    swift build --configuration debug
    
    if [ $? -eq 0 ]; then
        print_success "Debug版本构建成功"
        
        # 复制可执行文件到构建目录
        DEBUG_EXECUTABLE="$PROJECT_ROOT/.build/debug/$PROJECT_NAME"
        if [ -f "$DEBUG_EXECUTABLE" ]; then
            cp "$DEBUG_EXECUTABLE" "$BUILD_DIR/${PROJECT_NAME}_debug"
            print_success "Debug可执行文件已复制到: $BUILD_DIR/${PROJECT_NAME}_debug"
        fi
    else
        print_error "Debug版本构建失败"
        exit 1
    fi
}

# 函数：构建Release版本
build_release() {
    print_info "构建Release版本..."
    cd "$PROJECT_ROOT"
    
    swift build --configuration release
    
    if [ $? -eq 0 ]; then
        print_success "Release版本构建成功"
        
        # 复制可执行文件到构建目录
        RELEASE_EXECUTABLE="$PROJECT_ROOT/.build/release/$PROJECT_NAME"
        if [ -f "$RELEASE_EXECUTABLE" ]; then
            cp "$RELEASE_EXECUTABLE" "$BUILD_DIR/${PROJECT_NAME}_release"
            print_success "Release可执行文件已复制到: $BUILD_DIR/${PROJECT_NAME}_release"
        fi
    else
        print_error "Release版本构建失败"
        exit 1
    fi
}

# 函数：创建macOS应用程序包
create_app_bundle() {
    print_info "创建macOS应用程序包..."
    
    local APP_BUNDLE="$EXPORT_DIR/$PROJECT_NAME.app"
    local CONTENTS_DIR="$APP_BUNDLE/Contents"
    local MACOS_DIR="$CONTENTS_DIR/MacOS"
    local RESOURCES_DIR="$CONTENTS_DIR/Resources"
    
    # 创建应用程序包结构
    mkdir -p "$MACOS_DIR"
    mkdir -p "$RESOURCES_DIR"
    
    # 复制可执行文件
    local RELEASE_EXECUTABLE="$PROJECT_ROOT/.build/release/$PROJECT_NAME"
    if [ -f "$RELEASE_EXECUTABLE" ]; then
        cp "$RELEASE_EXECUTABLE" "$MACOS_DIR/$PROJECT_NAME"
        chmod +x "$MACOS_DIR/$PROJECT_NAME"
        print_success "可执行文件已复制到应用程序包"
    else
        print_error "找不到Release可执行文件，请先构建Release版本"
        exit 1
    fi
    
    # 创建Info.plist
    create_info_plist "$CONTENTS_DIR/Info.plist"
    
    # 复制资源文件（如果有的话）
    if [ -d "$PROJECT_ROOT/Resources" ]; then
        cp -R "$PROJECT_ROOT/Resources/"* "$RESOURCES_DIR/"
        print_info "资源文件已复制"
    fi
    
    # 创建应用程序图标（如果有的话）
    if [ -f "$PROJECT_ROOT/Resources/AppIcon.icns" ]; then
        cp "$PROJECT_ROOT/Resources/AppIcon.icns" "$RESOURCES_DIR/"
        print_info "应用程序图标已复制"
    fi
    
    print_success "macOS应用程序包创建完成: $APP_BUNDLE"
}

# 函数：创建Info.plist文件
create_info_plist() {
    local PLIST_PATH="$1"
    
    cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$PROJECT_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$PROJECT_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 DiskSpaceAnalyzer. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSDocumentsFolderUsageDescription</key>
    <string>This app needs access to scan and analyze disk space usage in your documents.</string>
    <key>NSDesktopFolderUsageDescription</key>
    <string>This app needs access to scan and analyze disk space usage on your desktop.</string>
    <key>NSDownloadsFolderUsageDescription</key>
    <string>This app needs access to scan and analyze disk space usage in your downloads.</string>
    <key>NSRemovableVolumesUsageDescription</key>
    <string>This app needs access to scan and analyze disk space usage on external drives.</string>
</dict>
</plist>
EOF
    
    print_success "Info.plist文件已创建"
}

# 函数：显示构建信息
show_build_info() {
    print_info "构建信息:"
    echo "  项目名称: $PROJECT_NAME"
    echo "  Bundle ID: $BUNDLE_ID"
    echo "  版本: $VERSION"
    echo "  构建号: $BUILD_NUMBER"
    echo "  项目根目录: $PROJECT_ROOT"
    echo "  构建目录: $BUILD_DIR"
    echo ""
}

# 函数：完整构建流程
full_build() {
    print_info "开始完整构建流程..."
    
    clean_build
    create_build_dirs
    run_tests
    build_release
    create_app_bundle
    
    print_success "完整构建流程完成！"
    print_info "应用程序位置: $EXPORT_DIR/$PROJECT_NAME.app"
}

# 主函数
main() {
    show_build_info
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                clean_build
                exit 0
                ;;
            -d|--debug)
                create_build_dirs
                build_debug
                exit 0
                ;;
            -r|--release)
                create_build_dirs
                build_release
                exit 0
                ;;
            -a|--archive)
                create_build_dirs
                build_release
                create_app_bundle
                exit 0
                ;;
            -p|--package)
                create_build_dirs
                create_app_bundle
                exit 0
                ;;
            -t|--test)
                run_tests
                exit 0
                ;;
            --all)
                full_build
                exit 0
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
    
    # 如果没有提供参数，显示帮助信息
    show_help
}

# 运行主函数
main "$@"
