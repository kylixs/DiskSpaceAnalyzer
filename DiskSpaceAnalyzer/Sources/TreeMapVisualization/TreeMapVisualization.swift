import Foundation
import AppKit
import Common
import DataModel
import CoordinateSystem
import PerformanceOptimizer

// MARK: - TreeMapVisualization Module
// TreeMap可视化模块 - 提供标准TreeMap可视化功能

/// TreeMapVisualization模块信息
public struct TreeMapVisualizationModule {
    public static let version = "1.0.0"
    public static let description = "TreeMap可视化组件"
    
    public static func initialize() {
        print("🗺️ TreeMapVisualization模块初始化")
        print("📋 包含: TreeMapLayoutEngine、SquarifiedAlgorithm、ColorManager、SmallFilesMerger、AnimationController")
        print("📊 版本: \(version)")
        print("✅ TreeMapVisualization模块初始化完成")
    }
}

// MARK: - TreeMap矩形

/// TreeMap矩形 - 表示TreeMap中的一个矩形块
public struct TreeMapRect {
    public let node: FileNode
    public let rect: CGRect
    public let color: NSColor
    public let level: Int
    
    public init(node: FileNode, rect: CGRect, color: NSColor, level: Int = 0) {
        self.node = node
        self.rect = rect
        self.color = color
        self.level = level
    }
    
    /// 检查点是否在矩形内
    public func contains(_ point: CGPoint) -> Bool {
        return rect.contains(point)
    }
    
    /// 获取矩形中心点
    public var center: CGPoint {
        return CGPoint(x: rect.midX, y: rect.midY)
    }
    
    /// 获取矩形面积
    public var area: CGFloat {
        return rect.width * rect.height
    }
}

// MARK: - Squarified算法

/// Squarified算法 - 实现标准TreeMap布局算法
public class SquarifiedAlgorithm {
    public static let shared = SquarifiedAlgorithm()
    
    private init() {}
    
    /// 计算TreeMap布局
    public func calculateLayout(nodes: [FileNode], bounds: CGRect) -> [TreeMapRect] {
        guard !nodes.isEmpty && bounds.width > 0 && bounds.height > 0 else {
            return []
        }
        
        // 过滤掉大小为0的节点
        let validNodes = nodes.filter { $0.size > 0 }
        guard !validNodes.isEmpty else { return [] }
        
        // 按大小排序（降序）
        let sortedNodes = validNodes.sorted { $0.size > $1.size }
        
        // 计算总大小
        let totalSize = sortedNodes.reduce(0) { $0 + $1.size }
        guard totalSize > 0 else { return [] }
        
        // 开始递归布局
        var result: [TreeMapRect] = []
        squarify(nodes: sortedNodes, bounds: bounds, totalSize: totalSize, result: &result)
        
        return result
    }
    
    private func squarify(nodes: [FileNode], bounds: CGRect, totalSize: Int64, result: inout [TreeMapRect]) {
        guard !nodes.isEmpty else { return }
        
        if nodes.count == 1 {
            // 只有一个节点，直接填充整个区域
            let node = nodes[0]
            let color = ColorManager.shared.getColor(for: node)
            let rect = TreeMapRect(node: node, rect: bounds, color: color)
            result.append(rect)
            return
        }
        
        // 选择较短的边作为分割方向
        let isVertical = bounds.width < bounds.height
        
        // 找到最佳分割点
        let splitIndex = findBestSplit(nodes: nodes, isVertical: isVertical)
        
        // 分割节点
        let leftNodes = Array(nodes[0..<splitIndex])
        let rightNodes = Array(nodes[splitIndex...])
        
        // 计算分割比例
        let leftSize = leftNodes.reduce(0) { $0 + $1.size }
        let rightSize = rightNodes.reduce(0) { $0 + $1.size }
        let leftRatio = Double(leftSize) / Double(totalSize)
        
        // 分割矩形
        let (leftBounds, rightBounds) = splitRect(bounds, ratio: leftRatio, isVertical: isVertical)
        
        // 递归处理子区域
        squarify(nodes: leftNodes, bounds: leftBounds, totalSize: leftSize, result: &result)
        squarify(nodes: rightNodes, bounds: rightBounds, totalSize: rightSize, result: &result)
    }
    
