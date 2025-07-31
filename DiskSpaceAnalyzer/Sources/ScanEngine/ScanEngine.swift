import Foundation
import Common
import DataModel
import PerformanceOptimizer

// MARK: - ScanEngine Module
// 扫描引擎模块 - 提供高性能文件系统扫描功能

/// ScanEngine模块信息
public struct ScanEngineModule {
    public static let version = "1.0.0"
    public static let description = "高性能文件系统扫描引擎"
    
    public static func initialize() {
        print("🔍 ScanEngine模块初始化")
        print("📋 包含: FileSystemScanner、ScanProgressManager、FileFilter、ScanTaskManager")
        print("📊 版本: \(version)")
        print("✅ ScanEngine模块初始化完成")
    }
}

// MARK: - 文件系统扫描器

/// 文件系统扫描器 - 核心扫描引擎
public class FileSystemScanner {
    public static let shared = FileSystemScanner()
    
    private let fileManager = FileManager.default
    private let scanQueue = DispatchQueue(label: "FileSystemScanner", qos: .userInitiated, attributes: .concurrent)
    private let progressQueue = DispatchQueue(label: "ScanProgress", qos: .utility)
    
    private var currentScanTask: Task<Void, Error>?
    private var isCancelled = false
    private var isPaused = false
    
    // 扫描统计
    private var scanStatistics = ScanStatistics()
    private var scanStartTime: Date?
    
    // 回调
    public var onProgress: ((ScanProgress) -> Void)?
    public var onNodeDiscovered: ((FileNode) -> Void)?
    public var onError: ((ScanError) -> Void)?
    public var onCompleted: ((ScanResult) -> Void)?
    
    private init() {}
    
    /// 开始扫描
    public func startScan(at path: String) async throws {
        guard !path.isEmpty else {
            throw ScanError.invalidPath("扫描路径不能为空")
        }
        
        // 重置状态
        resetScanState()
        scanStartTime = Date()
        
        // 检查路径是否存在
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            throw ScanError.pathNotFound("路径不存在: \(path)")
        }
        
        // 开始扫描任务
        currentScanTask = Task {
            try await performScan(at: path)
        }
        
        try await currentScanTask?.value
    }
    
    /// 取消扫描
    public func cancelScan() {
        isCancelled = true
        currentScanTask?.cancel()
        currentScanTask = nil
    }
    
    /// 暂停扫描
    public func pauseScan() {
        isPaused = true
    }
    
    /// 恢复扫描
    public func resumeScan() {
        isPaused = false
    }
    
    /// 获取扫描统计
    public func getScanStatistics() -> ScanStatistics {
        var stats = scanStatistics
        if let startTime = scanStartTime {
            stats.scanDuration = Date().timeIntervalSince(startTime)
        }
        return stats
    }
    
    // MARK: - 私有方法
    
    private func resetScanState() {
        isCancelled = false
        isPaused = false
        scanStatistics = ScanStatistics()
        scanStartTime = nil
    }
    
    private func performScan(at path: String) async throws {
        let rootNode = FileNode(name: URL(fileURLWithPath: path).lastPathComponent, 
                               path: path, 
                               size: 0, 
                               isDirectory: true)
        
        try await scanDirectory(node: rootNode, path: path)
        
        // 扫描完成
        let result = ScanResult(
            rootNode: rootNode,
            statistics: getScanStatistics(),
            errors: []
        )
        
        await MainActor.run {
            onCompleted?(result)
        }
    }
    
    private func scanDirectory(node: FileNode, path: String) async throws {
        // 检查取消状态
        try Task.checkCancellation()
        
        // 检查暂停状态
        while isPaused && !isCancelled {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        guard !isCancelled else { return }
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            
            for item in contents {
                guard !isCancelled else { return }
                
                let itemPath = (path as NSString).appendingPathComponent(item)
                
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: itemPath)
                    let fileType = attributes[.type] as? FileAttributeType
                    let fileSize = attributes[.size] as? Int64 ?? 0
                    let isDirectory = fileType == .typeDirectory
                    
                    // 跳过符号链接以避免循环
                    if fileType == .typeSymbolicLink {
                        scanStatistics.skippedFiles += 1
                        continue
                    }
                    
                    let childNode = FileNode(name: item, path: itemPath, size: fileSize, isDirectory: isDirectory)
                    node.addChild(childNode)
                    
                    // 更新统计
                    if isDirectory {
                        scanStatistics.directoriesScanned += 1
                        // 递归扫描子目录
                        try await scanDirectory(node: childNode, path: itemPath)
                    } else {
                        scanStatistics.filesScanned += 1
                        scanStatistics.totalBytesScanned += fileSize
                    }
                    
                    // 通知发现新节点
                    await MainActor.run {
                        onNodeDiscovered?(childNode)
                    }
                    
                    // 更新进度
                    await updateProgress()
                    
                } catch {
                    // 处理权限错误等
                    scanStatistics.errorCount += 1
                    let scanError = ScanError.accessDenied("无法访问: \(itemPath), 错误: \(error.localizedDescription)")
                    
                    await MainActor.run {
                        onError?(scanError)
                    }
                }
            }
            
        } catch {
            scanStatistics.errorCount += 1
            let scanError = ScanError.accessDenied("无法读取目录: \(path), 错误: \(error.localizedDescription)")
            
            await MainActor.run {
                onError?(scanError)
            }
        }
    }
    
    private func updateProgress() async {
        let progress = ScanProgress(
            currentPath: "",
            filesScanned: scanStatistics.filesScanned,
            directoriesScanned: scanStatistics.directoriesScanned,
            totalBytesScanned: scanStatistics.totalBytesScanned,
            errorCount: scanStatistics.errorCount,
            elapsedTime: scanStartTime?.timeIntervalSinceNow ?? 0
        )
        
        await MainActor.run {
            onProgress?(progress)
        }
    }
}

