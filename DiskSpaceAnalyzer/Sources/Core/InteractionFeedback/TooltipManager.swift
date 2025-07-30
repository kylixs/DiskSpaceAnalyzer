import Foundation
import AppKit
import CoreGraphics

/// Tooltip内容配置
public struct TooltipContent {
    public let title: String
    public let subtitle: String?
    public let details: [String: String]
    public let icon: NSImage?
    
    public init(title: String, subtitle: String? = nil, details: [String: String] = [:], icon: NSImage? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.details = details
        self.icon = icon
    }
}

/// Tooltip显示配置
public struct TooltipConfiguration {
    public let showDelay: TimeInterval
    public let hideDelay: TimeInterval
    public let maxWidth: CGFloat
    public let backgroundColor: NSColor
    public let textColor: NSColor
    public let borderColor: NSColor
    public let cornerRadius: CGFloat
    
    public init(showDelay: TimeInterval = 0.3, hideDelay: TimeInterval = 0.1, maxWidth: CGFloat = 300, backgroundColor: NSColor = NSColor.controlBackgroundColor, textColor: NSColor = NSColor.controlTextColor, borderColor: NSColor = NSColor.separatorColor, cornerRadius: CGFloat = 8.0) {
        self.showDelay = showDelay
        self.hideDelay = hideDelay
        self.maxWidth = maxWidth
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
    }
}

/// Tooltip管理器 - 实现智能tooltip显示系统
public class TooltipManager: NSObject {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = TooltipManager()
    
    /// 配置
    public var configuration: TooltipConfiguration
    
    /// 当前显示的popover
    private var currentPopover: NSPopover?
    
    /// 显示定时器
    private var showTimer: Timer?
    
    /// 隐藏定时器
    private var hideTimer: Timer?
    
    /// 当前目标视图
    private weak var targetView: NSView?
    
    /// 当前鼠标位置
    private var currentMouseLocation: CGPoint = .zero
    
    /// 坐标转换器
    private let coordinateTransformer: CoordinateTransformer
    