    private func findBestSplit(nodes: [FileNode], isVertical: Bool) -> Int {
        guard nodes.count > 1 else { return 1 }
        
        var bestSplit = 1
        var bestRatio = Double.infinity
        
        // 尝试不同的分割点
        for i in 1..<nodes.count {
            let leftNodes = Array(nodes[0..<i])
            let rightNodes = Array(nodes[i...])
            
            let leftSize = leftNodes.reduce(0) { $0 + $1.size }
            let rightSize = rightNodes.reduce(0) { $0 + $1.size }
            
            // 计算长宽比
            let ratio = calculateAspectRatio(leftSize: leftSize, rightSize: rightSize, isVertical: isVertical)
            
            if ratio < bestRatio {
                bestRatio = ratio
                bestSplit = i
            }
        }
        
        return bestSplit
    }
    
    private func calculateAspectRatio(leftSize: Int64, rightSize: Int64, isVertical: Bool) -> Double {
        let totalSize = leftSize + rightSize
        guard totalSize > 0 else { return Double.infinity }
        
        let leftRatio = Double(leftSize) / Double(totalSize)
        let rightRatio = Double(rightSize) / Double(totalSize)
        
        // 简化的长宽比计算
        if isVertical {
            return max(leftRatio / rightRatio, rightRatio / leftRatio)
        } else {
            return max(rightRatio / leftRatio, leftRatio / rightRatio)
        }
    }
    
    private func splitRect(_ rect: CGRect, ratio: Double, isVertical: Bool) -> (CGRect, CGRect) {
        if isVertical {
            // 垂直分割
            let splitY = rect.minY + rect.height * CGFloat(ratio)
            let leftRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: splitY - rect.minY)
            let rightRect = CGRect(x: rect.minX, y: splitY, width: rect.width, height: rect.maxY - splitY)
            return (leftRect, rightRect)
        } else {
            // 水平分割
            let splitX = rect.minX + rect.width * CGFloat(ratio)
            let leftRect = CGRect(x: rect.minX, y: rect.minY, width: splitX - rect.minX, height: rect.height)
            let rightRect = CGRect(x: splitX, y: rect.minY, width: rect.maxX - splitX, height: rect.height)
            return (leftRect, rightRect)
        }
    }
}

// MARK: - 颜色管理器

/// 颜色管理器 - 管理TreeMap的颜色方案
public class ColorManager {
    public static let shared = ColorManager()
    
    // 文件夹颜色（蓝色系）
    private let directoryColors: [NSColor] = [
        NSColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),  // 深蓝
        NSColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0),  // 中蓝
        NSColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1.0),  // 浅蓝
        NSColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 1.0),  // 更浅蓝
    ]
    
    // 文件颜色（橙色系）
    private let fileColors: [NSColor] = [
        NSColor(red: 0.8, green: 0.4, blue: 0.2, alpha: 1.0),  // 深橙
        NSColor(red: 0.9, green: 0.5, blue: 0.3, alpha: 1.0),  // 中橙
        NSColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0),  // 浅橙
        NSColor(red: 1.0, green: 0.7, blue: 0.5, alpha: 1.0),  // 更浅橙
    ]
    
    private init() {}
    
    /// 获取节点颜色
    public func getColor(for node: FileNode) -> NSColor {
        let colors = node.isDirectory ? directoryColors : fileColors
        
        // 根据大小选择颜色深度
        let sizeRatio = getSizeRatio(for: node)
        let colorIndex = min(Int(sizeRatio * Double(colors.count)), colors.count - 1)
        
        return colors[colorIndex]
    }
    
    /// 获取高亮颜色
    public func getHighlightColor(for node: FileNode) -> NSColor {
        let baseColor = getColor(for: node)
        return baseColor.blended(withFraction: 0.3, of: NSColor.white) ?? baseColor
    }
    
    /// 获取选中颜色
    public func getSelectionColor(for node: FileNode) -> NSColor {
        return NSColor.selectedControlColor
    }
    
    private func getSizeRatio(for node: FileNode) -> Double {
        // 简化的大小比例计算
        let logSize = log10(max(Double(node.size), 1.0))
        let normalizedSize = (logSize - 1.0) / 8.0 // 假设最大为10^9字节
        return max(0.0, min(1.0, normalizedSize))
    }
}