// MARK: - 扫描进度管理器

/// 扫描进度管理器 - 100ms高频更新
public class ScanProgressManager {
    public static let shared = ScanProgressManager()
    
    private var progressTimer: Timer?
    private let updateInterval: TimeInterval = 0.1 // 100ms
    private var currentProgress = ScanProgress()
    
    public var onProgressUpdate: ((ScanProgress) -> Void)?
    
    private init() {}
    
    /// 开始进度更新
    public func startProgressUpdates() {
        stopProgressUpdates()
        
        progressTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    /// 停止进度更新
    public func stopProgressUpdates() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    /// 更新进度数据
    public func updateProgress(_ progress: ScanProgress) {
        currentProgress = progress
    }
    
    private func updateProgress() {
        onProgressUpdate?(currentProgress)
    }
}

// MARK: - 文件过滤器

/// 文件过滤器 - 智能文件过滤
public class FileFilter {
    public static let shared = FileFilter()
    
    private var configuration = FilterConfiguration()
    
    private init() {}
    
    /// 设置过滤配置
    public func setConfiguration(_ config: FilterConfiguration) {
        self.configuration = config
    }
    
    /// 检查文件是否应该被过滤
    public func shouldFilter(path: String, attributes: [FileAttributeKey: Any]) -> Bool {
        // 检查文件大小
        if let fileSize = attributes[.size] as? Int64 {
            if fileSize == 0 && configuration.filterZeroSizeFiles {
                return true
            }
            
            if configuration.minFileSize > 0 && fileSize < configuration.minFileSize {
                return true
            }
            
            if configuration.maxFileSize > 0 && fileSize > configuration.maxFileSize {
                return true
            }
        }
        
        // 检查隐藏文件
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        if fileName.hasPrefix(".") && !configuration.includeHiddenFiles {
            return true
        }
        
        // 检查文件类型
        if let fileType = attributes[.type] as? FileAttributeType {
            if fileType == .typeSymbolicLink && !configuration.followSymbolicLinks {
                return true
            }
        }
        
        // 检查文件扩展名
        let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
        if !configuration.excludedExtensions.isEmpty && configuration.excludedExtensions.contains(fileExtension) {
            return true
        }
        
        return false
    }
    
    /// 过滤配置
    public struct FilterConfiguration {
        public var includeHiddenFiles = false
        public var followSymbolicLinks = false
        public var filterZeroSizeFiles = true
        public var minFileSize: Int64 = 0
        public var maxFileSize: Int64 = 0
        public var excludedExtensions: Set<String> = []
        
        public init() {}
    }
}

// MARK: - 扫描任务管理器

/// 扫描任务管理器 - 异步任务管理
public class ScanTaskManager {
    public static let shared = ScanTaskManager()
    
    private var activeTasks: [String: Task<Void, Error>] = [:]
    private let taskQueue = DispatchQueue(label: "ScanTaskManager", attributes: .concurrent)
    
    private init() {}
    
