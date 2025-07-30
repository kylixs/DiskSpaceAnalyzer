import Foundation
import CoreGraphics

/// TreeMap可视化模块 - 统一的TreeMap管理接口
public class TreeMapVisualization {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = TreeMapVisualization()
    
    /// 布局引擎
    public let layoutEngine: TreeMapLayoutEngine
    
    /// 动画控制器
    public let animationController: AnimationController
    
    /// 当前布局结果
    public private(set) var currentLayout: TreeMapLayoutResult?
    
    // MARK: - Initialization
    
    private init() {
        self.layoutEngine = TreeMapLayoutEngine.shared
        self.animationController = AnimationController()
    }
    
    // MARK: - Public Methods
    
    /// 计算并显示TreeMap
    public func displayTreeMap(for rootNode: FileNode, in bounds: CGRect, completion: @escaping (TreeMapLayoutResult) -> Void) {
        layoutEngine.calculateLayout(for: rootNode, in: bounds) { [weak self] result in
            self?.currentLayout = result
            completion(result)
        }
    }
    
    /// 获取当前布局
    public func getCurrentLayout() -> TreeMapLayoutResult? {
        return currentLayout
    }
}