    /// 字节格式化器
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter
    }()
    
    // MARK: - Initialization
    
    private override init() {
        self.configuration = TooltipConfiguration()
        self.coordinateTransformer = CoordinateTransformer.shared
        super.init()
    }
    
    // MARK: - Public Methods
    
    /// 配置tooltip管理器
    public func configure(with config: TooltipConfiguration) {
        self.configuration = config
    }
    
    /// 显示tooltip
    public func showTooltip(for rect: TreeMapRect, at point: CGPoint, in view: NSView) {
        // 取消之前的定时器
        cancelTimers()
        
        // 保存当前状态
        targetView = view
        currentMouseLocation = point
        
        // 延迟显示
        showTimer = Timer.scheduledTimer(withTimeInterval: configuration.showDelay, repeats: false) { [weak self] _ in
            self?.displayTooltip(for: rect, at: point, in: view)
        }
    }
    
    /// 隐藏tooltip
    public func hideTooltip() {
        cancelTimers()
        
        hideTimer = Timer.scheduledTimer(withTimeInterval: configuration.hideDelay, repeats: false) { [weak self] _ in
            self?.dismissTooltip()
        }
    }
    
    /// 立即隐藏tooltip
    public func hideTooltipImmediately() {
        cancelTimers()
        dismissTooltip()
    }
    
    /// 更新tooltip位置
    public func updateTooltipPosition(_ point: CGPoint) {
        currentMouseLocation = point
        
        guard let popover = currentPopover,
              let view = targetView else { return }
        
        // 重新计算位置
        let adjustedPoint = calculateTooltipPosition(point, in: view)
        popover.show(relativeTo: CGRect(origin: adjustedPoint, size: CGSize(width: 1, height: 1)), of: view, preferredEdge: .minY)
    }
    
    // MARK: - Private Methods
    
    /// 显示tooltip
    private func displayTooltip(for rect: TreeMapRect, at point: CGPoint, in view: NSView) {
        // 创建tooltip内容
        let content = createTooltipContent(for: rect)
        
        // 创建popover
        let popover = createPopover(with: content)
        
        // 计算显示位置
        let adjustedPoint = calculateTooltipPosition(point, in: view)
        
        // 显示popover
        popover.show(relativeTo: CGRect(origin: adjustedPoint, size: CGSize(width: 1, height: 1)), of: view, preferredEdge: .minY)
        
        currentPopover = popover
    }
    
    /// 创建tooltip内容
    private func createTooltipContent(for rect: TreeMapRect) -> TooltipContent {
        let node = rect.node
        
        var details: [String: String] = [:]
        
        // 基本信息
        details["大小"] = byteFormatter.string(fromByteCount: node.size)
        details["类型"] = node.isDirectory ? "目录" : "文件"
        details["路径"] = node.path
        
        // 时间信息
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        details["创建时间"] = dateFormatter.string(from: node.createdDate)
        details["修改时间"] = dateFormatter.string(from: node.modifiedDate)
        
        // 权限信息
        let permissions = node.permissions
        details["权限"] = "\(permissions.owner.description) \(permissions.group.description) \(permissions.others.description)"
        
        // 目录特有信息
        if node.isDirectory {
            details["子项数量"] = "\(node.children.count)"
            if node.totalSize != node.size {
                details["总大小"] = byteFormatter.string(fromByteCount: node.totalSize)
            }
        }
        
        // 获取文件图标
        let icon = NSWorkspace.shared.icon(forFile: node.path)
        
        return TooltipContent(
            title: node.name,
            subtitle: node.isDirectory ? "目录" : "文件",
            details: details,
            icon: icon
        )
    }
    
    /// 创建popover
    private func createPopover(with content: TooltipContent) -> NSPopover {
        let popover = NSPopover()
        popover.contentViewController = createTooltipViewController(with: content)
        popover.behavior = .transient
        popover.animates = true
        
        return popover
    }
    
    /// 创建tooltip视图控制器
    private func createTooltipViewController(with content: TooltipContent) -> NSViewController {
        let viewController = NSViewController()
        let containerView = NSView()
        
        // 设置背景
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = configuration.backgroundColor.cgColor
        containerView.layer?.borderColor = configuration.borderColor.cgColor
        containerView.layer?.borderWidth = 1.0
        containerView.layer?.cornerRadius = configuration.cornerRadius
        
        // 创建内容视图
        let contentView = createContentView(with: content)
        containerView.addSubview(contentView)
        
        // 设置约束
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            contentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            contentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            contentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: configuration.maxWidth)
        ])
        
        viewController.view = containerView
        return viewController
    }
    
    /// 创建内容视图
    private func createContentView(with content: TooltipContent) -> NSView {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 4
        
        // 标题行
        let titleRow = NSStackView()
        titleRow.orientation = .horizontal
        titleRow.alignment = .centerY
        titleRow.spacing = 8
        
        // 图标
        if let icon = content.icon {
            let imageView = NSImageView(image: icon)
            imageView.imageScaling = .scaleProportionallyUpOrDown
            imageView.setContentHuggingPriority(.required, for: .horizontal)
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 16),
                imageView.heightAnchor.constraint(equalToConstant: 16)
            ])
            titleRow.addArrangedSubview(imageView)
        }
        
        // 标题
        let titleLabel = NSTextField(labelWithString: content.title)
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = configuration.textColor
        titleRow.addArrangedSubview(titleLabel)
        
        stackView.addArrangedSubview(titleRow)
        
        // 副标题
        if let subtitle = content.subtitle {
            let subtitleLabel = NSTextField(labelWithString: subtitle)
            subtitleLabel.font = NSFont.systemFont(ofSize: 11)
            subtitleLabel.textColor = configuration.textColor.withAlphaComponent(0.7)
            stackView.addArrangedSubview(subtitleLabel)
        }
        
        // 详细信息
        if !content.details.isEmpty {
            let separator = NSBox()
            separator.boxType = .separator
            stackView.addArrangedSubview(separator)
            
            for (key, value) in content.details {
                let detailRow = NSStackView()
                detailRow.orientation = .horizontal
                detailRow.spacing = 8
                
                let keyLabel = NSTextField(labelWithString: "\(key):")
                keyLabel.font = NSFont.systemFont(ofSize: 11)
                keyLabel.textColor = configuration.textColor.withAlphaComponent(0.7)
                keyLabel.setContentHuggingPriority(.required, for: .horizontal)
                
                let valueLabel = NSTextField(labelWithString: value)
                valueLabel.font = NSFont.systemFont(ofSize: 11)
                valueLabel.textColor = configuration.textColor
                valueLabel.lineBreakMode = .byTruncatingMiddle
                
                detailRow.addArrangedSubview(keyLabel)
                detailRow.addArrangedSubview(valueLabel)
                
                stackView.addArrangedSubview(detailRow)
            }
        }
        
        return stackView
    }
    
    /// 计算tooltip位置
    private func calculateTooltipPosition(_ point: CGPoint, in view: NSView) -> CGPoint {
        // 获取屏幕边界
        guard let screen = view.window?.screen ?? NSScreen.main else {
            return point
        }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = view.window?.frame ?? .zero
        
        // 转换到屏幕坐标
        let screenPoint = view.convert(point, to: nil)
        let globalPoint = view.window?.convertToScreen(CGRect(origin: screenPoint, size: .zero)).origin ?? point
        
        var adjustedPoint = point
        
        // 检查右边界
        if globalPoint.x + configuration.maxWidth > screenFrame.maxX {
            adjustedPoint.x = point.x - configuration.maxWidth
        }
        
        // 检查下边界
        if globalPoint.y - 100 < screenFrame.minY { // 假设tooltip高度约100
            adjustedPoint.y = point.y + 20 // 显示在鼠标下方
        }
        
        return adjustedPoint
    }
    
    /// 取消定时器
    private func cancelTimers() {
        showTimer?.invalidate()
        hideTimer?.invalidate()
        showTimer = nil
        hideTimer = nil
    }
    
    /// 关闭tooltip
    private func dismissTooltip() {
        currentPopover?.close()
        currentPopover = nil
        targetView = nil
    }
}

