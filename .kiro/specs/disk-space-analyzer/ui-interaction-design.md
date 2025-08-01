# UI交互设计文档 - 磁盘空间分析器

## 概述

本文档详细描述了磁盘空间分析器的用户界面交互设计，包括扫描进度显示、文件统计信息、按钮状态管理等最佳实践。

## 界面布局设计

### 主窗口结构 (1200x800像素)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 📁 选择文件夹 | ▶️ 开始扫描 | ⏸️ 暂停 | ⏹️ 停止 | 🔄 刷新 | ⚙️ 设置 | 📊 统计 │ <- 工具栏 (44px)
├─────────────────────────────────────────────────────────────────────────────────┤
│ 📂 /Users/username/Documents                    ⚡ ████████░░ 80% | ⏱️ 00:02:15 │ <- 进度栏 (32px)
├─────────────────────────────────────────────────────────────────────────────────┤
│                        │                                                        │
│   📁 目录树视图          │              🎨 TreeMap 可视化区域                      │
│   ┌─ 📁 Documents       │    ┌─────────┐ ┌─────┐ ┌───────────────┐              │
│   │  ├─ 📁 Projects     │    │         │ │     │ │               │              │
│   │  │  ├─ 📄 file1.txt │    │   大    │ │ 中  │ │      大       │              │
│   │  │  └─ 📄 file2.pdf │    │  文件   │ │文件 │ │     文件      │              │ <- 主内容区域
│   │  ├─ 📁 Images       │    │         │ │     │ │               │              │
│   │  └─ 📁 Videos       │    └─────────┘ └─────┘ └───────────────┘              │
│   ├─ 📁 Downloads       │    ┌───┐ ┌─────┐ ┌──┐ ┌─────────────────┐            │
│   └─ 📁 Pictures        │    │小 │ │ 中等│ │小│ │      超大       │            │
│                        │    │文│ │文件 │ │文│ │     文件        │            │
│                        │    └───┘ └─────┘ └──┘ └─────────────────┘            │
├─────────────────────────────────────────────────────────────────────────────────┤
│ 📊 扫描中: /Users/username/Documents/Projects | 📁 12,345 文件 | 📂 1,234 文件夹 │ <- 状态栏 (28px)
│ 💾 总大小: 15.6 GB | 🚀 速度: 2,500 文件/秒 | ⚠️ 3 个错误 | 🕒 剩余: ~00:01:30  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 扫描状态管理

### 状态机设计

```
     [就绪状态]
         │
    选择文件夹
         │
         ▼
     [准备状态] ──开始扫描──► [扫描中状态]
         │                      │    │
         │                   暂停   │
         │                      │    │
         │                      ▼    │
         │                  [暂停状态] │
         │                      │    │
         │                   继续   │
         │                      │    │
         │                      ▼    │
    重新选择 ◄──────────────────────────┘
         │                           │
         │                        停止
         │                           │
         ▼                           ▼
     [完成状态] ◄─────────────────── [停止状态]
```

### 各状态下的UI表现

#### 1. 就绪状态
```
工具栏按钮状态:
- 📁 选择文件夹: 启用 (蓝色高亮)
- ▶️ 开始扫描: 禁用 (灰色)
- ⏸️ 暂停: 隐藏
- ⏹️ 停止: 隐藏
- 🔄 刷新: 禁用
- ⚙️ 设置: 启用
- 📊 统计: 禁用
- 💾 导出: 禁用

进度栏: 隐藏
状态栏: "📊 就绪 - 请选择要扫描的文件夹"
```

#### 2. 准备状态 (已选择文件夹)
```
工具栏按钮状态:
- 📁 选择文件夹: 启用
- ▶️ 开始扫描: 启用 (绿色高亮)
- ⏸️ 暂停: 隐藏
- ⏹️ 停止: 隐藏
- 🔄 刷新: 启用
- ⚙️ 设置: 启用
- 📊 统计: 禁用
- 💾 导出: 禁用

进度栏: 隐藏
状态栏: "📂 已选择: /path/to/folder - 点击开始扫描"
```

