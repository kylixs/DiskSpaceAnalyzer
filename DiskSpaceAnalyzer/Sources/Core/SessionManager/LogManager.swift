import Foundation
import os.log
/// 日志条目
public struct LogEntry {
    public let id: UUID
    public let timestamp: Date
    public let level: LogLevel
    public let category: String
    public let message: String
    public let file: String
    public let function: String
    public let line: Int
    public let thread: String
    
    public init(level: LogLevel, category: String, message: String, file: String = #file, function: String = #function, line: Int = #line) {
        self.id = UUID()
        self.timestamp = Date()
        self.level = level
        self.category = category
        self.message = message
        self.file = (file as NSString).lastPathComponent
        self.function = function
        self.line = line
        self.thread = Thread.isMainThread ? "main" : Thread.current.name ?? "unknown"
    }
    
    /// 格式化的日志字符串
    public var formattedString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        return "[\(dateFormatter.string(from: timestamp))] [\(level.displayName)] [\(category)] [\(thread)] \(file):\(line) \(function) - \(message)"
    }
    
    /// 简化的日志字符串
    public var simpleString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        
        return "\(level.emoji) \(dateFormatter.string(from: timestamp)) [\(category)] \(message)"
    }
}

/// 日志输出目标
public protocol LogOutput {
    func write(_ entry: LogEntry)
    func flush()
}

/// 控制台日志输出
public class ConsoleLogOutput: LogOutput {
    public init() {}
    
    public func write(_ entry: LogEntry) {
        print(entry.simpleString)
    }
    
    public func flush() {
        // 控制台不需要刷新
    }
}

/// 文件日志输出
public class FileLogOutput: LogOutput {
    private let fileURL: URL
    private let fileHandle: FileHandle?
    private let maxFileSize: Int64
    private let maxFileCount: Int
    private let accessLock = NSLock()
    
    public init(directory: URL, maxFileSize: Int64 = 10 * 1024 * 1024, maxFileCount: Int = 10) {
        self.maxFileSize = maxFileSize
        self.maxFileCount = maxFileCount
        
        // 创建日志目录
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        // 创建当前日志文件
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "DiskSpaceAnalyzer-\(dateFormatter.string(from: Date())).log"
        self.fileURL = directory.appendingPathComponent(fileName)
        
        // 创建文件句柄
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }
        
        self.fileHandle = try? FileHandle(forWritingTo: fileURL)
        self.fileHandle?.seekToEndOfFile()
    }
    
    deinit {
        fileHandle?.closeFile()
    }
    
    public func write(_ entry: LogEntry) {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        guard let handle = fileHandle else { return }
        
        let logString = entry.formattedString + "\n"
        if let data = logString.data(using: .utf8) {
            handle.write(data)
            
            // 检查文件大小并轮转
            if handle.offsetInFile > maxFileSize {
                rotateLogFile()
            }
        }
    }
    
    public func flush() {
        accessLock.lock()
        defer { accessLock.unlock() }
        
        fileHandle?.synchronizeFile()
    }
    
    private func rotateLogFile() {
        fileHandle?.closeFile()
        
        // 重命名当前文件
        let timestamp = Int(Date().timeIntervalSince1970)
        let rotatedURL = fileURL.appendingPathExtension("\(timestamp)")
        
        try? FileManager.default.moveItem(at: fileURL, to: rotatedURL)
        
        // 创建新文件
        FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        
        // 清理旧文件
        cleanupOldLogFiles()
    }
    
    private func cleanupOldLogFiles() {
        guard let directory = fileURL.deletingLastPathComponent().path as String? else { return }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: directory)
            let logFiles = files.filter { $0.hasPrefix("DiskSpaceAnalyzer-") && $0.hasSuffix(".log") }
                .sorted(by: >)
            
            // 保留最新的文件，删除多余的
            if logFiles.count > maxFileCount {
                let filesToDelete = Array(logFiles.dropFirst(maxFileCount))
                for file in filesToDelete {
                    let fileURL = URL(fileURLWithPath: directory).appendingPathComponent(file)
                    try? FileManager.default.removeItem(at: fileURL)
                }
            }
        } catch {
            // 忽略清理错误
        }
    }
}

