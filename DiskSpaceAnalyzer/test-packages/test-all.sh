#!/bin/bash

# 测试所有模块的便捷脚本
# 使用方法: ./test-all.sh

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试模块列表
MODULES=(
    "CommonTests"
    "DataModelTests" 
    "CoordinateSystemTests"
    "PerformanceOptimizerTests"
    "ScanEngineTests"
    "DirectoryTreeViewTests"
    "TreeMapVisualizationTests"
    "InteractionFeedbackTests"
    "SessionManagerTests"
    "UserInterfaceTests"
)

# 统计变量
TOTAL_MODULES=${#MODULES[@]}
PASSED_MODULES=0
FAILED_MODULES=0
FAILED_MODULE_NAMES=()

echo -e "${BLUE}🚀 开始测试所有模块...${NC}"
echo -e "${BLUE}总共 ${TOTAL_MODULES} 个模块${NC}"
echo ""

# 遍历所有模块进行测试
for module in "${MODULES[@]}"; do
    echo -e "${YELLOW}📦 测试模块: ${module}${NC}"
    echo "============================================================"
    
    # 检查模块目录是否存在
    if [ ! -d "${module}" ]; then
        echo -e "${RED}❌ 模块目录 ${module} 不存在，跳过${NC}"
        ((FAILED_MODULES++))
        FAILED_MODULE_NAMES+=("${module} (目录不存在)")
        echo ""
        continue
    fi
    
    # 进入模块目录
    cd "${module}"
    
    # 运行测试
    if swift test --quiet; then
        echo -e "${GREEN}✅ ${module} 测试通过${NC}"
        ((PASSED_MODULES++))
    else
        echo -e "${RED}❌ ${module} 测试失败${NC}"
        ((FAILED_MODULES++))
        FAILED_MODULE_NAMES+=("${module}")
    fi
    
    # 返回上级目录
    cd ..
    echo ""
done

# 输出总结
echo "============================================================"
echo -e "${BLUE}📊 测试总结${NC}"
echo "============================================================"
echo -e "📈 总模块数: ${TOTAL_MODULES}"
echo -e "${GREEN}✅ 通过: ${PASSED_MODULES}${NC}"
echo -e "${RED}❌ 失败: ${FAILED_MODULES}${NC}"

if [ ${FAILED_MODULES} -eq 0 ]; then
    echo -e "${GREEN}🎉 所有模块测试通过！${NC}"
    exit 0
else
    echo -e "${RED}⚠️  以下模块测试失败:${NC}"
    for failed_module in "${FAILED_MODULE_NAMES[@]}"; do
        echo -e "${RED}  • ${failed_module}${NC}"
    done
    exit 1
fi
