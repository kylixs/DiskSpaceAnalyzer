import Foundation

/// 导出格式
public enum ExportFormat {
    case json
    case csv
    case xml
}

/// 数据持久化协议定义
public protocol DataPersistenceProtocol {
    func save<T: Codable>(_ object: T, to path: String) throws
    func load<T: Codable>(_ type: T.Type, from path: String) throws -> T
    func delete(at path: String) throws
    func exists(at path: String) -> Bool
}

/// 数据持久化管理器
/// 使用JSON格式进行数据序列化，支持数据压缩和版本兼容性处理
public class DataPersistence {
    
    // MARK: - Properties
    
    /// 应用程序支持目录
    private let applicationSupportURL: URL
    
    /// 会话存储目录
    private let sessionsDirectory: URL
    
    /// 数据版本
    private let currentDataVersion = "1.0"
    
    /// JSON编码器
    private let encoder: JSONEncoder
    
    /// JSON解码器
    private let decoder: JSONDecoder
    
    /// 文件管理器
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    
    public init() throws {
        // 获取应用程序支持目录
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory,
                                                  in: .userDomainMask).first else {
            throw DataPersistenceError.applicationSupportDirectoryNotFound
        }
        
        applicationSupportURL = appSupportURL.appendingPathComponent("DiskSpaceAnalyzer")
        sessionsDirectory = applicationSupportURL.appendingPathComponent("Sessions")
        
        // 配置编码器和解码器
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // 创建目录
        try createDirectoriesIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /// 保存扫描会话
    /// - Parameter session: 要保存的会话
    public func saveSession(_ session: ScanSession) throws {
        let sessionURL = sessionsDirectory.appendingPathComponent("\(session.id.uuidString).json")
        
        // 创建包装对象（包含版本信息）
        let wrapper = SessionWrapper(version: currentDataVersion, session: session)
        
        try save(wrapper, to: sessionURL)
    }
    
    /// 加载扫描会话
    /// - Parameter sessionId: 会话ID
    /// - Returns: 加载的会话或nil
    public func loadSession(_ sessionId: UUID) throws -> ScanSession? {
        let sessionURL = sessionsDirectory.appendingPathComponent("\(sessionId.uuidString).json")
        
        guard fileManager.fileExists(atPath: sessionURL.path) else {
            return nil
        }
        
        let wrapper: SessionWrapper = try load(SessionWrapper.self, from: sessionURL)
        
        // 检查版本兼容性
        if wrapper.version != currentDataVersion {
            // 这里可以添加版本迁移逻辑
            print("Warning: Loading session with different version: \(wrapper.version)")
        }
        
        return wrapper.session
    }
    
    /// 获取所有会话
    /// - Returns: 所有会话的数组
    public func getAllSessions() throws -> [ScanSession] {
        let sessionFiles = try fileManager.contentsOfDirectory(at: sessionsDirectory,
                                                              includingPropertiesForKeys: nil)
        
        var sessions: [ScanSession] = []
        
        for fileURL in sessionFiles where fileURL.pathExtension == "json" {
            do {
                let wrapper: SessionWrapper = try load(SessionWrapper.self, from: fileURL)
                sessions.append(wrapper.session)
            } catch {
                print("Failed to load session from \(fileURL): \(error)")
                // 继续加载其他会话
            }
        }
        
        return sessions.sorted { $0.startTime > $1.startTime }
    }
    
    /// 删除会话
    /// - Parameter sessionId: 会话ID
    public func deleteSession(_ sessionId: UUID) throws {
        let sessionURL = sessionsDirectory.appendingPathComponent("\(sessionId.uuidString).json")
        
        if fileManager.fileExists(atPath: sessionURL.path) {
            try fileManager.removeItem(at: sessionURL)
        }
    }
    
    /// 清理过期会话
    /// - Parameter olderThan: 清理多少天前的会话
    public func cleanupOldSessions(olderThan days: Int) throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let sessions = try getAllSessions()
        