// MARK: - Extensions

extension TooltipManager {
    
    /// 获取tooltip统计信息
    public func getTooltipStatistics() -> [String: Any] {
        return [
            "isVisible": currentPopover != nil,
            "showDelay": configuration.showDelay,
            "hideDelay": configuration.hideDelay,
            "maxWidth": configuration.maxWidth,
            "hasTargetView": targetView != nil
        ]
    }
    
    /// 导出tooltip报告
    public func exportTooltipReport() -> String {
        var report = "=== Tooltip Manager Report ===\n\n"
        
        let stats = getTooltipStatistics()
        
        report += "Generated: \(Date())\n"
        report += "Is Visible: \(stats["isVisible"] ?? false)\n"
        report += "Show Delay: \(stats["showDelay"] ?? 0)s\n"
        report += "Hide Delay: \(stats["hideDelay"] ?? 0)s\n"
        report += "Max Width: \(stats["maxWidth"] ?? 0)pt\n"
        report += "Has Target View: \(stats["hasTargetView"] ?? false)\n\n"
        
        report += "=== Configuration ===\n"
        report += "Background Color: \(configuration.backgroundColor)\n"
        report += "Text Color: \(configuration.textColor)\n"
        report += "Border Color: \(configuration.borderColor)\n"
        report += "Corner Radius: \(configuration.cornerRadius)pt\n\n"
        
        return report
    }
}

// MARK: - PermissionSet Extension

extension PermissionSet {
    var description: String {
        var result = ""
        result += read ? "r" : "-"
        result += write ? "w" : "-"
        result += execute ? "x" : "-"
        return result
    }
}