// MARK: - 小文件合并器

/// 小文件合并器 - 处理小文件的合并显示
public class SmallFilesMerger {
    public static let shared = SmallFilesMerger()
    
    private let maxSmallFiles = 4 // 最多显示4个小文件
    private let smallFileThreshold = 0.01 // 小于1%的文件被认为是小文件
    
    private init() {}
    
    /// 合并小文件
    public func mergeSmallFiles(_ nodes: [FileNode]) -> [FileNode] {
        guard nodes.count > maxSmallFiles else { return nodes }
        
        // 计算总大小
        let totalSize = nodes.reduce(0) { $0 + $1.size }
        guard totalSize > 0 else { return nodes }
        
        // 分离大文件和小文件
        var largeFiles: [FileNode] = []
        var smallFiles: [FileNode] = []
        
        for node in nodes {
            let ratio = Double(node.size) / Double(totalSize)
            if ratio >= smallFileThreshold && largeFiles.count < maxSmallFiles {
                largeFiles.append(node)
            } else {
                smallFiles.append(node)
            }
        }
        
        // 如果有小文件需要合并
        if !smallFiles.isEmpty {
            let mergedSize = smallFiles.reduce(0) { $0 + $1.size }
            let mergedNode = FileNode(
                name: "其他文件 (\(smallFiles.count)个)",
                path: "merged://other_files",
                size: mergedSize,
                isDirectory: false
            )
            largeFiles.append(mergedNode)
        }
        
        return largeFiles
    }
}

// MARK: - 动画控制器

/// 动画控制器 - 管理TreeMap的动画效果
public class AnimationController {
    public static let shared = AnimationController()
    
    private let animationDuration: TimeInterval = 0.3
    private var currentAnimations: [String: NSViewAnimation] = [:]
    
    private init() {}
    
    /// 执行布局动画
    public func animateLayout(from oldRects: [TreeMapRect], to newRects: [TreeMapRect], completion: @escaping () -> Void) {
        // 简化的动画实现
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            completion()
        }
    }
    
    /// 执行高亮动画
    public func animateHighlight(rect: TreeMapRect, completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion()
        }
    }
    
    /// 取消所有动画
    public func cancelAllAnimations() {
        currentAnimations.values.forEach { $0.stop() }
        currentAnimations.removeAll()
    }
}

// MARK: - TreeMap布局引擎

/// TreeMap布局引擎 - 协调整个布局计算流程
public class TreeMapLayoutEngine {
    public static let shared = TreeMapLayoutEngine()
    
    private let squarifiedAlgorithm = SquarifiedAlgorithm.shared
    private let colorManager = ColorManager.shared
    private let smallFilesMerger = SmallFilesMerger.shared
    private let throttleManager = ThrottleManager.shared
    
    // 缓存
    private var layoutCache: [String: [TreeMapRect]] = [:]
    private let cacheQueue = DispatchQueue(label: "TreeMapLayoutCache", attributes: .concurrent)
    
    // 性能监控
    private var lastLayoutTime: Date = Date()
    private let layoutTimeThreshold: TimeInterval = 0.1 // 100ms
    
    private init() {}
    