#### 3. 扫描中状态
```
工具栏按钮状态:
- 📁 选择文件夹: 禁用 (灰色)
- ▶️ 开始扫描: 隐藏
- ⏸️ 暂停: 显示并启用 (橙色)
- ⏹️ 停止: 显示并启用 (红色)
- 🔄 刷新: 禁用
- ⚙️ 设置: 禁用
- 📊 统计: 启用
- 💾 导出: 禁用

进度栏: 显示
- 当前路径: "📂 /current/scanning/path"
- 进度条: "⚡ ████████░░ 80%"
- 时间: "⏱️ 00:02:15"

状态栏: 实时更新
- 第一行: "📊 扫描中: /current/path | 📁 12,345 文件 | 📂 1,234 文件夹"
- 第二行: "💾 总大小: 15.6 GB | 🚀 速度: 2,500 文件/秒 | ⚠️ 3 个错误 | 🕒 剩余: ~00:01:30"
```

#### 4. 暂停状态
```
工具栏按钮状态:
- 📁 选择文件夹: 禁用
- ▶️ 继续扫描: 显示并启用 (绿色, 文字变为"继续")
- ⏸️ 暂停: 隐藏
- ⏹️ 停止: 启用 (红色)
- 🔄 刷新: 禁用
- ⚙️ 设置: 禁用
- 📊 统计: 启用
- 💾 导出: 禁用

进度栏: 显示暂停状态
- 当前路径: "⏸️ 已暂停"
- 进度条: "⚡ ████████░░ 80% (暂停)"
- 时间: "⏱️ 00:02:15 (暂停)"

状态栏: "⏸️ 已暂停 | 📁 12,345 文件 | 💾 15.6 GB | 最后扫描: /last/path"
```

#### 5. 完成状态
```
工具栏按钮状态:
- 📁 选择文件夹: 启用
- ▶️ 开始扫描: 隐藏
- 🔄 重新扫描: 显示并启用 (蓝色, 文字变为"重新扫描")
- ⏸️ 暂停: 隐藏
- ⏹️ 停止: 隐藏
- ⚙️ 设置: 启用
- 📊 统计: 启用
- 💾 导出: 启用 (绿色高亮)

进度栏: 显示完成状态
- 当前路径: "✅ 扫描完成"
- 进度条: "⚡ ██████████ 100%"
- 时间: "⏱️ 总用时: 00:03:45"

状态栏: "✅ 扫描完成 | 📁 25,678 文件 | 📂 2,456 文件夹 | 💾 28.9 GB"
```

## 进度显示设计

### 进度栏组件 (32px高度)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 📂 /Users/username/Documents/Projects/MyApp/src    ⚡ ████████░░ 80% | ⏱️ 00:02:15 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

**组件说明：**
- **路径显示区域** (左侧60%): 显示当前正在扫描的文件夹路径
- **进度条区域** (中间30%): 可视化进度条，0-100%
- **时间显示区域** (右侧10%): 已用时间，格式HH:MM:SS

### 进度更新策略

**更新频率：**
- 进度条: 每500ms更新一次
- 路径显示: 每次切换文件夹时更新
- 时间显示: 每秒更新一次
- 统计信息: 每1秒更新一次

**性能优化：**
- 使用节流机制避免过度频繁的UI更新
- 路径显示使用省略号处理过长路径
- 进度条使用Core Animation实现平滑过渡
- 统计信息使用格式化缓存减少计算开销

## 文件统计信息设计

### 状态栏统计显示 (28px高度)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│ 📊 扫描中: /Users/username/Documents/Projects | 📁 12,345 文件 | 📂 1,234 文件夹 │
│ 💾 总大小: 15.6 GB | 🚀 速度: 2,500 文件/秒 | ⚠️ 3 个错误 | 🕒 剩余: ~00:01:30  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 统计信息类型

**基础统计：**
- 📁 文件数量: 已发现的文件总数
- 📂 文件夹数量: 已发现的文件夹总数
- 💾 总大小: 所有文件的总大小，自动格式化 (B/KB/MB/GB/TB)
- 📊 当前状态: 就绪/扫描中/暂停/完成/错误

**性能统计：**
- 🚀 扫描速度: 文件/秒，基于最近5秒的移动平均值
- ⏱️ 已用时间: 从扫描开始到现在的时间
- 🕒 预估剩余时间: 基于当前速度和剩余文件数量估算
- 📈 扫描深度: 当前扫描到的最大目录层级

**错误统计：**
- ⚠️ 错误数量: 扫描过程中遇到的错误总数
- 🔒 权限错误: 无法访问的文件/文件夹数量
- 💥 读取错误: 文件读取失败的数量
- 🔗 链接错误: 符号链接处理错误数量

### 统计信息格式化

