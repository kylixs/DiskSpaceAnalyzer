import Foundation
import Dispatch

/// 扫描状态
public enum ScanState {
    case idle       // 空闲
    case scanning   // 扫描中
    case paused     // 已暂停
    case cancelled  // 已取消
    case completed  // 已完成
    case error      // 错误状态
}

/// 扫描错误类型
public enum FileScanError: Error, Equatable {
    case permissionDenied(path: String)
    case fileNotFound(path: String)
    case invalidPath(path: String)
    case scanCancelled
    case unknownError(description: String)
    
    public var localizedDescription: String {
        switch self {
        case .permissionDenied(let path):
            return "Permission denied: \(path)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidPath(let path):
            return "Invalid path: \(path)"
        case .scanCancelled:
            return "Scan was cancelled"
        case .unknownError(let description):
            return "Unknown error: \(description)"
        }
    }
}

/// 扫描统计信息
public struct ScanStatistics {
    public let totalFiles: Int
    public let totalDirectories: Int
    public let totalSize: Int64
    public let scannedFiles: Int
    public let scannedDirectories: Int
    public let scannedSize: Int64
    public let skippedFiles: Int
    public let errorCount: Int
    public let startTime: Date
    public let endTime: Date?
    public let duration: TimeInterval
    
    public init(totalFiles: Int = 0, totalDirectories: Int = 0, totalSize: Int64 = 0, scannedFiles: Int = 0, scannedDirectories: Int = 0, scannedSize: Int64 = 0, skippedFiles: Int = 0, errorCount: Int = 0, startTime: Date = Date(), endTime: Date? = nil) {
        self.totalFiles = totalFiles
        self.totalDirectories = totalDirectories
        self.totalSize = totalSize
        self.scannedFiles = scannedFiles
        self.scannedDirectories = scannedDirectories
        self.scannedSize = scannedSize
        self.skippedFiles = skippedFiles
        self.errorCount = errorCount
        self.startTime = startTime
        self.endTime = endTime
        self.duration = (endTime ?? Date()).timeIntervalSince(startTime)
    }
    
    public var progress: Double {
        let totalItems = totalFiles + totalDirectories
        let scannedItems = scannedFiles + scannedDirectories
        return totalItems > 0 ? Double(scannedItems) / Double(totalItems) : 0.0
    }
}

/// 扫描配置
public struct ScanConfiguration {
    public let maxConcurrency: Int
    public let followSymlinks: Bool
    public let includeHiddenFiles: Bool
    public let maxDepth: Int?
    public let excludePaths: Set<String>
    public let fileExtensionFilter: Set<String>?
    
    public init(maxConcurrency: Int = 4, followSymlinks: Bool = false, includeHiddenFiles: Bool = false, maxDepth: Int? = nil, excludePaths: Set<String> = [], fileExtensionFilter: Set<String>? = nil) {
        self.maxConcurrency = maxConcurrency
        self.followSymlinks = followSymlinks
        self.includeHiddenFiles = includeHiddenFiles
        self.maxDepth = maxDepth
        self.excludePaths = excludePaths
        self.fileExtensionFilter = fileExtensionFilter
    }
}

/// 文件系统扫描器 - 核心扫描引擎
public class FileSystemScanner {
    
    // MARK: - Properties
    
    /// 扫描状态
    public private(set) var state: ScanState = .idle
    
    /// 扫描配置
    public var configuration: ScanConfiguration
    
    /// 扫描统计信息
    public private(set) var statistics: ScanStatistics
    
    /// 扫描错误列表
    public private(set) var errors: [ScanError] = []
    
    /// 状态锁
    private let stateLock = NSLock()
    
    /// 扫描队列
    private let scanQueue = DispatchQueue(label: "FileSystemScanner", qos: .userInitiated, attributes: .concurrent)
    
    /// 文件管理器
    private let fileManager = FileManager.default
    
    /// 扫描进度回调
    public var progressCallback: ((ScanStatistics) -> Void)?
    
    /// 文件发现回调
    public var fileDiscoveredCallback: ((FileNode) -> Void)?
    
    /// 错误回调
    public var errorCallback: ((ScanError) -> Void)?
    
    /// 状态变化回调
    public var stateChangeCallback: ((ScanState) -> Void)?
    
    /// 取消标志
    private var isCancelled = false
    
    /// 暂停标志
    private var isPaused = false
    
    // MARK: - Initialization
    
    public init(configuration: ScanConfiguration = ScanConfiguration()) {
        self.configuration = configuration
        self.statistics = ScanStatistics()
    }
    
    // MARK: - Public Methods
    