        for session in sessions {
            if session.startTime < cutoffDate {
                try deleteSession(session.id)
            }
        }
    }
    
    /// 导出会话数据
    /// - Parameters:
    ///   - session: 要导出的会话
    ///   - format: 导出格式
    /// - Returns: 导出的数据
    public func exportSession(_ session: ScanSession, format: ExportFormat) throws -> Data {
        switch format {
        case .json:
            return try encoder.encode(session)
        case .csv:
            return try exportSessionAsCSV(session)
        case .xml:
            throw DataPersistenceError.unsupportedFormat
        }
    }
    
    /// 导入会话数据
    /// - Parameter data: 要导入的数据
    /// - Returns: 导入的会话
    public func importSession(from data: Data) throws -> ScanSession {
        return try decoder.decode(ScanSession.self, from: data)
    }
    
    /// 获取存储统计信息
    /// - Returns: 存储统计信息
    public func getStorageStatistics() throws -> StorageStatistics {
        let sessionFiles = try fileManager.contentsOfDirectory(at: sessionsDirectory,
                                                              includingPropertiesForKeys: [.fileSizeKey])
        
        var totalSize: Int64 = 0
        var sessionCount = 0
        
        for fileURL in sessionFiles where fileURL.pathExtension == "json" {
            sessionCount += 1
            
            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues.fileSize {
                totalSize += Int64(fileSize)
            }
        }
        
        return StorageStatistics(
            sessionCount: sessionCount,
            totalSize: totalSize,
            storageDirectory: sessionsDirectory.path
        )
    }
    
    // MARK: - Generic Save/Load Methods
    
    /// 保存对象到文件
    /// - Parameters:
    ///   - object: 要保存的对象
    ///   - url: 文件URL
    public func save<T: Codable>(_ object: T, to url: URL) throws {
        let data = try encoder.encode(object)
        
        // 原子写入（先写临时文件，然后重命名）
        let tempURL = url.appendingPathExtension("tmp")
        
        try data.write(to: tempURL)
        
        // 验证写入的数据
        let verificationData = try Data(contentsOf: tempURL)
        if verificationData != data {
            try fileManager.removeItem(at: tempURL)
            throw DataPersistenceError.dataVerificationFailed
        }
        
        // 原子性重命名
        _ = try fileManager.replaceItem(at: url, withItemAt: tempURL,
                                       backupItemName: nil, options: [],
                                       resultingItemURL: nil)
    }
    
    /// 从文件加载对象
    /// - Parameters:
    ///   - type: 对象类型
    ///   - url: 文件URL
    /// - Returns: 加载的对象
    public func load<T: Codable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        
        // 验证数据完整性
        guard !data.isEmpty else {
            throw DataPersistenceError.emptyFile
        }
        
        return try decoder.decode(type, from: data)
    }
    
    /// 检查文件是否存在
    /// - Parameter url: 文件URL
    /// - Returns: 是否存在
    public func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
    
    /// 删除文件
    /// - Parameter url: 文件URL
    public func deleteFile(at url: URL) throws {
        if fileExists(at: url) {
            try fileManager.removeItem(at: url)
        }
    }
    
    // MARK: - Private Methods
    
    /// 创建必要的目录
    private func createDirectoriesIfNeeded() throws {
        try fileManager.createDirectory(at: applicationSupportURL,
                                       withIntermediateDirectories: true)
        try fileManager.createDirectory(at: sessionsDirectory,
                                       withIntermediateDirectories: true)
    }
    
    /// 导出会话为CSV格式
    /// - Parameter session: 要导出的会话
    /// - Returns: CSV数据
    private func exportSessionAsCSV(_ session: ScanSession) throws -> Data {
        var csvContent = "Path,Name,Size,IsDirectory,CreatedDate,ModifiedDate\n"
        
        if let rootNode = session.rootNode {
            addNodeToCSV(rootNode, csvContent: &csvContent)
        }
        
        guard let data = csvContent.data(using: .utf8) else {
            throw DataPersistenceError.encodingFailed
        }
        
        return data
    }
    
    /// 递归添加节点到CSV
    /// - Parameters:
    ///   - node: 节点
    ///   - csvContent: CSV内容
    private func addNodeToCSV(_ node: FileNode, csvContent: inout String) {
        let dateFormatter = ISO8601DateFormatter()
        
        let line = "\"\(node.path)\",\"\(node.name)\",\(node.size),\(node.isDirectory),\"\(dateFormatter.string(from: node.createdDate))\",\"\(dateFormatter.string(from: node.modifiedDate))\"\n"
        csvContent.append(line)
        
        for child in node.children {
            addNodeToCSV(child, csvContent: &csvContent)
        }
    }
}

// MARK: - Supporting Types

/// 会话包装器（包含版本信息）
private struct SessionWrapper: Codable {
    let version: String
    let session: ScanSession
}

/// 存储统计信息
public struct StorageStatistics {
    public let sessionCount: Int
    public let totalSize: Int64
    public let storageDirectory: String
    
    /// 格式化的总大小
    public var formattedTotalSize: String {
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    /// 平均会话大小
    public var averageSessionSize: Int64 {
        return sessionCount > 0 ? totalSize / Int64(sessionCount) : 0
    }
    
    /// 格式化的平均会话大小
    public var formattedAverageSessionSize: String {
        return ByteCountFormatter.string(fromByteCount: averageSessionSize, countStyle: .file)
    }
}

/// 数据持久化错误
public enum DataPersistenceError: Error, LocalizedError {
    case applicationSupportDirectoryNotFound
    case dataVerificationFailed
    case emptyFile
    case encodingFailed
    case unsupportedFormat
    
    public var errorDescription: String? {
        switch self {
        case .applicationSupportDirectoryNotFound:
            return "无法找到应用程序支持目录"
        case .dataVerificationFailed:
            return "数据验证失败"
        case .emptyFile:
            return "文件为空"
        case .encodingFailed:
            return "编码失败"
        case .unsupportedFormat:
            return "不支持的格式"
        }
    }
}

// MARK: - Protocol Implementation

/// 数据持久化协议实现
extension DataPersistence: DataPersistenceProtocol {
    
    public func save<T: Codable>(_ object: T, to path: String) throws {
        let url = URL(fileURLWithPath: path)
        try save(object, to: url)
    }
    
    public func load<T: Codable>(_ type: T.Type, from path: String) throws -> T {
        let url = URL(fileURLWithPath: path)
        return try load(type, from: url)
    }
    
    public func delete(at path: String) throws {
        let url = URL(fileURLWithPath: path)
        try deleteFile(at: url)
    }
    
    public func exists(at path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        return fileExists(at: url)
    }
}
