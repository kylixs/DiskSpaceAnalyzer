#!/bin/bash

# DiskSpaceAnalyzer 构建脚本
# 用于编译生成可执行文件并创建应用程序包

set -e

echo "🚀 开始构建 DiskSpaceAnalyzer..."

# 项目配置
PROJECT_NAME="DiskSpaceAnalyzer"
BUILD_DIR="Build"
EXECUTABLE_NAME="DiskSpaceAnalyzer"
APP_NAME="DiskSpaceAnalyzer.app"

# 清理构建目录
echo "🧹 清理构建目录..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 编译项目
echo "🔨 编译项目..."
swift build --configuration release --product "$EXECUTABLE_NAME"

# 检查编译是否成功
if [ ! -f ".build/release/$EXECUTABLE_NAME" ]; then
    echo "❌ 编译失败！"
    exit 1
fi

echo "✅ 编译成功！"

# 创建应用程序包结构
echo "📦 创建应用程序包..."
APP_DIR="$BUILD_DIR/$APP_NAME"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# 复制可执行文件
cp ".build/release/$EXECUTABLE_NAME" "$APP_DIR/Contents/MacOS/"

# 创建 Info.plist
cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>$EXECUTABLE_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.diskspaceanalyzer.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>磁盘空间分析器</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024 DiskSpaceAnalyzer. All rights reserved.</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
EOF

# 创建应用程序图标（如果有的话）
if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/"
fi

# 设置可执行权限
chmod +x "$APP_DIR/Contents/MacOS/$EXECUTABLE_NAME"

echo "🎉 构建完成！"
echo "📍 应用程序位置: $BUILD_DIR/$APP_NAME"
echo "💾 可执行文件大小: $(du -h ".build/release/$EXECUTABLE_NAME" | cut -f1)"

# 显示构建信息
echo ""
echo "📊 构建信息:"
echo "   项目名称: $PROJECT_NAME"
echo "   版本: 1.0.0"
echo "   构建配置: Release"
echo "   目标平台: macOS 10.15+"
echo "   架构: $(uname -m)"

# 可选：打开构建目录
if command -v open >/dev/null 2>&1; then
    echo ""
    read -p "是否打开构建目录？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "$BUILD_DIR"
    fi
fi

echo ""
echo "🚀 要运行应用程序，请执行："
echo "   open $BUILD_DIR/$APP_NAME"
echo ""
echo "或者直接运行可执行文件："
echo "   .build/release/$EXECUTABLE_NAME"