/// 系统日志输出
public class SystemLogOutput: LogOutput {
    private let osLog: OSLog
    
    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "DiskSpaceAnalyzer", category: String = "General") {
        self.osLog = OSLog(subsystem: subsystem, category: category)
    }
    
    public func write(_ entry: LogEntry) {
        let osLogType: OSLogType
        switch entry.level {
        case .debug:
            osLogType = .debug
        case .info:
            osLogType = .info
        case .warning:
            osLogType = .default
        case .error:
            osLogType = .error
        case .fatal:
            osLogType = .fault
        }
        
        os_log("%{public}@", log: osLog, type: osLogType, entry.message)
    }
    
    public func flush() {
        // 系统日志不需要刷新
    }
}

/// 日志管理器 - 实现多级别的日志记录系统
public class LogManager {
    
    // MARK: - Properties
    
    /// 单例实例
    public static let shared = LogManager()
    
    /// 当前日志级别
    public var logLevel: LogLevel = .info
    
    /// 日志输出目标
    private var outputs: [LogOutput] = []
    
    /// 日志队列
    private let logQueue = DispatchQueue(label: "LogManager.queue", qos: .utility)
    
    /// 内存日志缓存
    private var memoryCache: [LogEntry] = []
    
    /// 最大内存缓存大小
    public var maxMemoryCacheSize: Int = 1000
    
    /// 缓存访问锁
    private let cacheLock = NSLock()
    
    /// 日志统计
    private var logStatistics: [LogLevel: Int] = [:]
    
