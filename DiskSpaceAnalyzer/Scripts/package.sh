#!/bin/bash

# DiskSpaceAnalyzer 打包脚本
# 用于创建分发版本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目配置
PROJECT_NAME="DiskSpaceAnalyzer"
BUNDLE_ID="com.diskspaceanalyzer.app"
VERSION="1.0.0"
BUILD_NUMBER="1"

# 路径配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_ROOT/build"
EXPORT_DIR="$BUILD_DIR/Export"
DIST_DIR="$BUILD_DIR/Distribution"

print_info() {
    echo -e "${BLUE}[PACKAGE]${NC} $1"
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

# 创建DMG镜像
create_dmg() {
    print_info "创建DMG镜像..."
    
    local APP_BUNDLE="$EXPORT_DIR/$PROJECT_NAME.app"
    local DMG_NAME="${PROJECT_NAME}_v${VERSION}.dmg"
    local DMG_PATH="$DIST_DIR/$DMG_NAME"
    local TEMP_DMG="$DIST_DIR/temp.dmg"
    local VOLUME_NAME="$PROJECT_NAME $VERSION"
    
    # 检查应用程序包是否存在
    if [ ! -d "$APP_BUNDLE" ]; then
        print_error "应用程序包不存在: $APP_BUNDLE"
        print_info "请先运行构建脚本创建应用程序包"
        exit 1
    fi
    
    # 创建分发目录
    mkdir -p "$DIST_DIR"
    
    # 创建临时目录用于DMG内容
    local TEMP_DIR="$DIST_DIR/dmg_temp"
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    
    # 复制应用程序到临时目录
    cp -R "$APP_BUNDLE" "$TEMP_DIR/"
    
    # 创建Applications链接
    ln -s /Applications "$TEMP_DIR/Applications"
    
    # 创建README文件
    create_readme "$TEMP_DIR/README.txt"
    
    # 计算所需大小（MB）
    local SIZE=$(du -sm "$TEMP_DIR" | cut -f1)
    SIZE=$((SIZE + 50))  # 添加50MB缓冲
    
    # 创建DMG
    hdiutil create -srcfolder "$TEMP_DIR" -volname "$VOLUME_NAME" -fs HFS+ \
        -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${SIZE}m "$TEMP_DMG"
    
    # 挂载DMG进行自定义
    local DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$TEMP_DMG" | \
        egrep '^/dev/' | sed 1q | awk '{print $1}')
    local MOUNT_POINT="/Volumes/$VOLUME_NAME"
    
    # 等待挂载完成
    sleep 2
    
    # 设置DMG外观
    setup_dmg_appearance "$MOUNT_POINT"
    
    # 卸载DMG
    hdiutil detach "$DEVICE"
    
    # 转换为只读压缩格式
    hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$DMG_PATH"
    
    # 清理临时文件
    rm -f "$TEMP_DMG"
    rm -rf "$TEMP_DIR"
    
    print_success "DMG镜像创建完成: $DMG_PATH"
}

# 设置DMG外观
setup_dmg_appearance() {
    local MOUNT_POINT="$1"
    
    print_info "设置DMG外观..."
    
    # 使用AppleScript设置Finder窗口外观
    osascript << EOF
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 400}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 72
        set background picture of viewOptions to file ".background:background.png"
        make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
        set position of item "$PROJECT_NAME.app" of container window to {150, 200}
        set position of item "Applications" of container window to {350, 200}
        set position of item "README.txt" of container window to {250, 300}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF
}

# 创建ZIP压缩包
create_zip() {
    print_info "创建ZIP压缩包..."
    
    local APP_BUNDLE="$EXPORT_DIR/$PROJECT_NAME.app"
    local ZIP_NAME="${PROJECT_NAME}_v${VERSION}.zip"
    local ZIP_PATH="$DIST_DIR/$ZIP_NAME"
    
    # 检查应用程序包是否存在
    if [ ! -d "$APP_BUNDLE" ]; then
        print_error "应用程序包不存在: $APP_BUNDLE"
        exit 1
    fi
    
    # 创建分发目录
    mkdir -p "$DIST_DIR"
    
    # 创建ZIP
    cd "$EXPORT_DIR"
    zip -r "$ZIP_PATH" "$PROJECT_NAME.app"
    
    print_success "ZIP压缩包创建完成: $ZIP_PATH"
}

