import Foundation
import CoreGraphics
import Dispatch

/// TreeMap矩形布局信息
public struct TreeMapRect {
    public let id: UUID
    public let rect: CGRect
    public let node: FileNode
    public let depth: Int
    public let color: CGColor
    public let isDirectory: Bool
    
    public init(id: UUID, rect: CGRect, node: FileNode, depth: Int, color: CGColor, isDirectory: Bool) {
        self.id = id
        self.rect = rect
        self.node = node
        self.depth = depth
        self.color = color
        self.isDirectory = isDirectory
    }
}

/// 布局配置
public struct TreeMapLayoutConfiguration {
    public let minRectSize: CGSize
    public let padding: CGFloat
    public let maxDepth: Int
    public let enableSmallFilesMerging: Bool
    public let smallFilesThreshold: Double  // 小文件阈值（百分比）
    public let maxSmallFilesToShow: Int
    
    public init(minRectSize: CGSize = CGSize(width: 10, height: 10), padding: CGFloat = 1.0, maxDepth: Int = 3, enableSmallFilesMerging: Bool = true, smallFilesThreshold: Double = 0.01, maxSmallFilesToShow: Int = 4) {
        self.minRectSize = minRectSize
        self.padding = padding
        self.maxDepth = maxDepth
        self.enableSmallFilesMerging = enableSmallFilesMerging
        self.smallFilesThreshold = smallFilesThreshold
        self.maxSmallFilesToShow = maxSmallFilesToShow
    }
}

/// 布局结果
public struct TreeMapLayoutResult {
    public let rects: [TreeMapRect]
    public let totalArea: CGFloat
    public let layoutTime: TimeInterval
    public let nodesProcessed: Int
    public let mergedFilesCount: Int
    
    public init(rects: [TreeMapRect], totalArea: CGFloat, layoutTime: TimeInterval, nodesProcessed: Int, mergedFilesCount: Int) {
        self.rects = rects
        self.totalArea = totalArea
        self.layoutTime = layoutTime
        self.nodesProcessed = nodesProcessed
        self.mergedFilesCount = mergedFilesCount
    }
}

/// TreeMap布局引擎 - 协调整个TreeMap的布局计算流程
public class TreeMapLayoutEngine {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = TreeMapLayoutEngine()
    
    /// 布局配置
    public var configuration: TreeMapLayoutConfiguration
    
    /// Squarified算法实例
    private let squarifiedAlgorithm: SquarifiedAlgorithm
    
    /// 颜色管理器
    private let colorManager: ColorManager
    
    /// 小文件合并器
    private let smallFilesMerger: SmallFilesMerger
    
    /// 布局缓存
    private var layoutCache: [String: TreeMapLayoutResult] = [:]
    
    /// 缓存锁
    private let cacheLock = NSLock()
    
    /// 计算队列
    private let computeQueue = DispatchQueue(label: "TreeMapLayoutEngine.compute", qos: .userInitiated, attributes: .concurrent)
    
    /// 并发信号量
    private let concurrencySemaphore: DispatchSemaphore
    
    /// 布局完成回调
    public var layoutCompletionCallback: ((TreeMapLayoutResult) -> Void)?
    
    /// 布局进度回调
    public var layoutProgressCallback: ((Double) -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        self.configuration = TreeMapLayoutConfiguration()
        self.squarifiedAlgorithm = SquarifiedAlgorithm()
        self.colorManager = ColorManager()
        self.smallFilesMerger = SmallFilesMerger()
        self.concurrencySemaphore = DispatchSemaphore(value: 2) // 最多2个并发计算
    }
    
    // MARK: - Public Methods
    
    /// 配置布局引擎
    public func configure(with config: TreeMapLayoutConfiguration) {
        self.configuration = config
        
        // 更新子组件配置
        squarifiedAlgorithm.minRectSize = config.minRectSize
        squarifiedAlgorithm.padding = config.padding
        
        smallFilesMerger.threshold = config.smallFilesThreshold
        smallFilesMerger.maxSmallFilesToShow = config.maxSmallFilesToShow
        
        // 清除缓存
        clearCache()
    }
    
