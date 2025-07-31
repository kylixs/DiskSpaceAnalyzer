#!/bin/bash

# DiskSpaceAnalyzer 构建脚本
# 编译项目并生成macOS应用程序包

set -e  # 遇到错误时退出

echo "🚀 开始构建 DiskSpaceAnalyzer..."

# 清理之前的构建
echo "🧹 清理之前的构建产物..."
swift package clean
rm -rf DiskSpaceAnalyzer.app
rm -f DiskSpaceAnalyzer

# 编译项目
echo "🔨 编译项目（Release配置）..."
swift build --configuration release

# 检查编译是否成功
if [ ! -f ".build/arm64-apple-macosx/release/DiskSpaceAnalyzer" ]; then
    echo "❌ 编译失败：找不到可执行文件"
    exit 1
fi

echo "✅ 编译成功！"

# 复制可执行文件到项目根目录
echo "📁 复制可执行文件..."
cp .build/arm64-apple-macosx/release/DiskSpaceAnalyzer ./DiskSpaceAnalyzer

# 创建应用程序包
echo "📦 创建应用程序包..."
mkdir -p DiskSpaceAnalyzer.app/Contents/MacOS
mkdir -p DiskSpaceAnalyzer.app/Contents/Resources

# 复制可执行文件到应用程序包
cp DiskSpaceAnalyzer DiskSpaceAnalyzer.app/Contents/MacOS/

# 创建Info.plist（如果不存在）
if [ ! -f "DiskSpaceAnalyzer.app/Contents/Info.plist" ]; then
    echo "📝 创建Info.plist..."
    cat > DiskSpaceAnalyzer.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>DiskSpaceAnalyzer</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.diskspaceanalyzer</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>DiskSpaceAnalyzer</string>
    <key>CFBundleDisplayName</key>
    <string>磁盘空间分析器</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025 DiskSpaceAnalyzer. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
EOF
fi

# 显示构建结果
echo ""
echo "🎉 构建完成！"
echo ""
echo "📊 构建统计："
echo "   可执行文件大小: $(ls -lh DiskSpaceAnalyzer | awk '{print $5}')"
echo "   应用程序包: DiskSpaceAnalyzer.app"
echo "   架构: $(file DiskSpaceAnalyzer | cut -d: -f2)"
echo ""
echo "🚀 运行方式："
echo "   命令行: ./DiskSpaceAnalyzer"
echo "   应用程序: open DiskSpaceAnalyzer.app"
echo "   Finder: 双击 DiskSpaceAnalyzer.app"
echo ""
echo "📁 输出文件："
echo "   • DiskSpaceAnalyzer (命令行可执行文件)"
echo "   • DiskSpaceAnalyzer.app (macOS应用程序包)"
echo "   • .build/arm64-apple-macosx/release/ (构建产物)"
echo ""

# 验证应用程序包
if [ -d "DiskSpaceAnalyzer.app" ] && [ -f "DiskSpaceAnalyzer.app/Contents/MacOS/DiskSpaceAnalyzer" ]; then
    echo "✅ 应用程序包创建成功！"
else
    echo "❌ 应用程序包创建失败！"
    exit 1
fi

echo "🎯 DiskSpaceAnalyzer 构建完成！"