# 创建README文件
create_readme() {
    local README_PATH="$1"
    
    cat > "$README_PATH" << EOF
DiskSpaceAnalyzer v$VERSION
==========================

磁盘空间分析器 - 智能可视化磁盘使用情况

安装说明:
1. 将 DiskSpaceAnalyzer.app 拖拽到 Applications 文件夹
2. 首次运行时，可能需要在系统偏好设置中允许运行

系统要求:
- macOS 13.0 或更高版本
- 64位Intel或Apple Silicon处理器

功能特性:
- 智能文件系统扫描
- TreeMap可视化显示
- 交互式目录树浏览
- 性能优化的大文件处理
- 会话管理和历史记录

使用说明:
1. 启动应用程序
2. 选择要分析的目录
3. 等待扫描完成
4. 使用可视化界面浏览结果

技术支持:
如有问题，请访问项目主页或提交Issue。

版权信息:
Copyright © 2024 DiskSpaceAnalyzer. All rights reserved.
EOF
    
    print_info "README文件已创建"
}

# 代码签名（如果有开发者证书）
code_sign() {
    local APP_BUNDLE="$EXPORT_DIR/$PROJECT_NAME.app"
    local IDENTITY="$1"
    
    if [ -z "$IDENTITY" ]; then
        print_warning "未提供签名身份，跳过代码签名"
        return
    fi
    
    print_info "进行代码签名..."
    
    # 签名应用程序
    codesign --force --verify --verbose --sign "$IDENTITY" "$APP_BUNDLE"
    
    if [ $? -eq 0 ]; then
        print_success "代码签名完成"
        
        # 验证签名
        codesign --verify --verbose=2 "$APP_BUNDLE"
        spctl --assess --verbose "$APP_BUNDLE"
    else
        print_error "代码签名失败"
        exit 1
    fi
}

# 公证（需要Apple ID和应用专用密码）
notarize() {
    local APP_BUNDLE="$EXPORT_DIR/$PROJECT_NAME.app"
    local APPLE_ID="$1"
    local PASSWORD="$2"
    local TEAM_ID="$3"
    
    if [ -z "$APPLE_ID" ] || [ -z "$PASSWORD" ] || [ -z "$TEAM_ID" ]; then
        print_warning "未提供公证所需信息，跳过公证"
        return
    fi
    
    print_info "进行应用程序公证..."
    
    # 创建ZIP用于公证
    local NOTARIZE_ZIP="$DIST_DIR/${PROJECT_NAME}_notarize.zip"
    cd "$EXPORT_DIR"
    zip -r "$NOTARIZE_ZIP" "$PROJECT_NAME.app"
    
    # 提交公证
    xcrun notarytool submit "$NOTARIZE_ZIP" \
        --apple-id "$APPLE_ID" \
        --password "$PASSWORD" \
        --team-id "$TEAM_ID" \
        --wait
    
    if [ $? -eq 0 ]; then
        print_success "公证完成"
        
        # 装订公证票据
        xcrun stapler staple "$APP_BUNDLE"
        print_success "公证票据装订完成"
    else
        print_error "公证失败"
        exit 1
    fi
    
    # 清理临时文件
    rm -f "$NOTARIZE_ZIP"
}

# 显示帮助信息
show_help() {
    echo "DiskSpaceAnalyzer 打包脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help                    显示帮助信息"
    echo "  -d, --dmg                     创建DMG镜像"
    echo "  -z, --zip                     创建ZIP压缩包"
    echo "  -s, --sign [身份]             代码签名"
    echo "  -n, --notarize [ID] [密码] [团队ID]  公证应用程序"
    echo "  --all                         创建所有分发格式"
    echo ""
    echo "示例:"
    echo "  $0 --dmg                      # 创建DMG镜像"
    echo "  $0 --zip                      # 创建ZIP压缩包"
    echo "  $0 --all                      # 创建所有格式"
}

# 创建所有分发格式
create_all() {
    print_info "创建所有分发格式..."
    
    create_zip
    create_dmg
    
    print_success "所有分发格式创建完成！"
    print_info "分发文件位置: $DIST_DIR"
    ls -la "$DIST_DIR"
}

# 主函数
main() {
    # 确保构建目录存在
    mkdir -p "$DIST_DIR"
    
    case "${1:-}" in
        -h|--help)
            show_help
            ;;
        -d|--dmg)
            create_dmg
            ;;
        -z|--zip)
            create_zip
            ;;
        -s|--sign)
            code_sign "$2"
            ;;
        -n|--notarize)
            notarize "$2" "$3" "$4"
            ;;
        --all)
            create_all
            ;;
        "")
            create_all
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