    /// 开始扫描
    public func startScan(at rootPath: String) {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        guard state == .idle || state == .completed || state == .error else {
            return
        }
        
        // 重置状态
        state = .scanning
        statistics = ScanStatistics(startTime: Date())
        errors.removeAll()
        isCancelled = false
        isPaused = false
        
        stateChangeCallback?(state)
        
        // 异步开始扫描
        scanQueue.async { [weak self] in
            self?.performScan(at: rootPath)
        }
    }
    
    /// 暂停扫描
    public func pauseScan() {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        guard state == .scanning else { return }
        
        isPaused = true
        state = .paused
        stateChangeCallback?(state)
    }
    
    /// 恢复扫描
    public func resumeScan() {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        guard state == .paused else { return }
        
        isPaused = false
        state = .scanning
        stateChangeCallback?(state)
    }
    
    /// 取消扫描
    public func cancelScan() {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        guard state == .scanning || state == .paused else { return }
        
        isCancelled = true
        state = .cancelled
        stateChangeCallback?(state)
    }
    
    /// 获取当前状态
    public func getCurrentState() -> ScanState {
        stateLock.lock()
        defer { stateLock.unlock() }
        return state
    }
    
    /// 获取统计信息
    public func getStatistics() -> ScanStatistics {
        stateLock.lock()
        defer { stateLock.unlock() }
        return statistics
    }
    
    /// 获取错误列表
    public func getErrors() -> [ScanError] {
        stateLock.lock()
        defer { stateLock.unlock() }
        return errors
    }
    
    // MARK: - Private Methods
    
    /// 执行扫描
    private func performScan(at rootPath: String) {
        do {
            // 验证根路径
            guard fileManager.fileExists(atPath: rootPath) else {
                handleError(.fileNotFound(path: rootPath))
                return
            }
            
            // 创建根节点
            let rootNode = try createFileNode(at: rootPath)
            fileDiscoveredCallback?(rootNode)
            
            // 开始递归扫描
            try scanDirectory(at: rootPath, depth: 0)
            
            // 扫描完成
            completeScanning()
            
        } catch {
            handleError(.unknownError(description: error.localizedDescription))
        }
    }
    