**大小格式化规则：**
```
< 1 KB:     显示为 "123 B"
< 1 MB:     显示为 "123.4 KB"
< 1 GB:     显示为 "123.4 MB"  
< 1 TB:     显示为 "123.4 GB"
>= 1 TB:    显示为 "1.23 TB"
```

**数量格式化规则：**
```
< 1,000:    显示为 "123"
< 1,000,000: 显示为 "12,345"
>= 1,000,000: 显示为 "1.23M"
```

**时间格式化规则：**
```
< 1分钟:    显示为 "00:00:45"
< 1小时:    显示为 "00:15:30"
>= 1小时:   显示为 "01:23:45"
```

**速度格式化规则：**
```
< 1,000:    显示为 "123 文件/秒"
< 10,000:   显示为 "1.2K 文件/秒"
>= 10,000:  显示为 "12K 文件/秒"
```

## 按钮设计规范

### 工具栏按钮设计

#### 主要操作按钮

**📁 选择文件夹按钮**
- 图标: `folder.badge.plus`
- 颜色: 系统蓝色 (NSColor.controlAccentColor)
- 状态: 始终可见，扫描时禁用
- 快捷键: Cmd+O
- 工具提示: "选择要扫描的文件夹"

**▶️ 开始扫描按钮**
- 图标: `play.circle.fill`
- 颜色: 系统绿色 (NSColor.systemGreen)
- 状态: 选择文件夹后启用，扫描时隐藏
- 快捷键: Cmd+R
- 工具提示: "开始扫描选定的文件夹"

**⏸️ 暂停按钮**
- 图标: `pause.circle.fill`
- 颜色: 系统橙色 (NSColor.systemOrange)
- 状态: 仅扫描时显示
- 快捷键: Space
- 工具提示: "暂停当前扫描"

**⏹️ 停止按钮**
- 图标: `stop.circle.fill`
- 颜色: 系统红色 (NSColor.systemRed)
- 状态: 扫描或暂停时显示
- 快捷键: Cmd+.
- 工具提示: "停止扫描并保留结果"

#### 辅助操作按钮

**🔄 刷新按钮**
- 图标: `arrow.clockwise`
- 颜色: 系统蓝色
- 状态: 完成状态时变为"重新扫描"
- 快捷键: Cmd+Shift+R
- 工具提示: "重新扫描当前文件夹"

**⚙️ 设置按钮**
- 图标: `gearshape.fill`
- 颜色: 系统灰色
- 状态: 扫描时禁用
- 快捷键: Cmd+,
- 工具提示: "打开扫描设置"

**📊 统计按钮**
- 图标: `chart.bar.fill`
- 颜色: 系统蓝色
- 状态: 有数据时启用
- 快捷键: Cmd+I
- 工具提示: "显示详细统计信息"

**💾 导出按钮**
- 图标: `square.and.arrow.up`
- 颜色: 系统绿色
- 状态: 扫描完成后启用
- 快捷键: Cmd+E
- 工具提示: "导出扫描结果"

### 按钮状态管理

#### 状态转换规则

```
按钮状态矩阵:
                就绪  准备  扫描中  暂停  完成
选择文件夹      ✅    ✅    ❌     ❌    ✅
开始扫描        ❌    ✅    隐藏   隐藏  隐藏
暂停           隐藏  隐藏   ✅     隐藏  隐藏
停止           隐藏  隐藏   ✅     ✅   隐藏
刷新/重新扫描   ❌    ✅    ❌     ❌    ✅
设置           ✅    ✅    ❌     ❌    ✅
统计           ❌    ❌    ✅     ✅    ✅
导出           ❌    ❌    ❌     ❌    ✅
```

#### 视觉反馈设计

**启用状态:**
- 图标: 正常颜色，清晰显示
- 背景: 鼠标悬停时显示高亮背景
- 动画: 点击时有轻微的缩放动画

**禁用状态:**
- 图标: 50%透明度，灰色调
- 背景: 无交互反馈
- 鼠标: 显示禁用光标

**高亮状态 (重要操作):**
- 图标: 稍大尺寸 (18px vs 16px)
- 背景: 轻微的彩色背景
- 动画: 轻微的脉冲动画提示

## 目录树面板设计

### 列设计规范

#### 名称列 (60%宽度)
```
┌─ 📁 Documents                    ⚡
│  ├─ 📁 Projects                  
│  │  ├─ 📄 file1.txt             
│  │  └─ 📄 file2.pdf             
│  ├─ 📁 Images                   🔄
│  └─ 📁 Videos                   
```

