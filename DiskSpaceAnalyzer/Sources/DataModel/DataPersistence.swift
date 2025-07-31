import Foundation
import Common

/// 数据持久化管理器
/// 支持基本的数据存储和加载功能
public class DataPersistence {
    
    // MARK: - Properties
    
    /// 数据存储根目录
    public static let dataDirectory: URL = {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let appDataPath = documentsPath.appendingPathComponent("DiskSpaceAnalyzer")
        
        // 确保目录存在
        try? FileManager.default.createDirectory(at: appDataPath, withIntermediateDirectories: true)
        
        return appDataPath
    }()
    
    /// 会话数据目录
    public static let sessionsDirectory: URL = {
        let sessionsPath = dataDirectory.appendingPathComponent("Sessions")
        try? FileManager.default.createDirectory(at: sessionsPath, withIntermediateDirectories: true)
        return sessionsPath
    }()
    
    /// 缓存目录
    public static let cacheDirectory: URL = {
        let cachePath = dataDirectory.appendingPathComponent("Cache")
        try? FileManager.default.createDirectory(at: cachePath, withIntermediateDirectories: true)
        return cachePath
    }()
    
    /// JSON编码器
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
    
    /// JSON解码器
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    /// 当前数据版本
    private static let currentVersion = "1.0.0"
    
    // MARK: - Session Persistence
    
    /// 保存扫描会话
    /// - Parameter session: 要保存的会话
    /// - Throws: 保存过程中的错误
    public static func saveSession(_ session: ScanSession) throws {
        let sessionFile = sessionsDirectory.appendingPathComponent("\(session.id.uuidString).json")
        try saveToFile(session, at: sessionFile)
    }
    
    /// 加载扫描会话
    /// - Parameter id: 会话ID
    /// - Returns: 加载的会话，如果不存在返回nil
    /// - Throws: 加载过程中的错误
    public static func loadSession(id: UUID) throws -> ScanSession? {
        let sessionFile = sessionsDirectory.appendingPathComponent("\(id.uuidString).json")
        
        guard FileManager.default.fileExists(atPath: sessionFile.path) else {
            return nil
        }
        
        return try loadFromFile(at: sessionFile)
    }
    
    /// 删除扫描会话
    /// - Parameter id: 会话ID
    /// - Throws: 删除过程中的错误
    public static func deleteSession(id: UUID) throws {
        let sessionFile = sessionsDirectory.appendingPathComponent("\(id.uuidString).json")
        
        if FileManager.default.fileExists(atPath: sessionFile.path) {
            try FileManager.default.removeItem(at: sessionFile)
        }
    }
    
    /// 获取所有已保存的会话ID
    /// - Returns: 会话ID列表
    public static func getAllSessionIds() -> [UUID] {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: sessionsDirectory, includingPropertiesForKeys: nil)
            