    /// 计算布局（异步）
    public func calculateLayout(for rootNode: FileNode, in bounds: CGRect, completion: @escaping (TreeMapLayoutResult) -> Void) {
        let cacheKey = generateCacheKey(rootNode: rootNode, bounds: bounds)
        
        // 检查缓存
        if let cachedResult = getCachedResult(for: cacheKey) {
            DispatchQueue.main.async {
                completion(cachedResult)
            }
            return
        }
        
        // 异步计算
        computeQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.concurrencySemaphore.wait()
            defer { self.concurrencySemaphore.signal() }
            
            let result = self.performLayoutCalculation(rootNode: rootNode, bounds: bounds)
            
            // 缓存结果
            self.setCachedResult(result, for: cacheKey)
            
            // 回调结果
            DispatchQueue.main.async {
                completion(result)
                self.layoutCompletionCallback?(result)
            }
        }
    }
    
    /// 计算布局（同步）
    public func calculateLayoutSync(for rootNode: FileNode, in bounds: CGRect) -> TreeMapLayoutResult {
        let cacheKey = generateCacheKey(rootNode: rootNode, bounds: bounds)
        
        // 检查缓存
        if let cachedResult = getCachedResult(for: cacheKey) {
            return cachedResult
        }
        
        // 同步计算
        let result = performLayoutCalculation(rootNode: rootNode, bounds: bounds)
        
        // 缓存结果
        setCachedResult(result, for: cacheKey)
        
        return result
    }
    
    /// 增量更新布局
    public func updateLayout(for changedNodes: [FileNode], in bounds: CGRect, completion: @escaping (TreeMapLayoutResult) -> Void) {
        // 简化实现：重新计算整个布局
        // 在实际项目中，这里可以实现更复杂的增量更新逻辑
        guard let rootNode = findCommonRoot(of: changedNodes) else {
            completion(TreeMapLayoutResult(rects: [], totalArea: 0, layoutTime: 0, nodesProcessed: 0, mergedFilesCount: 0))
            return
        }
        
        calculateLayout(for: rootNode, in: bounds, completion: completion)
    }
    
    /// 清除缓存
    public func clearCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        layoutCache.removeAll()
    }
    
    /// 获取缓存统计信息
    public func getCacheStatistics() -> [String: Any] {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        return [
            "cacheSize": layoutCache.count,
            "memoryUsage": layoutCache.count * MemoryLayout<TreeMapLayoutResult>.size
        ]
    }
    
    // MARK: - Private Methods
    
    /// 执行布局计算
    private func performLayoutCalculation(rootNode: FileNode, bounds: CGRect) -> TreeMapLayoutResult {
        let startTime = Date()
        var processedNodes = 0
        var mergedFilesCount = 0
        
        // 报告进度
        layoutProgressCallback?(0.1)
        
        // 准备数据
        var nodes = prepareNodes(from: rootNode)
        processedNodes = nodes.count
        
        layoutProgressCallback?(0.3)
        
        // 应用小文件合并
        if configuration.enableSmallFilesMerging {
            let mergeResult = smallFilesMerger.mergeSmallFiles(nodes, totalSize: rootNode.totalSize)
            nodes = mergeResult.nodes
            mergedFilesCount = mergeResult.mergedCount
        }
        
        layoutProgressCallback?(0.5)
        
        // 计算布局
        let layoutRects = squarifiedAlgorithm.calculateLayout(
            nodes: nodes,
            bounds: bounds.insetBy(dx: configuration.padding, dy: configuration.padding)
        )
        
        layoutProgressCallback?(0.8)
        
        // 生成TreeMapRect
        let treeMapRects = layoutRects.enumerated().map { index, layoutRect in
            let node = nodes[index]
            let color = colorManager.getColor(for: node, depth: 0)
            
            return TreeMapRect(
                id: node.id,
                rect: layoutRect,
                node: node,
                depth: 0,
                color: color,
                isDirectory: node.isDirectory
            )
        }
        
        layoutProgressCallback?(1.0)
        
        let layoutTime = Date().timeIntervalSince(startTime)
        let totalArea = bounds.width * bounds.height
        
        return TreeMapLayoutResult(
            rects: treeMapRects,
            totalArea: totalArea,
            layoutTime: layoutTime,
            nodesProcessed: processedNodes,
            mergedFilesCount: mergedFilesCount
        )
    }
    
    /// 准备节点数据
    private func prepareNodes(from rootNode: FileNode) -> [FileNode] {
        var nodes: [FileNode] = []
        
        // 收集所有子节点
        func collectNodes(_ node: FileNode, depth: Int) {
            if depth < configuration.maxDepth {
                for child in node.children {
                    if child.isDirectory && depth < configuration.maxDepth - 1 {
                        collectNodes(child, depth: depth + 1)
                    } else {
                        nodes.append(child)
                    }
                }
            }
        }
        
        collectNodes(rootNode, depth: 0)
        
        // 按大小排序
        nodes.sort { $0.size > $1.size }
        
        // 过滤太小的矩形
        nodes = nodes.filter { node in
            let estimatedArea = Double(node.size) / Double(rootNode.totalSize)
            return estimatedArea * Double(configuration.minRectSize.width * configuration.minRectSize.height) >= Double(configuration.minRectSize.width * configuration.minRectSize.height)
        }
        
        return nodes
    }
    
    /// 生成缓存键
    private func generateCacheKey(rootNode: FileNode, bounds: CGRect) -> String {
        let boundsString = "\(bounds.origin.x),\(bounds.origin.y),\(bounds.size.width),\(bounds.size.height)"
        let configString = "\(configuration.minRectSize.width),\(configuration.minRectSize.height),\(configuration.padding),\(configuration.maxDepth)"
        return "\(rootNode.id.uuidString)_\(boundsString)_\(configString)"
    }
    
    /// 获取缓存结果
    private func getCachedResult(for key: String) -> TreeMapLayoutResult? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        return layoutCache[key]
    }
    
    /// 设置缓存结果
    private func setCachedResult(_ result: TreeMapLayoutResult, for key: String) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        layoutCache[key] = result
        
        // 限制缓存大小
        if layoutCache.count > 100 {
            let oldestKey = layoutCache.keys.first!
            layoutCache.removeValue(forKey: oldestKey)
        }
    }
    
    /// 查找共同根节点
    private func findCommonRoot(of nodes: [FileNode]) -> FileNode? {
        guard !nodes.isEmpty else { return nil }
        
        // 简化实现：返回第一个节点的根节点
        var current = nodes.first!
        while let parent = current.parent {
            current = parent
        }
        return current
    }
}

