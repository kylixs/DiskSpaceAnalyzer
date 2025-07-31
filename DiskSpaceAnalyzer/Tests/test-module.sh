#!/bin/bash

# 测试单个模块的便捷脚本
# 使用方法: ./test-module.sh ModuleName

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查参数
if [ $# -eq 0 ]; then
    echo -e "${RED}❌ 错误: 请指定要测试的模块名称${NC}"
    echo ""
    echo "使用方法: $0 <ModuleName>"
    echo ""
    echo "可用的模块:"
    echo "  • CommonTests"
    echo "  • DataModelTests"
    echo "  • CoordinateSystemTests"
    echo "  • PerformanceOptimizerTests"
    echo "  • ScanEngineTests"
    echo "  • DirectoryTreeViewTests"
    echo "  • TreeMapVisualizationTests"
    echo "  • InteractionFeedbackTests"
    echo "  • SessionManagerTests"
    echo "  • UserInterfaceTests"
    echo ""
    echo "示例: $0 CommonTests"
    exit 1
fi

MODULE_NAME="$1"

# 检查模块目录是否存在
if [ ! -d "${MODULE_NAME}" ]; then
    echo -e "${RED}❌ 错误: 模块目录 '${MODULE_NAME}' 不存在${NC}"
    exit 1
fi

# 检查Package.swift是否存在
if [ ! -f "${MODULE_NAME}/Package.swift" ]; then
    echo -e "${RED}❌ 错误: 模块 '${MODULE_NAME}' 中没有找到 Package.swift${NC}"
    exit 1
fi

echo -e "${BLUE}🚀 开始测试模块: ${MODULE_NAME}${NC}"
echo "============================================================"

# 进入模块目录
cd "${MODULE_NAME}"

# 运行测试
echo -e "${YELLOW}📦 正在运行测试...${NC}"
if swift test; then
    echo ""
    echo "============================================================"
    echo -e "${GREEN}🎉 ${MODULE_NAME} 测试通过！${NC}"
    exit 0
else
    echo ""
    echo "============================================================"
    echo -e "${RED}❌ ${MODULE_NAME} 测试失败！${NC}"
    exit 1
fi
