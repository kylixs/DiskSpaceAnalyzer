import Foundation
import CoreGraphics

/// Squarified TreeMap算法实现
public class SquarifiedAlgorithm {
    
    // MARK: - Properties
    
    /// 最小矩形大小
    public var minRectSize: CGSize = CGSize(width: 10, height: 10)
    
    /// 内边距
    public var padding: CGFloat = 1.0
    
    /// 算法统计信息
    public private(set) var statistics = AlgorithmStatistics()
    
    // MARK: - Public Methods
    
    /// 计算TreeMap布局
    public func calculateLayout(nodes: [FileNode], bounds: CGRect) -> [CGRect] {
        let startTime = Date()
        statistics.reset()
        
        guard !nodes.isEmpty else {
            return []
        }
        
        // 计算总面积
        let totalSize = nodes.reduce(0) { $0 + $1.size }
        guard totalSize > 0 else {
            return Array(repeating: CGRect.zero, count: nodes.count)
        }
        
        // 计算每个节点的面积
        let areas = nodes.map { node in
            Double(node.size) / Double(totalSize) * Double(bounds.width * bounds.height)
        }
        
        // 执行Squarified算法
        let rects = squarify(areas: areas, bounds: bounds)
        
        // 更新统计信息
        statistics.executionTime = Date().timeIntervalSince(startTime)
        statistics.nodesProcessed = nodes.count
        statistics.totalArea = Double(bounds.width * bounds.height)
        statistics.averageAspectRatio = calculateAverageAspectRatio(rects)
        
        return rects
    }
    
    /// 获取算法统计信息
    public func getStatistics() -> AlgorithmStatistics {
        return statistics
    }
    
    /// 重置统计信息
    public func resetStatistics() {
        statistics.reset()
    }
    
    // MARK: - Private Methods
    
    /// Squarified算法核心实现
    private func squarify(areas: [Double], bounds: CGRect) -> [CGRect] {
        guard !areas.isEmpty else { return [] }
        
        var result: [CGRect] = []
        var remainingAreas = areas
        var currentBounds = bounds
        
        while !remainingAreas.isEmpty {
            // 找到最佳的行或列
            let (rowAreas, remainingAfterRow) = findBestRow(areas: remainingAreas, bounds: currentBounds)
            
            // 为这一行/列生成矩形
            let rowRects = layoutRow(areas: rowAreas, bounds: currentBounds)
            result.append(contentsOf: rowRects)
            
            // 更新剩余区域
            if !remainingAfterRow.isEmpty {
                currentBounds = calculateRemainingBounds(
                    originalBounds: currentBounds,
                    usedRects: rowRects
                )
            }
            
            remainingAreas = remainingAfterRow
        }
        
        return result
    }
    
    /// 找到最佳的行或列
    private func findBestRow(areas: [Double], bounds: CGRect) -> ([Double], [Double]) {
        guard !areas.isEmpty else { return ([], []) }
        
        var bestRow: [Double] = [areas[0]]
        var bestRemainder = Array(areas.dropFirst())
        var bestWorstRatio = Double.infinity
        
        // 尝试不同的行长度
        for i in 1...areas.count {
            let currentRow = Array(areas.prefix(i))
            let remainder = Array(areas.dropFirst(i))
            
            let worstRatio = calculateWorstAspectRatio(areas: currentRow, bounds: bounds)
            
            if worstRatio < bestWorstRatio {
                bestWorstRatio = worstRatio
                bestRow = currentRow
                bestRemainder = remainder
            } else {
                // 如果长宽比开始变差，停止尝试
                break
            }
        }
        
        return (bestRow, bestRemainder)
    }
    
    /// 为一行/列布局矩形
    private func layoutRow(areas: [Double], bounds: CGRect) -> [CGRect] {
        guard !areas.isEmpty else { return [] }
        
        let totalArea = areas.reduce(0, +)
        let isHorizontal = bounds.width >= bounds.height
        
        var rects: [CGRect] = []
        var currentPosition: CGFloat = 0
        
        if isHorizontal {
            // 水平布局
            let rowHeight = CGFloat(totalArea / Double(bounds.width))
            
            for area in areas {
                let rectWidth = CGFloat(area / Double(rowHeight))
                let rect = CGRect(
                    x: bounds.minX + currentPosition,
                    y: bounds.minY,
                    width: rectWidth,
                    height: rowHeight
                )
                rects.append(rect)
                currentPosition += rectWidth
            }
        } else {
            // 垂直布局
            let rowWidth = CGFloat(totalArea / Double(bounds.height))
            
            for area in areas {
                let rectHeight = CGFloat(area / Double(rowWidth))
                let rect = CGRect(
                    x: bounds.minX,
                    y: bounds.minY + currentPosition,
                    width: rowWidth,
                    height: rectHeight
                )
                rects.append(rect)
                currentPosition += rectHeight
            }
        }
        
        return rects
    }
    