**显示内容:**
- 文件夹图标: `folder.fill` (蓝色) / `doc.fill` (灰色)
- 文件/文件夹名称
- 扫描状态图标: ⚡(完成) / 🔄(扫描中) / ⚠️(错误)

#### 大小列 (25%宽度)
```
大小
────────
2.5 GB
1.2 GB
45.6 MB
128 KB
```

**格式化规则:**
- 右对齐显示
- 自动选择合适的单位 (B/KB/MB/GB/TB)
- 保留1位小数 (小于1KB时显示整数)
- 扫描中显示 "..." 或进度条

#### 项目列 (15%宽度)
```
项目
────────
1,234
567
89
1
```

**显示内容:**
- 文件夹: 显示子项目数量
- 文件: 显示 "-" 或空白
- 右对齐显示
- 使用千位分隔符

### 实时更新机制

**增量更新策略:**
1. 新发现文件夹时立即添加到树中
2. 文件夹大小变化时更新对应行
3. 扫描完成的文件夹移除加载图标
4. 使用批量更新减少UI刷新频率

**视觉反馈:**
- 新添加的行有淡入动画
- 正在扫描的文件夹有加载动画
- 大小变化时有数字滚动动画
- 完成扫描时有完成提示动画

## TreeMap面板设计

### 可视化规范

#### 颜色编码方案

**文件类型颜色:**
```
文档文件:    蓝色系 (#007AFF, #5AC8FA, #34C759)
图片文件:    绿色系 (#34C759, #30D158, #32D74B)
视频文件:    紫色系 (#AF52DE, #BF5AF2, #CF6679)
音频文件:    橙色系 (#FF9500, #FF9F0A, #FFB340)
代码文件:    红色系 (#FF3B30, #FF453A, #FF6961)
压缩文件:    灰色系 (#8E8E93, #98989D, #A8A8A8)
其他文件:    默认色 (#F2F2F7, #E5E5EA, #D1D1D6)
```

**大小映射规则:**
- 方块面积与文件大小成正比
- 最小方块: 16x16像素
- 最大方块: 不超过面板的1/4
- 使用Squarified算法优化布局

#### 交互反馈设计

**鼠标悬停效果:**
- 方块边框高亮 (2px白色边框)
- 显示详细tooltip
- 相关文件夹在目录树中高亮
- 其他方块略微变暗 (80%透明度)

**点击交互:**
- 单击: 在目录树中选中对应项目
- 双击: 进入子文件夹 (如果是文件夹)
- 右键: 显示上下文菜单

**tooltip设计:**
```
┌─────────────────────────────┐
│ 📁 Documents                │
│ 💾 大小: 2.5 GB             │
│ 📁 包含: 1,234 个项目        │
│ 📍 路径: /Users/.../Documents│
│ 🕒 修改: 2024-07-30 14:30   │
└─────────────────────────────┘
```

### 实时渲染策略

**渲染优化:**
- 使用Core Animation图层缓存
- 大文件夹优先渲染
- 小文件合并显示 ("其他文件")
- 视口外的方块延迟渲染

**动画效果:**
- 新方块淡入动画 (300ms)
- 大小变化的缩放动画 (200ms)
- 颜色变化的渐变动画 (150ms)
- 布局调整的位移动画 (250ms)

## 最佳实践总结

### 响应性设计原则

1. **即时反馈** - 用户操作后100ms内给出视觉反馈
2. **进度指示** - 超过1秒的操作显示进度指示器
3. **状态一致** - UI状态与数据状态保持同步
4. **优雅降级** - 在性能不足时自动降低更新频率

### 可访问性设计原则

1. **键盘导航** - 所有功能都可通过键盘操作
2. **屏幕阅读** - 为VoiceOver提供完整的语义信息
3. **高对比度** - 支持系统高对比度模式
4. **字体缩放** - 支持系统字体大小设置

### 性能优化原则

1. **异步操作** - 耗时操作在后台线程执行
2. **UI节流** - 限制UI更新频率避免卡顿
3. **内存管理** - 及时释放不需要的UI资源
4. **硬件加速** - 使用Core Animation优化渲染

### 用户体验原则

1. **直观操作** - 按钮图标清晰，操作流程简单
2. **状态反馈** - 清晰的状态指示和进度反馈
3. **错误恢复** - 友好的错误提示和恢复机制
4. **数据保护** - 自动保存防止数据丢失

---

**文档版本:** 1.0  
**最后更新:** 2024-07-30  
**负责人:** UI设计团队