    /// 自动清理定时器
    private var cleanupTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        setupDefaultOutputs()
        setupCleanupTimer()
        setupLogStatistics()
    }
    
    deinit {
        cleanupTimer?.invalidate()
        flush()
    }
    
    // MARK: - Public Methods
    
    /// 添加日志输出目标
    public func addOutput(_ output: LogOutput) {
        logQueue.async {
            self.outputs.append(output)
        }
    }
    
    /// 移除所有输出目标
    public func removeAllOutputs() {
        logQueue.async {
            self.outputs.removeAll()
        }
    }
    
    /// 记录日志
    public func log(_ message: String, level: LogLevel = .info, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        
        // 检查日志级别
        guard level >= logLevel else { return }
        
        let entry = LogEntry(
            level: level,
            category: category,
            message: message,
            file: file,
            function: function,
            line: line
        )
        
        logQueue.async {
            self.processLogEntry(entry)
        }
    }
    
    /// 调试日志
    public func debug(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    /// 信息日志
    public func info(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    /// 警告日志
    public func warning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    /// 错误日志
    public func error(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
    
    /// 致命错误日志
    public func fatal(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .fatal, category: category, file: file, function: function, line: line)
    }
    
    /// 刷新所有输出
    public func flush() {
        logQueue.sync {
            for output in self.outputs {
                output.flush()
            }
        }
    }
    
    /// 获取内存缓存的日志
    public func getMemoryLogs(limit: Int = 100) -> [LogEntry] {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        let sortedLogs = memoryCache.sorted { $0.timestamp > $1.timestamp }
        return Array(sortedLogs.prefix(limit))
    }
    
    /// 清除内存缓存
    public func clearMemoryCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        memoryCache.removeAll()
    }
    
    /// 获取日志统计
    public func getLogStatistics() -> [String: Any] {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        let totalLogs = logStatistics.values.reduce(0, +)
        let levelCounts = logStatistics.mapKeys { $0.displayName }
        
        return [
            "totalLogs": totalLogs,
            "memoryCacheSize": memoryCache.count,
            "maxMemoryCacheSize": maxMemoryCacheSize,
            "currentLogLevel": logLevel.displayName,
            "levelCounts": levelCounts,
            "outputCount": outputs.count
        ]
    }
    
    /// 导出日志报告
    public func exportLogReport() -> String {
        var report = "=== Log Manager Report ===\n\n"
        
        let stats = getLogStatistics()
        
        report += "Generated: \(Date())\n"
        report += "Total Logs: \(stats["totalLogs"] ?? 0)\n"
        report += "Memory Cache Size: \(stats["memoryCacheSize"] ?? 0)\n"
        report += "Max Memory Cache: \(stats["maxMemoryCacheSize"] ?? 0)\n"
        report += "Current Log Level: \(stats["currentLogLevel"] ?? "Unknown")\n"
        report += "Output Count: \(stats["outputCount"] ?? 0)\n\n"
        
        if let levelCounts = stats["levelCounts"] as? [String: Int] {
            report += "=== Level Breakdown ===\n"
            for (level, count) in levelCounts.sorted(by: { $0.key < $1.key }) {
                report += "\(level): \(count)\n"
            }
            report += "\n"
        }
        
        // 最近的日志条目
        let recentLogs = getMemoryLogs(limit: 10)
        if !recentLogs.isEmpty {
            report += "=== Recent Logs ===\n"
            for log in recentLogs {
                report += log.simpleString + "\n"
            }
        }
        
        return report
    }
    
    // MARK: - Private Methods
    
    /// 设置默认输出
    private func setupDefaultOutputs() {
        // 添加控制台输出
        addOutput(ConsoleLogOutput())
        
        // 添加文件输出
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logsURL = documentsURL.appendingPathComponent("Logs")
            addOutput(FileLogOutput(directory: logsURL))
        }
        
        // 添加系统日志输出
        addOutput(SystemLogOutput())
    }
    
    /// 设置清理定时器
    private func setupCleanupTimer() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { [weak self] _ in
            self?.performCleanup()
        }
    }
    
    /// 设置日志统计
    private func setupLogStatistics() {
        for level in LogLevel.allCases {
            logStatistics[level] = 0
        }
    }
    
    /// 处理日志条目
    private func processLogEntry(_ entry: LogEntry) {
        // 写入所有输出目标
        for output in outputs {
            output.write(entry)
        }
        
        // 添加到内存缓存
        addToMemoryCache(entry)
        
        // 更新统计
        updateStatistics(entry)
    }
    
    /// 添加到内存缓存
    private func addToMemoryCache(_ entry: LogEntry) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        memoryCache.append(entry)
        
        // 限制缓存大小
        if memoryCache.count > maxMemoryCacheSize {
            memoryCache.removeFirst(memoryCache.count - maxMemoryCacheSize)
        }
    }
    
    /// 更新统计信息
    private func updateStatistics(_ entry: LogEntry) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        logStatistics[entry.level, default: 0] += 1
    }
    
    /// 执行清理
    private func performCleanup() {
        // 清理7天前的日志文件
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        let logsURL = documentsURL.appendingPathComponent("Logs")
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: logsURL, includingPropertiesForKeys: [.creationDateKey])
            
            for fileURL in files {
                if let creationDate = try fileURL.resourceValues(forKeys: [.creationDateKey]).creationDate,
                   creationDate < sevenDaysAgo {
                    try FileManager.default.removeItem(at: fileURL)
                    info("Cleaned up old log file: \(fileURL.lastPathComponent)", category: "LogManager")
                }
            }
        } catch {
            warning("Failed to cleanup old log files: \(error)", category: "LogManager")
        }
    }
}

// MARK: - Extensions

extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        return Dictionary<T, Value>(uniqueKeysWithValues: map { (transform($0.key), $0.value) })
    }
}

// MARK: - Global Logging Functions

/// 全局日志函数
public func log(_ message: String, level: LogLevel = .info, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    LogManager.shared.log(message, level: level, category: category, file: file, function: function, line: line)
}

/// 全局调试日志
public func logDebug(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    LogManager.shared.debug(message, category: category, file: file, function: function, line: line)
}

/// 全局信息日志
public func logInfo(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    LogManager.shared.info(message, category: category, file: file, function: function, line: line)
}

/// 全局警告日志
public func logWarning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    LogManager.shared.warning(message, category: category, file: file, function: function, line: line)
}

/// 全局错误日志
public func logError(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
    LogManager.shared.error(message, category: category, file: file, function: function, line: line)
}