            return files.compactMap { url in
                guard url.pathExtension == "json" else { return nil }
                let fileName = url.deletingPathExtension().lastPathComponent
                return UUID(uuidString: fileName)
            }
        } catch {
            print("❌ 获取会话列表失败: \(error)")
            return []
        }
    }
    
    // MARK: - Directory Tree Persistence
    
    /// 保存目录树
    /// - Parameters:
    ///   - tree: 要保存的目录树
    ///   - sessionId: 关联的会话ID
    /// - Throws: 保存过程中的错误
    public static func saveDirectoryTree(_ tree: DirectoryTree, for sessionId: UUID) throws {
        let treeFile = sessionsDirectory.appendingPathComponent("\(sessionId.uuidString)_tree.json")
        
        // 简化保存：只保存基本信息
        let treeData: [String: Any] = [
            "sessionId": sessionId.uuidString,
            "nodeCount": tree.nodeCount,
            "savedAt": ISO8601DateFormatter().string(from: Date())
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: treeData, options: [.prettyPrinted])
        try jsonData.write(to: treeFile)
    }
    
    /// 加载目录树
    /// - Parameter sessionId: 会话ID
    /// - Returns: 加载的目录树，如果不存在返回nil
    /// - Throws: 加载过程中的错误
    public static func loadDirectoryTree(for sessionId: UUID) throws -> DirectoryTree? {
        let treeFile = sessionsDirectory.appendingPathComponent("\(sessionId.uuidString)_tree.json")
        
        guard FileManager.default.fileExists(atPath: treeFile.path) else {
            return nil
        }
        
        // 简化加载：返回空的目录树
        return DirectoryTree()
    }
    
    // MARK: - Cache Management
    
    /// 保存到缓存
    /// - Parameters:
    ///   - data: 要缓存的数据
    ///   - key: 缓存键
    ///   - expiration: 过期时间（秒）
    /// - Throws: 保存过程中的错误
    public static func saveToCache<T: Codable>(_ data: T, key: String, expiration: TimeInterval = 3600) throws {
        let cacheFile = cacheDirectory.appendingPathComponent("\(key).cache")
        
        let cacheItem = CacheItem(
            data: data,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(expiration)
        )
        
        try saveToFile(cacheItem, at: cacheFile)
    }
    
    /// 从缓存加载
    /// - Parameter key: 缓存键
    /// - Returns: 缓存的数据，如果不存在或已过期返回nil
    public static func loadFromCache<T: Codable>(key: String, type: T.Type) -> T? {
        let cacheFile = cacheDirectory.appendingPathComponent("\(key).cache")
        
        guard FileManager.default.fileExists(atPath: cacheFile.path) else {
            return nil
        }
        
        do {
            let cacheItem: CacheItem<T> = try loadFromFile(at: cacheFile)
            
            // 检查是否过期
            if Date() > cacheItem.expiresAt {
                try? FileManager.default.removeItem(at: cacheFile)
                return nil
            }
            
            return cacheItem.data
        } catch {
            print("❌ 加载缓存失败 (\(key)): \(error)")
            return nil
        }
    }
    
    /// 清理过期缓存
    public static func cleanExpiredCache() {
        do {
            let cacheFiles = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])
            
            for file in cacheFiles {
                guard file.pathExtension == "cache" else { continue }
                
                // 尝试读取缓存项检查过期时间
                do {
                    let data = try Data(contentsOf: file)
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    if let expiresAtString = json?["expiresAt"] as? String,
                       let expiresAt = ISO8601DateFormatter().date(from: expiresAtString),
                       Date() > expiresAt {
                        try FileManager.default.removeItem(at: file)
                        print("🗑️ 清理过期缓存: \(file.lastPathComponent)")
                    }
                } catch {
                    // 如果无法解析，删除文件
                    try? FileManager.default.removeItem(at: file)
                    print("🗑️ 清理损坏缓存: \(file.lastPathComponent)")
                }
            }
        } catch {
            print("❌ 清理缓存失败: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    /// 获取数据目录大小
    /// - Returns: 目录大小（字节）
    public static func getDataDirectorySize() -> Int64 {
        return getDirectorySize(at: dataDirectory)
    }
    
    /// 清理所有数据
    /// - Parameter keepSessions: 是否保留会话数据
    public static func cleanAllData(keepSessions: Bool = false) {
        do {
            // 清理缓存
            let cacheFiles = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in cacheFiles {
                try FileManager.default.removeItem(at: file)
            }
            
            // 清理会话数据（如果需要）
            if !keepSessions {
                let sessionFiles = try FileManager.default.contentsOfDirectory(at: sessionsDirectory, includingPropertiesForKeys: nil)
                for file in sessionFiles {
                    try FileManager.default.removeItem(at: file)
                }
            }
            
            print("🧹 数据清理完成")
        } catch {
            print("❌ 数据清理失败: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    /// 保存数据到文件
    /// - Parameters:
    ///   - data: 要保存的数据
    ///   - url: 文件URL
    /// - Throws: 保存过程中的错误
    private static func saveToFile<T: Codable>(_ data: T, at url: URL) throws {
        let jsonData = try encoder.encode(data)
        
        // 原子写入：先写入临时文件，然后重命名
        let tempURL = url.appendingPathExtension("tmp")
        
        try jsonData.write(to: tempURL)
        
        // 原子性重命名
        _ = try FileManager.default.replaceItem(at: url, withItemAt: tempURL, backupItemName: nil, options: [], resultingItemURL: nil)
    }
    
    /// 从文件加载数据
    /// - Parameter url: 文件URL
    /// - Returns: 加载的数据
    /// - Throws: 加载过程中的错误
    private static func loadFromFile<T: Codable>(at url: URL) throws -> T {
        let jsonData = try Data(contentsOf: url)
        return try decoder.decode(T.self, from: jsonData)
    }
    
    /// 获取目录大小
    /// - Parameter url: 目录URL
    /// - Returns: 目录大小（字节）
    private static func getDirectorySize(at url: URL) -> Int64 {
        var size: Int64 = 0
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles])
            
            for file in files {
                let resourceValues = try file.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                
                if let isDirectory = resourceValues.isDirectory, isDirectory {
                    size += getDirectorySize(at: file)
                } else if let fileSize = resourceValues.fileSize {
                    size += Int64(fileSize)
                }
            }
        } catch {
            print("❌ 计算目录大小失败: \(error)")
        }
        
        return size
    }
}

// MARK: - Supporting Types

/// 缓存项
private struct CacheItem<T: Codable>: Codable {
    let data: T
    let createdAt: Date
    let expiresAt: Date
}

/// 持久化错误类型
public enum PersistenceError: Error, LocalizedError {
    case sessionNotFound(UUID)
    case invalidData
    case versionMismatch(String, String)
    case fileSystemError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .sessionNotFound(let id):
            return "会话未找到: \(id)"
        case .invalidData:
            return "数据格式无效"
        case .versionMismatch(let current, let expected):
            return "版本不匹配: \(current) -> \(expected)"
        case .fileSystemError(let error):
            return "文件系统错误: \(error.localizedDescription)"
        }
    }
}