    /// 计算TreeMap布局
    public func calculateLayout(for node: FileNode, bounds: CGRect, completion: @escaping ([TreeMapRect]) -> Void) {
        let cacheKey = "\(node.id)-\(bounds)"
        
        // 检查缓存
        cacheQueue.async { [weak self] in
            if let cachedLayout = self?.layoutCache[cacheKey] {
                DispatchQueue.main.async {
                    completion(cachedLayout)
                }
                return
            }
            
            // 在后台线程计算布局
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                let startTime = Date()
                let layout = self.performLayoutCalculation(for: node, bounds: bounds)
                let calculationTime = Date().timeIntervalSince(startTime)
                
                // 缓存结果
                self.cacheQueue.async(flags: .barrier) {
                    self.layoutCache[cacheKey] = layout
                }
                
                // 返回结果
                DispatchQueue.main.async {
                    completion(layout)
                }
                
                // 性能监控
                if calculationTime > self.layoutTimeThreshold {
                    print("⚠️ TreeMap布局计算耗时: \(calculationTime * 1000)ms")
                }
            }
        }
    }
    
    private func performLayoutCalculation(for node: FileNode, bounds: CGRect) -> [TreeMapRect] {
        guard node.isDirectory else {
            // 单个文件
            let color = colorManager.getColor(for: node)
            return [TreeMapRect(node: node, rect: bounds, color: color)]
        }
        
        // 获取子节点
        let children = node.children
        guard !children.isEmpty else { return [] }
        
        // 合并小文件
        let mergedChildren = smallFilesMerger.mergeSmallFiles(children)
        
        // 使用Squarified算法计算布局
        return squarifiedAlgorithm.calculateLayout(nodes: mergedChildren, bounds: bounds)
    }
    
    /// 清除缓存
    public func clearCache() {
        cacheQueue.async(flags: .barrier) { [weak self] in
            self?.layoutCache.removeAll()
        }
    }
    
    /// 获取缓存统计
    public func getCacheStatistics() -> (count: Int, memoryUsage: Int) {
        return cacheQueue.sync {
            let count = layoutCache.count
            let memoryUsage = count * MemoryLayout<[TreeMapRect]>.size
            return (count, memoryUsage)
        }
    }
}

// MARK: - TreeMap视图

/// TreeMap视图 - 渲染TreeMap的自定义视图
public class TreeMapView: NSView {
    
    // 数据
    private var treeMapRects: [TreeMapRect] = []
    private var highlightedRect: TreeMapRect?
    private var selectedRect: TreeMapRect?
    
    // 管理器
    private let layoutEngine = TreeMapLayoutEngine.shared
    private let colorManager = ColorManager.shared
    private let animationController = AnimationController.shared
    
    // 回调
    public var onRectClicked: ((TreeMapRect) -> Void)?
    public var onRectHovered: ((TreeMapRect?) -> Void)?
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 添加鼠标跟踪
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    /// 设置数据
    public func setData(_ node: FileNode) {
        layoutEngine.calculateLayout(for: node, bounds: bounds) { [weak self] rects in
            self?.treeMapRects = rects
            self?.needsDisplay = true
        }
    }
    
    /// 更新布局
    public func updateLayout() {
        needsDisplay = true
    }
    
    // MARK: - 绘制
    
    public override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        // 绘制所有矩形
        for rect in treeMapRects {
            drawRect(rect, in: context)
        }
        
        // 绘制高亮
        if let highlighted = highlightedRect {
            drawHighlight(highlighted, in: context)
        }
        