    /// 创建扫描任务
    public func createScanTask(id: String, path: String) -> Task<Void, Error> {
        let task = Task {
            try await FileSystemScanner.shared.startScan(at: path)
        }
        
        taskQueue.async(flags: .barrier) {
            self.activeTasks[id] = task
        }
        
        // 任务完成后清理
        Task {
            _ = try? await task.value
            taskQueue.async(flags: .barrier) {
                self.activeTasks.removeValue(forKey: id)
            }
        }
        
        return task
    }
    
    /// 取消任务
    public func cancelTask(id: String) {
        taskQueue.async(flags: .barrier) {
            self.activeTasks[id]?.cancel()
            self.activeTasks.removeValue(forKey: id)
        }
    }
    
    /// 取消所有任务
    public func cancelAllTasks() {
        taskQueue.async(flags: .barrier) {
            self.activeTasks.values.forEach { $0.cancel() }
            self.activeTasks.removeAll()
        }
    }
    
    /// 获取活跃任务数量
    public func getActiveTaskCount() -> Int {
        return taskQueue.sync {
            return activeTasks.count
        }
    }
}

// MARK: - 数据结构

/// 扫描进度
public struct ScanProgress {
    public let currentPath: String
    public let filesScanned: Int
    public let directoriesScanned: Int
    public let totalBytesScanned: Int64
    public let errorCount: Int
    public let elapsedTime: TimeInterval
    
    public init(currentPath: String = "", filesScanned: Int = 0, directoriesScanned: Int = 0, 
                totalBytesScanned: Int64 = 0, errorCount: Int = 0, elapsedTime: TimeInterval = 0) {
        self.currentPath = currentPath
        self.filesScanned = filesScanned
        self.directoriesScanned = directoriesScanned
        self.totalBytesScanned = totalBytesScanned
        self.errorCount = errorCount
        self.elapsedTime = elapsedTime
    }
    
    public var totalItemsScanned: Int {
        return filesScanned + directoriesScanned
    }
    
    public var scanSpeed: Double {
        return elapsedTime > 0 ? Double(totalItemsScanned) / elapsedTime : 0
    }
}

/// 扫描结果
public struct ScanResult {
    public let rootNode: FileNode
    public let statistics: ScanStatistics
    public let errors: [ScanError]
    
    public init(rootNode: FileNode, statistics: ScanStatistics, errors: [ScanError]) {
        self.rootNode = rootNode
        self.statistics = statistics
        self.errors = errors
    }
}

/// 扫描错误
public enum ScanError: Error, LocalizedError {
    case invalidPath(String)
    case pathNotFound(String)
    case accessDenied(String)
    case scanCancelled
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidPath(let message):
            return "无效路径: \(message)"
        case .pathNotFound(let message):
            return "路径未找到: \(message)"
        case .accessDenied(let message):
            return "访问被拒绝: \(message)"
        case .scanCancelled:
            return "扫描已取消"
        case .unknownError(let message):
            return "未知错误: \(message)"
        }
    }
}

// MARK: - 扫描引擎管理器

/// 扫描引擎管理器 - 统一管理所有扫描功能
public class ScanEngine {
    public static let shared = ScanEngine()
    
    private let fileSystemScanner = FileSystemScanner.shared
    private let progressManager = ScanProgressManager.shared
    private let fileFilter = FileFilter.shared
    private let taskManager = ScanTaskManager.shared
    
    private init() {}
    
    /// 开始扫描
    public func startScan(at path: String, configuration: FileFilter.FilterConfiguration? = nil) async throws -> ScanResult {
        // 设置过滤配置
        if let config = configuration {
            fileFilter.setConfiguration(config)
        }
        
        // 开始进度更新
        progressManager.startProgressUpdates()
        
        // 设置回调
        fileSystemScanner.onProgress = { [weak self] progress in
            self?.progressManager.updateProgress(progress)
        }
        
        defer {
            progressManager.stopProgressUpdates()
        }
        
        // 执行扫描
        try await fileSystemScanner.startScan(at: path)
        
        // 返回结果
        return ScanResult(
            rootNode: FileNode(name: "root", path: path, size: 0, isDirectory: true),
            statistics: fileSystemScanner.getScanStatistics(),
            errors: []
        )
    }
    
    /// 取消扫描
    public func cancelScan() {
        fileSystemScanner.cancelScan()
        progressManager.stopProgressUpdates()
    }
    
    /// 暂停扫描
    public func pauseScan() {
        fileSystemScanner.pauseScan()
    }
    
    /// 恢复扫描
    public func resumeScan() {
        fileSystemScanner.resumeScan()
    }
    
    /// 获取扫描统计
    public func getScanStatistics() -> ScanStatistics {
        return fileSystemScanner.getScanStatistics()
    }
}
