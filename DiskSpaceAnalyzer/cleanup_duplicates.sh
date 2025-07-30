#!/bin/bash

# 清理重复定义的脚本

echo "🧹 开始清理重复定义..."

# 定义要清理的重复类型
DUPLICATES=(
    "ScanStatus"
    "SystemStatus" 
    "Theme"
    "ErrorCategory"
    "ErrorSeverity"
    "FileType"
    "ScanTaskPriority"
    "LogLevel"
    "ScanError"
    "ScanStatistics"
    "ScanConfiguration"
)

# 保留Common模块中的定义，删除其他模块中的重复定义
for type in "${DUPLICATES[@]}"; do
    echo "清理 $type 的重复定义..."
    
    # 查找除Common模块外的重复定义
    find Sources/Core -name "*.swift" -not -path "*/Common/*" -exec grep -l "enum.*$type\|struct.*$type" {} \; | while read file; do
        echo "  从 $file 中删除 $type"
        # 删除从注释到结束大括号的整个定义
        sed -i '' "/^\/\/\/ .*$type/,/^}$/d" "$file"
    done
done

# 清理空行
echo "清理多余的空行..."
find Sources/Core -name "*.swift" -exec sed -i '' '/^$/N;/^\n$/d' {} \;

echo "✅ 清理完成！"