        // 绘制选中状态
        if let selected = selectedRect {
            drawSelection(selected, in: context)
        }
    }
    
    private func drawRect(_ treeMapRect: TreeMapRect, in context: CGContext) {
        let rect = treeMapRect.rect
        
        // 填充颜色
        context.setFillColor(treeMapRect.color.cgColor)
        context.fill(rect)
        
        // 绘制边框
        context.setStrokeColor(NSColor.separatorColor.cgColor)
        context.setLineWidth(1.0)
        context.stroke(rect)
        
        // 绘制文本（如果矩形足够大）
        if rect.width > 60 && rect.height > 20 {
            drawText(for: treeMapRect, in: context)
        }
    }
    
    private func drawText(for treeMapRect: TreeMapRect, in context: CGContext) {
        let rect = treeMapRect.rect
        let node = treeMapRect.node
        
        // 准备文本
        let name = node.name
        let size = SharedUtilities.formatFileSize(node.size)
        let text = "\(name)\n\(size)"
        
        // 文本属性
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.labelColor
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        // 计算文本位置（居中）
        let textRect = CGRect(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        // 确保文本在矩形内
        let clippedRect = rect.intersection(textRect)
        if !clippedRect.isEmpty {
            attributedString.draw(in: clippedRect)
        }
    }
    
    private func drawHighlight(_ treeMapRect: TreeMapRect, in context: CGContext) {
        let rect = treeMapRect.rect
        let highlightColor = colorManager.getHighlightColor(for: treeMapRect.node)
        
        context.setFillColor(highlightColor.cgColor)
        context.fill(rect)
        
        // 高亮边框
        context.setStrokeColor(NSColor.controlAccentColor.cgColor)
        context.setLineWidth(2.0)
        context.stroke(rect)
    }
    
    private func drawSelection(_ treeMapRect: TreeMapRect, in context: CGContext) {
        let rect = treeMapRect.rect
        let selectionColor = colorManager.getSelectionColor(for: treeMapRect.node)
        
        // 选中边框
        context.setStrokeColor(selectionColor.cgColor)
        context.setLineWidth(3.0)
        context.stroke(rect)
    }
    
    // MARK: - 鼠标事件
    
    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        
        if let rect = findRect(at: point) {
            selectedRect = rect
            needsDisplay = true
            onRectClicked?(rect)
        }
    }
    
    public override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let rect = findRect(at: point)
        
        // 比较矩形的节点ID来判断是否是同一个矩形
        let isSameRect = (rect?.node.id == highlightedRect?.node.id)
        
        if !isSameRect {
            highlightedRect = rect
            needsDisplay = true
            onRectHovered?(rect)
        }
    }
    
    private func findRect(at point: CGPoint) -> TreeMapRect? {
        return treeMapRects.first { $0.contains(point) }
    }
    
    // MARK: - 视图更新
    
    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // 移除旧的跟踪区域
        trackingAreas.forEach { removeTrackingArea($0) }
        
        // 添加新的跟踪区域
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .mouseMoved, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
}

// MARK: - TreeMap可视化管理器

/// TreeMap可视化管理器 - 统一管理TreeMap可视化功能
public class TreeMapVisualization {
    public static let shared = TreeMapVisualization()
    
    private let layoutEngine = TreeMapLayoutEngine.shared
    private let colorManager = ColorManager.shared
    private let smallFilesMerger = SmallFilesMerger.shared
    private let animationController = AnimationController.shared
    
    public var treeMapView: TreeMapView?
    
    // 回调
    public var onRectClicked: ((TreeMapRect) -> Void)?
    public var onRectHovered: ((TreeMapRect?) -> Void)?
    
    private init() {}
    
    /// 设置TreeMap视图
    public func setTreeMapView(_ view: TreeMapView) {
        treeMapView = view
        
        // 设置回调
        view.onRectClicked = { [weak self] rect in
            self?.onRectClicked?(rect)
        }
        
        view.onRectHovered = { [weak self] rect in
            self?.onRectHovered?(rect)
        }
    }
    
    /// 更新数据
    public func updateData(_ node: FileNode) {
        treeMapView?.setData(node)
    }
    
    /// 清除缓存
    public func clearCache() {
        layoutEngine.clearCache()
    }
    
    /// 获取性能统计
    public func getPerformanceStatistics() -> (cacheCount: Int, memoryUsage: Int) {
        let stats = layoutEngine.getCacheStatistics()
        return (cacheCount: stats.count, memoryUsage: stats.memoryUsage)
    }
}