    /// 扫描目录
    private func scanDirectory(at path: String, depth: Int) throws {
        // 检查取消和暂停状态
        try checkScanState()
        
        // 检查深度限制
        if let maxDepth = configuration.maxDepth, depth >= maxDepth {
            return
        }
        
        // 检查排除路径
        if configuration.excludePaths.contains(path) {
            return
        }
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            
            // 并发处理目录内容
            let semaphore = DispatchSemaphore(value: configuration.maxConcurrency)
            let group = DispatchGroup()
            
            for item in contents {
                let itemPath = (path as NSString).appendingPathComponent(item)
                
                // 检查隐藏文件
                if !configuration.includeHiddenFiles && item.hasPrefix(".") {
                    continue
                }
                
                group.enter()
                scanQueue.async { [weak self] in
                    defer {
                        semaphore.signal()
                        group.leave()
                    }
                    
                    semaphore.wait()
                    
                    do {
                        try self?.processFileSystemItem(at: itemPath, depth: depth + 1)
                    } catch {
                        self?.handleError(.unknownError(description: error.localizedDescription))
                    }
                }
            }
            
            group.wait()
            
        } catch {
            handleError(.permissionDenied(path: path))
        }
    }
    
    /// 处理文件系统项目
    private func processFileSystemItem(at path: String, depth: Int) throws {
        try checkScanState()
        
        let attributes = try fileManager.attributesOfItem(atPath: path)
        let fileType = attributes[.type] as? FileAttributeType
        
        // 处理符号链接
        if fileType == .typeSymbolicLink {
            if !configuration.followSymlinks {
                updateStatistics(skippedFiles: 1)
                return
            }
            
            // 解析符号链接
            let resolvedPath = try fileManager.destinationOfSymbolicLink(atPath: path)
            if !fileManager.fileExists(atPath: resolvedPath) {
                updateStatistics(skippedFiles: 1)
                return
            }
        }
        
        // 创建文件节点
        let fileNode = try createFileNode(at: path, attributes: attributes)
        fileDiscoveredCallback?(fileNode)
        
        // 更新统计信息
        if fileNode.isDirectory {
            updateStatistics(scannedDirectories: 1, scannedSize: fileNode.size)
            
            // 递归扫描子目录
            try scanDirectory(at: path, depth: depth)
        } else {
            // 检查文件扩展名过滤
            if let filter = configuration.fileExtensionFilter {
                let pathExtension = (path as NSString).pathExtension.lowercased()
                if !filter.contains(pathExtension) {
                    updateStatistics(skippedFiles: 1)
                    return
                }
            }
            
            updateStatistics(scannedFiles: 1, scannedSize: fileNode.size)
        }
    }
    
    /// 创建文件节点
    private func createFileNode(at path: String, attributes: [FileAttributeKey: Any]? = nil) throws -> FileNode {
        let attrs = attributes ?? (try fileManager.attributesOfItem(atPath: path))
        
        let name = (path as NSString).lastPathComponent
        let size = (attrs[.size] as? Int64) ?? 0
        let isDirectory = (attrs[.type] as? FileAttributeType) == .typeDirectory
        let createdDate = (attrs[.creationDate] as? Date) ?? Date()
        let modifiedDate = (attrs[.modificationDate] as? Date) ?? Date()
        
        // 创建权限信息
        let posixPermissions = (attrs[.posixPermissions] as? Int16) ?? 0o644
        let permissions = FilePermissions.fromPosix(posixPermissions)
        
        return FileNode(
            name: name,
            path: path,
            size: size,
            isDirectory: isDirectory,
            createdDate: createdDate,
            modifiedDate: modifiedDate,
            permissions: permissions
        )
    }
    
    /// 检查扫描状态
    private func checkScanState() throws {
        if isCancelled {
            throw ScanError.scanCancelled
        }
        
        // 处理暂停状态
        while isPaused && !isCancelled {
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        if isCancelled {
            throw ScanError.scanCancelled
        }
    }
    
    /// 更新统计信息
    private func updateStatistics(scannedFiles: Int = 0, scannedDirectories: Int = 0, scannedSize: Int64 = 0, skippedFiles: Int = 0) {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        statistics = ScanStatistics(
            totalFiles: statistics.totalFiles,
            totalDirectories: statistics.totalDirectories,
            totalSize: statistics.totalSize,
            scannedFiles: statistics.scannedFiles + scannedFiles,
            scannedDirectories: statistics.scannedDirectories + scannedDirectories,
            scannedSize: statistics.scannedSize + scannedSize,
            skippedFiles: statistics.skippedFiles + skippedFiles,
            errorCount: statistics.errorCount,
            startTime: statistics.startTime,
            endTime: statistics.endTime
        )
        
        // 触发进度回调
        progressCallback?(statistics)
    }
    
    /// 处理错误
    private func handleError(_ error: ScanError) {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        errors.append(error)
        
        statistics = ScanStatistics(
            totalFiles: statistics.totalFiles,
            totalDirectories: statistics.totalDirectories,
            totalSize: statistics.totalSize,
            scannedFiles: statistics.scannedFiles,
            scannedDirectories: statistics.scannedDirectories,
            scannedSize: statistics.scannedSize,
            skippedFiles: statistics.skippedFiles,
            errorCount: statistics.errorCount + 1,
            startTime: statistics.startTime,
            endTime: statistics.endTime
        )
        
        // 触发错误回调
        errorCallback?(error)
        
        // 如果是严重错误，停止扫描
        switch error {
        case .scanCancelled:
            state = .cancelled
        case .fileNotFound, .invalidPath:
            state = .error
        default:
            break
        }
        
        if state == .cancelled || state == .error {
            stateChangeCallback?(state)
        }
    }
    
    /// 完成扫描
    private func completeScanning() {
        stateLock.lock()
        defer { stateLock.unlock() }
        
        state = .completed
        statistics = ScanStatistics(
            totalFiles: statistics.totalFiles,
            totalDirectories: statistics.totalDirectories,
            totalSize: statistics.totalSize,
            scannedFiles: statistics.scannedFiles,
            scannedDirectories: statistics.scannedDirectories,
            scannedSize: statistics.scannedSize,
            skippedFiles: statistics.skippedFiles,
            errorCount: statistics.errorCount,
            startTime: statistics.startTime,
            endTime: Date()
        )
        
        stateChangeCallback?(state)
        progressCallback?(statistics)
    }
}

// MARK: - Extensions

extension FilePermissions {
    /// 从POSIX权限创建FilePermissions
    static func fromPosix(_ posix: Int16) -> FilePermissions {
        let owner = PermissionSet(
            read: (posix & 0o400) != 0,
            write: (posix & 0o200) != 0,
            execute: (posix & 0o100) != 0
        )
        
        let group = PermissionSet(
            read: (posix & 0o040) != 0,
            write: (posix & 0o020) != 0,
            execute: (posix & 0o010) != 0
        )
        
        let others = PermissionSet(
            read: (posix & 0o004) != 0,
            write: (posix & 0o002) != 0,
            execute: (posix & 0o001) != 0
        )
        
        return FilePermissions(owner: owner, group: group, others: others)
    }
}
