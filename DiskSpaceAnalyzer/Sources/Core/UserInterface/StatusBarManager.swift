import Foundation
import AppKit

/// 状态栏管理器 - 管理底部状态栏的显示
public class StatusBarManager {
    
    // MARK: - Properties
    
    /// 状态栏视图
    private var statusBar: NSView!
    
    /// 状态标签
    private var statusLabel: NSTextField!
    
    /// 统计标签
    private var statisticsLabel: NSTextField!
    
    /// 错误标签
    private var errorLabel: NSTextField!
    
    /// 进度标签
    private var progressLabel: NSTextField!
    
    /// 字节格式化器
    private let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter
    }()
    
    // MARK: - Initialization
    
    public init() {
        createStatusBar()
    }
    
    // MARK: - Public Methods
    
    /// 获取状态栏视图
    public func getStatusBar() -> NSView {
        return statusBar
    }
    
    /// 更新扫描状态
    public func updateStatus(_ status: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.stringValue = "📊 状态: \(status)"
        }
    }
    
    /// 更新统计信息
    public func updateStatistics(fileCount: Int, totalSize: Int64) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let sizeString = self.byteFormatter.string(fromByteCount: totalSize)
            self.statisticsLabel.stringValue = "📁 \(fileCount) 文件 | 💾 \(sizeString)"
        }
    }
    
    /// 更新错误信息
    public func updateErrors(errorCount: Int) {
        DispatchQueue.main.async { [weak self] in
            if errorCount > 0 {
                self?.errorLabel.stringValue = "⚠️ \(errorCount) 个错误"
                self?.errorLabel.textColor = NSColor.systemOrange
            } else {
                self?.errorLabel.stringValue = ""
            }
        }
    }
    
    /// 更新进度
    public func updateProgress(_ progress: Double) {
        DispatchQueue.main.async { [weak self] in
            if progress > 0 && progress < 1.0 {
                self?.progressLabel.stringValue = String(format: "%.1f%%", progress * 100)
            } else {
                self?.progressLabel.stringValue = ""
            }
        }
    }
    
    /// 重置状态栏
    public func reset() {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.stringValue = "📊 状态: 就绪"
            self?.statisticsLabel.stringValue = ""
            self?.errorLabel.stringValue = ""
            self?.progressLabel.stringValue = ""
        }
    }
    
    // MARK: - Private Methods
    
    /// 创建状态栏
    private func createStatusBar() {
        statusBar = NSView()
        statusBar.wantsLayer = true
        statusBar.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // 创建分隔线
        let separator = NSBox()
        separator.boxType = .separator
        
        // 创建标签
        statusLabel = NSTextField(labelWithString: "📊 状态: 就绪")
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = NSColor.controlTextColor
        
        statisticsLabel = NSTextField(labelWithString: "")
        statisticsLabel.font = NSFont.systemFont(ofSize: 12)
        statisticsLabel.textColor = NSColor.controlTextColor
        
        errorLabel = NSTextField(labelWithString: "")
        errorLabel.font = NSFont.systemFont(ofSize: 12)
        errorLabel.textColor = NSColor.systemOrange
        
        progressLabel = NSTextField(labelWithString: "")
        progressLabel.font = NSFont.systemFont(ofSize: 12)
        progressLabel.textColor = NSColor.controlTextColor
        progressLabel.alignment = .right
        
        // 添加到状态栏
        statusBar.addSubview(separator)
        statusBar.addSubview(statusLabel)
        statusBar.addSubview(statisticsLabel)
        statusBar.addSubview(errorLabel)
        statusBar.addSubview(progressLabel)
        
        // 设置约束
        separator.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statisticsLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // 状态栏高度
            statusBar.heightAnchor.constraint(equalToConstant: 24),
            
            // 分隔线
            separator.topAnchor.constraint(equalTo: statusBar.topAnchor),
            separator.leadingAnchor.constraint(equalTo: statusBar.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: statusBar.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            
            // 状态标签
            statusLabel.leadingAnchor.constraint(equalTo: statusBar.leadingAnchor, constant: 10),
            statusLabel.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor),
            
            // 统计标签
            statisticsLabel.leadingAnchor.constraint(equalTo: statusLabel.trailingAnchor, constant: 20),
            statisticsLabel.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor),
            
            // 错误标签
            errorLabel.leadingAnchor.constraint(equalTo: statisticsLabel.trailingAnchor, constant: 20),
            errorLabel.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor),
            
            // 进度标签
            progressLabel.trailingAnchor.constraint(equalTo: statusBar.trailingAnchor, constant: -10),
            progressLabel.centerYAnchor.constraint(equalTo: statusBar.centerYAnchor),
            progressLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
    }
}
