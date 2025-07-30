import Foundation
import CoreGraphics
import AppKit

/// 颜色管理器 - 基于HSB颜色模型实现同色系深浅变化
public class ColorManager {
    
    // MARK: - Properties
    
    /// 目录颜色色相 (蓝色系)
    private let directoryHue: CGFloat = 240.0 / 360.0  // 240度
    
    /// 文件颜色色相 (橙色系)
    private let fileHue: CGFloat = 30.0 / 360.0   // 30度
    
    /// 饱和度范围
    private let saturationRange: ClosedRange<CGFloat> = 0.2...0.8
    
    /// 亮度范围
    private let brightnessRange: ClosedRange<CGFloat> = 0.3...0.7
    
    /// 当前外观模式
    private var isDarkMode: Bool {
        return NSApp.effectiveAppearance.name == .darkAqua
    }
    
    // MARK: - Public Methods
    
    /// 获取节点颜色
    public func getColor(for node: FileNode, depth: Int = 0) -> CGColor {
        let baseHue = node.isDirectory ? directoryHue : fileHue
        
        // 根据文件大小计算颜色深度
        let sizeRatio = calculateSizeRatio(for: node)
        
        // 计算饱和度和亮度
        let saturation = saturationRange.lowerBound + (saturationRange.upperBound - saturationRange.lowerBound) * sizeRatio
        var brightness = brightnessRange.lowerBound + (brightnessRange.upperBound - brightnessRange.lowerBound) * (1.0 - sizeRatio)
        
        // 深色模式调整
        if isDarkMode {
            brightness = min(brightness + 0.2, 1.0)
        }
        
        let color = NSColor(hue: baseHue, saturation: saturation, brightness: brightness, alpha: 1.0)
        return color.cgColor
    }
    
    /// 获取高亮颜色
    public func getHighlightColor(for node: FileNode) -> CGColor {
        let baseColor = getColor(for: node)
        
        // 增加亮度作为高亮效果
        if let nsColor = NSColor(cgColor: baseColor) {
            let highlightColor = nsColor.blended(withFraction: 0.3, of: .white) ?? nsColor
            return highlightColor.cgColor
        }
        
        return baseColor
    }
    
    /// 获取选中颜色
    public func getSelectedColor(for node: FileNode) -> CGColor {
        return NSColor.controlAccentColor.cgColor
    }
    
    // MARK: - Private Methods
    
    /// 计算大小比例（使用对数缩放）
    private func calculateSizeRatio(for node: FileNode) -> CGFloat {
        guard let parent = node.parent else { return 0.5 }
        
        let parentSize = parent.totalSize
        guard parentSize > 0 else { return 0.5 }
        
        let ratio = Double(node.size) / Double(parentSize)
        
        // 使用对数缩放避免极值
        let logRatio = log10(max(ratio, 0.0001)) / log10(1.0)
        let normalizedRatio = max(0.0, min(1.0, (logRatio + 4.0) / 4.0))
        
        return CGFloat(normalizedRatio)
    }
}