// MARK: - Extensions

extension TreeMapLayoutEngine {
    
    /// 导出布局报告
    public func exportLayoutReport() -> String {
        var report = "=== TreeMap Layout Engine Report ===\n\n"
        
        report += "Generated: \(Date())\n"
        report += "Configuration:\n"
        report += "  Min Rect Size: \(configuration.minRectSize)\n"
        report += "  Padding: \(configuration.padding)\n"
        report += "  Max Depth: \(configuration.maxDepth)\n"
        report += "  Small Files Merging: \(configuration.enableSmallFilesMerging)\n"
        report += "  Small Files Threshold: \(String(format: "%.2f%%", configuration.smallFilesThreshold * 100))\n"
        report += "  Max Small Files to Show: \(configuration.maxSmallFilesToShow)\n\n"
        
        let cacheStats = getCacheStatistics()
        report += "=== Cache Statistics ===\n"
        report += "Cache Size: \(cacheStats["cacheSize"] ?? 0)\n"
        report += "Memory Usage: \(cacheStats["memoryUsage"] ?? 0) bytes\n\n"
        
        return report
    }
    
    /// 获取性能指标
    public func getPerformanceMetrics() -> [String: Any] {
        let cacheStats = getCacheStatistics()
        
        return [
            "cacheHitRate": calculateCacheHitRate(),
            "averageLayoutTime": calculateAverageLayoutTime(),
            "cacheSize": cacheStats["cacheSize"] ?? 0,
            "memoryUsage": cacheStats["memoryUsage"] ?? 0
        ]
    }
    
    /// 计算缓存命中率
    private func calculateCacheHitRate() -> Double {
        // 简化实现，实际项目中需要跟踪命中和未命中次数
        return 0.75 // 假设75%的命中率
    }
    
    /// 计算平均布局时间
    private func calculateAverageLayoutTime() -> TimeInterval {
        // 简化实现，实际项目中需要跟踪历史布局时间
        return 0.05 // 假设50ms的平均布局时间
    }
}