    /// 计算剩余边界
    private func calculateRemainingBounds(originalBounds: CGRect, usedRects: [CGRect]) -> CGRect {
        guard let firstRect = usedRects.first else { return originalBounds }
        
        let isHorizontal = originalBounds.width >= originalBounds.height
        
        if isHorizontal {
            // 水平布局，剩余区域在右侧
            return CGRect(
                x: firstRect.maxX,
                y: originalBounds.minY,
                width: originalBounds.maxX - firstRect.maxX,
                height: originalBounds.height
            )
        } else {
            // 垂直布局，剩余区域在下方
            return CGRect(
                x: originalBounds.minX,
                y: firstRect.maxY,
                width: originalBounds.width,
                height: originalBounds.maxY - firstRect.maxY
            )
        }
    }
    
    /// 计算最差长宽比
    private func calculateWorstAspectRatio(areas: [Double], bounds: CGRect) -> Double {
        guard !areas.isEmpty else { return Double.infinity }
        
        let totalArea = areas.reduce(0, +)
        let isHorizontal = bounds.width >= bounds.height
        
        var worstRatio = 0.0
        
        if isHorizontal {
            let rowHeight = totalArea / Double(bounds.width)
            
            for area in areas {
                let rectWidth = area / rowHeight
                let ratio = max(rectWidth / rowHeight, rowHeight / rectWidth)
                worstRatio = max(worstRatio, ratio)
            }
        } else {
            let rowWidth = totalArea / Double(bounds.height)
            
            for area in areas {
                let rectHeight = area / rowWidth
                let ratio = max(rowWidth / rectHeight, rectHeight / rowWidth)
                worstRatio = max(worstRatio, ratio)
            }
        }
        
        return worstRatio
    }
    
    /// 计算平均长宽比
    private func calculateAverageAspectRatio(_ rects: [CGRect]) -> Double {
        guard !rects.isEmpty else { return 0.0 }
        
        let totalRatio = rects.reduce(0.0) { sum, rect in
            let ratio = max(rect.width / rect.height, rect.height / rect.width)
            return sum + Double(ratio)
        }
        
        return totalRatio / Double(rects.count)
    }
}

// MARK: - Supporting Types

/// 算法统计信息
public struct AlgorithmStatistics {
    public var executionTime: TimeInterval = 0
    public var nodesProcessed: Int = 0
    public var totalArea: Double = 0
    public var averageAspectRatio: Double = 0
    public var recursionDepth: Int = 0
    
    public mutating func reset() {
        executionTime = 0
        nodesProcessed = 0
        totalArea = 0
        averageAspectRatio = 0
        recursionDepth = 0
    }
}

// MARK: - Extensions

extension SquarifiedAlgorithm {
    
    /// 验证布局结果
    public func validateLayout(_ rects: [CGRect], originalBounds: CGRect) -> ValidationResult {
        var result = ValidationResult()
        
        // 检查矩形是否在边界内
        for rect in rects {
            if !originalBounds.contains(rect) {
                result.errors.append("Rectangle \(rect) is outside bounds \(originalBounds)")
            }
        }
        
        // 检查矩形是否重叠
        for i in 0..<rects.count {
            for j in (i+1)..<rects.count {
                if rects[i].intersects(rects[j]) {
                    result.warnings.append("Rectangles \(i) and \(j) intersect")
                }
            }
        }
        
        // 检查面积利用率
        let totalRectArea = rects.reduce(0) { $0 + $1.width * $1.height }
        let boundsArea = originalBounds.width * originalBounds.height
        let utilization = Double(totalRectArea / boundsArea)
        
        result.areaUtilization = utilization
        
        if utilization < 0.95 {
            result.warnings.append("Low area utilization: \(String(format: "%.2f%%", utilization * 100))")
        }
        
        return result
    }
    
    /// 导出算法报告
    public func exportAlgorithmReport() -> String {
        var report = "=== Squarified Algorithm Report ===\n\n"
        
        let stats = getStatistics()
        
        report += "Generated: \(Date())\n"
        report += "Configuration:\n"
        report += "  Min Rect Size: \(minRectSize)\n"
        report += "  Padding: \(padding)\n\n"
        
        report += "=== Performance Statistics ===\n"
        report += "Execution Time: \(String(format: "%.3f ms", stats.executionTime * 1000))\n"
        report += "Nodes Processed: \(stats.nodesProcessed)\n"
        report += "Total Area: \(String(format: "%.0f", stats.totalArea))\n"
        report += "Average Aspect Ratio: \(String(format: "%.2f", stats.averageAspectRatio))\n"
        report += "Recursion Depth: \(stats.recursionDepth)\n\n"
        
        return report
    }
}

/// 验证结果
public struct ValidationResult {
    public var errors: [String] = []
    public var warnings: [String] = []
    public var areaUtilization: Double = 0.0
    
    public var isValid: Bool {
        return errors.isEmpty
    }
}
