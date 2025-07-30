# TreeMap可视化模块 (TreeMapVisualization) - 处理流程设计

## 模块概述

**模块名称：** TreeMapVisualization  
**对应需求特性：** 特性3 - TreeMap可视化系统  
**核心职责：** 实现右侧面板的TreeMap可视化系统，使用Squarified算法生成标准矩形拼图布局，支持多行多列网格显示和小文件合并

## 核心组件

### 1. TreeMapLayoutEngine - 布局引擎
**关键逻辑：** 协调整个TreeMap的布局计算流程，管理布局缓存和增量更新。在后台线程执行复杂计算，支持布局结果的序列化存储，实现100ms内的布局响应时间。

**实现步骤：**
- 使用DispatchQueue.global(qos: .userInitiated)在后台线程计算布局
- 维护布局缓存字典，键为节点ID，值为计算结果
- 实现增量更新，只重新计算变化的节点布局
- 使用DispatchSemaphore控制并发计算数量，避免资源过载

### 2. SquarifiedAlgorithm - Squarified算法
**关键逻辑：** 实现标准Squarified TreeMap算法，递归分割空间生成最优长宽比的矩形。使用贪心策略选择最佳分割点，确保方块紧密排列无空隙，生成多行多列的网格布局。

**实现步骤：**
- 按面积大小排序输入节点，使用贪心策略分组
- 计算每组的最佳长宽比，选择最接近1:1的分割方案
- 递归分割剩余空间，直到所有节点都分配完毕
- 精确计算矩形边界，确保像素级对齐无空隙

### 3. ColorManager - 颜色管理器
**关键逻辑：** 基于HSB颜色模型实现同色系深浅变化，目录使用蓝色系，文件使用橙色系。根据文件大小计算颜色深度，支持深色/浅色模式切换，确保颜色对比度和可读性。

**实现步骤：**
- 定义蓝色系(H=240°)和橙色系(H=30°)的基础色相
- 根据文件大小比例计算饱和度(20%-80%)和亮度(30%-70%)
- 监听NSApp.effectiveAppearance变化，动态调整颜色方案
- 使用对数缩放避免极值，确保颜色差异明显可区分

### 4. SmallFilesMerger - 小文件合并器
**关键逻辑：** 识别占比小于1%的小文件，保留最大的4个小文件显示，将其余文件合并为"其他文件"方块。计算合并方块的总大小和统计信息，支持合并详情的tooltip显示。

**实现步骤：**
- 计算每个文件占总大小的百分比，筛选小于1%的文件
- 对小文件按大小排序，保留前4个最大的小文件
- 创建虚拟合并节点，累加剩余小文件的大小和数量
- 生成合并节点的tooltip内容，显示被合并文件的详细列表

### 5. AnimationController - 动画控制器
**关键逻辑：** 管理TreeMap布局变化的平滑动画效果，使用缓动函数实现自然的过渡。支持方块的位置、大小和颜色动画，控制动画时长和帧率，提供动画的暂停和取消机制。

**实现步骤：**
- 使用CABasicAnimation实现方块的位置和大小动画
- 设置缓动函数为kCAMediaTimingFunctionEaseInEaseOut
- 动画时长设置为0.3秒，确保流畅不拖沓的视觉效果
- 实现动画组合，同时处理多个属性的变化动画

## 依赖关系

- **依赖模块**: DataModelr
nManager

## 主要处理流程

### 流程1：TreeMap布局计算流程

```mermaid
sequenceDiagram
    
    participant TMV as TreeMapVisualization
    participant TMLE as TreeMapLayoutEng
    participant SA as SquarifiedAlgori
    participant SFM as SmallFilesMerger
    
    DTV->>TMV: updateLayout(selected
    TMV->>SFM: mergeSmallFilen)
    SFM->>TMV: mergedNodes([FileNode])
    TMV->>TMLE: calculateLayout(merge bounds)
    TMLE->>SA: squarify(nodes, bounds)
   atios()

    SA->>t])
    TMLE->>T
    TMV->>TMV: eMap()
```

**详细步骤：**
1. **数据预处理**
   - 获取选中目录的子节点数据 - 从数据模型获取当前目录的所有子项
   - 过滤无效或空节点 - 移除大小为0或无效的节点，确保数据质量
   - 计算节点相对大小 - 计算每个节点占总大小的比例，用于布局计算
   - 验证数据完整性 - 检查数据一致性，处理异常情况

2. **小文件合并**
   - 识别占比小于1%的小文件 - 按比例阈值筛选需要合并的小文件
   - 保留最大的4个小文件 - 选择最大的几个小文件单独显示
   - 合并其余小文件为"其他文件"项 - 创建虚拟合并节点，聚合统计信息
   - 计算合并项总大小 - 累加所有合并文件的大小和数量

3. **Squarified算法执行**
   - 按文件大小降序排序 - 使用快速排序算法按大小排列节点
   - 递归分割可用空间 - 使用贪心策略选择最佳分割方向和位置
   - 优化矩形长宽比 - 计算长宽比，选择最接近1:1的分割方案
   - 确保紧密排列无空隙 - 精确计算矩形边界，避免像素间隙

4. **布局优化**
   - 调整矩形边界对齐 - 对齐到像素边界，确保清晰显示
   - 优化小方块可见性 - 设置最小显示尺寸，确保可点击性
   - 平衡行列分布 - 调整布局参数，实现理想的网格效果
   - 确保多行多列网格效果 - 验证最终布局符合TreeMap标准

### 流程2：颜色系统管理流程

```maid
sequenceDiagram
    participant TMV as TreeMapVisuation
    
    participant Node
    participant Rect as RectView
    
    TMV-s)
    
    loop 为每个节点
        CM->>Node:()
        Node->>CM: nodeType(directory/file)
        
        alt 是目录
           (size)
       
    文件
            CM->>CM: calculateOe)
   

        
        CM-
    end
    
    CM->>TMVd
```

**详细步骤：**
1. **颜色系统设计**
   - 目录使用蓝色系 (HSB0-80%)
   - 文件使用橙色系 (HSB)
   - 占用空间越大，颜深


2. **深度计算**
   - 根据文件大小计算颜色深度
   - 使用对数缩放避免极值
   - 确保最小和最大深度可区分
的颜色

3. **颜色生成**
   - 使用HSB颜色控制
   - 动态调整饱和度和亮度
   - 考虑系统深色/色模式
方案

流程

```mermaid
sequenceDiagram
    participant SE as ScanEngine
    participant TMV as TreeMapViion
    participant TMLE as TreeMapL
    izer
    participant Canvas as Canvas
    
    SE->>TMV: odes)
    TMV->>PO: checkUpdateThrottle()
    PO->>TMV: updateAllowed
    TMV-)
    TMLE->>TMV:
    TMV->>Canvas: renderTreeMap()
    Canvas->>Canvas: drawRectangles()
    Canvas->>Can()
    Canvas->>TMV: renderComplete
```

**详细步骤：**
1. **更新节流**
   - 10
   -
   - 优先处理用户交互触发的更新
   中智能降频

2. **增量更新**
   - 只重新计算变化的
   - 复用未变化的布局结果
   - 优化大数据集的更新性能
   - 保持动画的连续性

*
   - 使用Canv制
   - 实现脏矩形更新机制
   - 优化文字渲染性能
   - 支持高DPI显示器

性能优化策略

### 1. 布局计算优化
- 缓存布局结果避免重复计算
- 使用增量更新减少计算量
- 在后台线程执行复杂计算
序列化存储

### 2. 渲染性能优化
- 使用Core Graphic加速
- 实现视口裁剪只渲染可见部分
- 优化文字渲染和字体缓存


化
- 及时释放不需要的数据
- 使用对象池管理矩形对象
- 优化颜色对象的创建和缓存
- 实现智能的垃圾回收策略

## 接口定义

```swift
protocol TreeMapVisualizationProtoc{
    // 布局更新
    func updateLayout(for nodes
    func updateLayout(for nodes: [F
    out()
    
    // 交互处理
    funint)
    func selectBlock(at point: CGPoint) ?
    funt()
    func getRect(for node: FileNodet?
    
    查询
    var isLayouting: Bool { get }
   t }
}
    
    // 配置
    func setCoect)
    func setColorSeme)
    func setA Bool)
}

protocol Treeol {
    func calculaeeMapRect]
    func optimRect]
    var isCalc}
}

struct TreeRect {
    let node: FileNode
    let frame: C
    let color: Color
    let level: Int

```

## 测试策略

### 1. 算法测试
确性测试
- 边界条件测试 (空数据、单个文件等)
能基准测试
- 布局质量评估测试

### 2. 视觉测试
- 颜色系统准确性测试
- 动画流畅性测试
- 不同屏幕尺寸适配测试
- 高DPI显示器兼容性测试

### 3. 交互测试
- 鼠标悬停响应测试
- 点击选择准确性测试
- 实时更新性能测试
- 大数据集渲染测试

## 监控指标

### 1. 性能指标
- 布局计算时间
渲染帧率
- 内存使用量
- CPU使用率

### 2. 质量指标
- 布局准确性
- 颜色分配正确性
动画流畅度
- 交互响应时间

### 3. 用户体验指标
- 布局更新延迟
- 视觉效果满意度
交互精确度
- 系统稳定性