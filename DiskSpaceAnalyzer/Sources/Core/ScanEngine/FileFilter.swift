import Foundation

/// 过滤规则类型
public enum FilterRuleType {
    case size           // 文件大小过滤
    case fileExtension  // 文件扩展名过滤
    case name           // 文件名过滤
    case path           // 路径过滤
    case attribute      // 文件属性过滤
    case custom         // 自定义过滤
}

/// 过滤操作类型
public enum FilterOperation {
    case include        // 包含
    case exclude        // 排除
}

/// 过滤规则
public struct FilterRule {
    public let id: String
    public let type: FilterRuleType
    public let operation: FilterOperation
    public let pattern: String
    public let isEnabled: Bool
    public let priority: Int
    
    public init(id: String = UUID().uuidString, type: FilterRuleType, operation: FilterOperation, pattern: String, isEnabled: Bool = true, priority: Int = 0) {
        self.id = id
        self.type = type
        self.operation = operation
        self.pattern = pattern
        self.isEnabled = isEnabled
        self.priority = priority
    }
}

/// 过滤结果
public struct FilterResult {
    public let shouldInclude: Bool
    public let matchedRules: [FilterRule]
    public let reason: String
    
    public init(shouldInclude: Bool, matchedRules: [FilterRule] = [], reason: String = "") {
        self.shouldInclude = shouldInclude
        self.matchedRules = matchedRules
        self.reason = reason
    }
}

/// 过滤统计信息
public struct FilterStatistics {
    public let totalFilesProcessed: Int
    public let filesIncluded: Int
    public let filesExcluded: Int
    public let zeroSizeFilesFiltered: Int
    public let symbolicLinksFiltered: Int
    public let hardLinksFiltered: Int
    public let ruleBasedFiltered: Int
    
    public init(totalFilesProcessed: Int = 0, filesIncluded: Int = 0, filesExcluded: Int = 0, zeroSizeFilesFiltered: Int = 0, symbolicLinksFiltered: Int = 0, hardLinksFiltered: Int = 0, ruleBasedFiltered: Int = 0) {
        self.totalFilesProcessed = totalFilesProcessed
        self.filesIncluded = filesIncluded
        self.filesExcluded = filesExcluded
        self.zeroSizeFilesFiltered = zeroSizeFilesFiltered
        self.symbolicLinksFiltered = symbolicLinksFiltered
        self.hardLinksFiltered = hardLinksFiltered
        self.ruleBasedFiltered = ruleBasedFiltered
    }
    
    public var filterRate: Double {
        return totalFilesProcessed > 0 ? Double(filesExcluded) / Double(totalFilesProcessed) : 0.0
    }
}

/// 文件过滤器 - 智能文件过滤系统
public class FileFilter {
    
    // MARK: - Properties
    
    /// 过滤规则列表
    private var filterRules: [FilterRule] = []
    
    /// 规则访问锁
    private let rulesLock = NSLock()
    
    /// inode索引表（用于硬链接去重）
    private var inodeSet: Set<UInt64> = []
    
    /// inode锁
    private let inodeLock = NSLock()
    
    /// 过滤统计信息
    private var statistics: FilterStatistics = FilterStatistics()
    
    /// 统计锁
    private let statisticsLock = NSLock()
    
    /// 是否启用零字节文件过滤
    public var filterZeroSizeFiles: Bool = true
    
    /// 是否启用符号链接过滤
    public var filterSymbolicLinks: Bool = true
    
    /// 是否启用硬链接去重
    public var filterDuplicateHardLinks: Bool = true
    
    /// 文件管理器
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    
    public init() {
        setupDefaultRules()
    }
    
    // MARK: - Public Methods
    
    /// 添加过滤规则
    public func addFilterRule(_ rule: FilterRule) {
        rulesLock.lock()
        defer { rulesLock.unlock() }
        
        // 移除同ID的规则
        filterRules.removeAll { $0.id == rule.id }
        
        // 添加新规则并按优先级排序
        filterRules.append(rule)
        filterRules.sort { $0.priority > $1.priority }
    }
    
    /// 移除过滤规则
    public func removeFilterRule(id: String) {
        rulesLock.lock()
        defer { rulesLock.unlock() }
        
        filterRules.removeAll { $0.id == id }
    }
    
    /// 获取所有过滤规则
    public func getAllFilterRules() -> [FilterRule] {
        rulesLock.lock()
        defer { rulesLock.unlock() }
        
        return filterRules
    }
    
    /// 启用/禁用规则
    public func setRuleEnabled(id: String, enabled: Bool) {
        rulesLock.lock()
        defer { rulesLock.unlock() }
        
        if let index = filterRules.firstIndex(where: { $0.id == id }) {
            let rule = filterRules[index]
            filterRules[index] = FilterRule(
                id: rule.id,
                type: rule.type,
                operation: rule.operation,
                pattern: rule.pattern,
                isEnabled: enabled,
                priority: rule.priority
            )
        }
    }
    
    /// 过滤文件
    public func filterFile(at path: String, attributes: [FileAttributeKey: Any]? = nil) -> FilterResult {
        updateStatistics(totalFilesProcessed: 1)
        
        let attrs = attributes ?? getFileAttributes(at: path)
        
        // 1. 检查零字节文件
        if filterZeroSizeFiles {
            if let size = attrs[.size] as? Int64, size == 0 {
                updateStatistics(filesExcluded: 1, zeroSizeFilesFiltered: 1)
                return FilterResult(shouldInclude: false, reason: "Zero size file")
            }
        }
        
        // 2. 检查符号链接
        if filterSymbolicLinks {
            if let fileType = attrs[.type] as? FileAttributeType, fileType == .typeSymbolicLink {
                updateStatistics(filesExcluded: 1, symbolicLinksFiltered: 1)
                return FilterResult(shouldInclude: false, reason: "Symbolic link")
            }
        }
        
        // 3. 检查硬链接去重
        if filterDuplicateHardLinks {
            if let inode = attrs[.systemFileNumber] as? UInt64 {
                inodeLock.lock()
                let isNewInode = inodeSet.insert(inode).inserted
                inodeLock.unlock()
                
                if !isNewInode {
                    updateStatistics(filesExcluded: 1, hardLinksFiltered: 1)
                    return FilterResult(shouldInclude: false, reason: "Duplicate hard link")
                }
            }
        }
        
        // 4. 应用自定义规则
        let ruleResult = applyFilterRules(path: path, attributes: attrs)
        if !ruleResult.shouldInclude {
            updateStatistics(filesExcluded: 1, ruleBasedFiltered: 1)
            return ruleResult
        }
        
        // 文件通过所有过滤器
        updateStatistics(filesIncluded: 1)
        return FilterResult(shouldInclude: true, reason: "Passed all filters")
    }
    
    /// 批量过滤文件
    public func filterFiles(at paths: [String]) -> [String: FilterResult] {
        var results: [String: FilterResult] = [:]
        
        for path in paths {
            results[path] = filterFile(at: path)
        }
        
        return results
    }
    
    /// 获取过滤统计信息
    public func getStatistics() -> FilterStatistics {
        statisticsLock.lock()
        defer { statisticsLock.unlock() }
        
        return statistics
    }
    
    /// 重置统计信息
    public func resetStatistics() {
        statisticsLock.lock()
        defer { statisticsLock.unlock() }
        
        statistics = FilterStatistics()
        
        inodeLock.lock()
        inodeSet.removeAll()
        inodeLock.unlock()
    }
    
    /// 清除inode缓存
    public func clearInodeCache() {
        inodeLock.lock()
        defer { inodeLock.unlock() }
        
        inodeSet.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// 设置默认规则
    private func setupDefaultRules() {
        // 排除系统文件
        let systemFilesRule = FilterRule(
            type: .name,
            operation: .exclude,
            pattern: "^\\.DS_Store$|^\\.Spotlight-V100$|^\\.Trashes$|^\\.fseventsd$",
            priority: 100
        )
        addFilterRule(systemFilesRule)
        
        // 排除临时文件
        let tempFilesRule = FilterRule(
            type: .extension,
            operation: .exclude,
            pattern: "tmp|temp|cache",
            priority: 90
        )
        addFilterRule(tempFilesRule)
        
        // 排除备份文件
        let backupFilesRule = FilterRule(
            type: .extension,
            operation: .exclude,
            pattern: "bak|backup|old",
            priority: 80
        )
        addFilterRule(backupFilesRule)
    }
    
    /// 应用过滤规则
    private func applyFilterRules(path: String, attributes: [FileAttributeKey: Any]) -> FilterResult {
        rulesLock.lock()
        let rules = filterRules.filter { $0.isEnabled }
        rulesLock.unlock()
        
        var matchedRules: [FilterRule] = []
        var shouldInclude = true
        var reason = ""
        
        for rule in rules {
            if matchesRule(rule: rule, path: path, attributes: attributes) {
                matchedRules.append(rule)
                
                switch rule.operation {
                case .include:
                    shouldInclude = true
                    reason = "Matched include rule: \(rule.pattern)"
                case .exclude:
                    shouldInclude = false
                    reason = "Matched exclude rule: \(rule.pattern)"
                    break  // 排除规则优先级更高
                }
            }
        }
        
        return FilterResult(shouldInclude: shouldInclude, matchedRules: matchedRules, reason: reason)
    }
    
    /// 检查规则匹配
    private func matchesRule(rule: FilterRule, path: String, attributes: [FileAttributeKey: Any]) -> Bool {
        switch rule.type {
        case .size:
            return matchesSizeRule(pattern: rule.pattern, attributes: attributes)
        case .fileExtension:
            return matchesExtensionRule(pattern: rule.pattern, path: path)
        case .name:
            return matchesNameRule(pattern: rule.pattern, path: path)
        case .path:
            return matchesPathRule(pattern: rule.pattern, path: path)
        case .attribute:
            return matchesAttributeRule(pattern: rule.pattern, attributes: attributes)
        case .custom:
            return matchesCustomRule(pattern: rule.pattern, path: path, attributes: attributes)
        }
    }
    
    /// 匹配文件大小规则
    private func matchesSizeRule(pattern: String, attributes: [FileAttributeKey: Any]) -> Bool {
        guard let size = attributes[.size] as? Int64 else { return false }
        
        // 解析大小模式，如 ">1MB", "<100KB", "=0"
        let regex = try? NSRegularExpression(pattern: "([><=])([0-9]+)([KMGT]?B?)", options: .caseInsensitive)
        guard let match = regex?.firstMatch(in: pattern, range: NSRange(location: 0, length: pattern.count)) else {
            return false
        }
        
        let operatorSymbol = (pattern as NSString).substring(with: match.range(at: 1))
        let value = Int64((pattern as NSString).substring(with: match.range(at: 2))) ?? 0
        let unit = (pattern as NSString).substring(with: match.range(at: 3)).uppercased()
        
        let multiplier: Int64
        switch unit {
        case "KB", "K":
            multiplier = 1024
        case "MB", "M":
            multiplier = 1024 * 1024
        case "GB", "G":
            multiplier = 1024 * 1024 * 1024
        case "TB", "T":
            multiplier = 1024 * 1024 * 1024 * 1024
        default:
            multiplier = 1
        }
        
        let targetSize = value * multiplier
        
        switch operatorSymbol {
        case ">":
            return size > targetSize
        case "<":
            return size < targetSize
        case "=":
            return size == targetSize
        default:
            return false
        }
    }
    
    /// 匹配文件扩展名规则
    private func matchesExtensionRule(pattern: String, path: String) -> Bool {
        let pathExtension = (path as NSString).pathExtension.lowercased()
        let patterns = pattern.lowercased().split(separator: "|").map(String.init)
        
        return patterns.contains(pathExtension)
    }
    
    /// 匹配文件名规则
    private func matchesNameRule(pattern: String, path: String) -> Bool {
        let fileName = (path as NSString).lastPathComponent
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: fileName.count)
            return regex.firstMatch(in: fileName, range: range) != nil
        } catch {
            // 如果正则表达式无效，使用简单的包含匹配
            return fileName.lowercased().contains(pattern.lowercased())
        }
    }
    
    /// 匹配路径规则
    private func matchesPathRule(pattern: String, path: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: path.count)
            return regex.firstMatch(in: path, range: range) != nil
        } catch {
            return path.lowercased().contains(pattern.lowercased())
        }
    }
    
    /// 匹配属性规则
    private func matchesAttributeRule(pattern: String, attributes: [FileAttributeKey: Any]) -> Bool {
        // 简化的属性匹配，可以根据需要扩展
        if pattern.contains("readonly") {
            let permissions = attributes[.posixPermissions] as? Int16 ?? 0
            return (permissions & 0o200) == 0  // 没有写权限
        }
        
        if pattern.contains("hidden") {
            return attributes[.extensionHidden] as? Bool ?? false
        }
        
        return false
    }
    
    /// 匹配自定义规则
    private func matchesCustomRule(pattern: String, path: String, attributes: [FileAttributeKey: Any]) -> Bool {
        // 这里可以实现更复杂的自定义逻辑
        // 目前返回false，可以根据需要扩展
        return false
    }
    
    /// 获取文件属性
    private func getFileAttributes(at path: String) -> [FileAttributeKey: Any] {
        do {
            return try fileManager.attributesOfItem(atPath: path)
        } catch {
            return [:]
        }
    }
    
    /// 更新统计信息
    private func updateStatistics(totalFilesProcessed: Int = 0, filesIncluded: Int = 0, filesExcluded: Int = 0, zeroSizeFilesFiltered: Int = 0, symbolicLinksFiltered: Int = 0, hardLinksFiltered: Int = 0, ruleBasedFiltered: Int = 0) {
        statisticsLock.lock()
        defer { statisticsLock.unlock() }
        
        statistics = FilterStatistics(
            totalFilesProcessed: statistics.totalFilesProcessed + totalFilesProcessed,
            filesIncluded: statistics.filesIncluded + filesIncluded,
            filesExcluded: statistics.filesExcluded + filesExcluded,
            zeroSizeFilesFiltered: statistics.zeroSizeFilesFiltered + zeroSizeFilesFiltered,
            symbolicLinksFiltered: statistics.symbolicLinksFiltered + symbolicLinksFiltered,
            hardLinksFiltered: statistics.hardLinksFiltered + hardLinksFiltered,
            ruleBasedFiltered: statistics.ruleBasedFiltered + ruleBasedFiltered
        )
    }
}

// MARK: - Extensions

extension FileFilter {
    
    /// 导出过滤报告
    public func exportFilterReport() -> String {
        let stats = getStatistics()
        
        var report = "=== File Filter Report ===\n\n"
        
        report += "Generated: \(Date())\n"
        report += "Filter Settings:\n"
        report += "  Zero Size Files: \(filterZeroSizeFiles ? "Enabled" : "Disabled")\n"
        report += "  Symbolic Links: \(filterSymbolicLinks ? "Enabled" : "Disabled")\n"
        report += "  Duplicate Hard Links: \(filterDuplicateHardLinks ? "Enabled" : "Disabled")\n\n"
        
        report += "=== Statistics ===\n"
        report += "Total Files Processed: \(stats.totalFilesProcessed)\n"
        report += "Files Included: \(stats.filesIncluded)\n"
        report += "Files Excluded: \(stats.filesExcluded)\n"
        report += "Filter Rate: \(String(format: "%.2f%%", stats.filterRate * 100))\n\n"
        
        report += "=== Filter Breakdown ===\n"
        report += "Zero Size Files: \(stats.zeroSizeFilesFiltered)\n"
        report += "Symbolic Links: \(stats.symbolicLinksFiltered)\n"
        report += "Hard Links: \(stats.hardLinksFiltered)\n"
        report += "Rule-based: \(stats.ruleBasedFiltered)\n\n"
        
        let rules = getAllFilterRules()
        report += "=== Active Rules (\(rules.count)) ===\n"
        for rule in rules {
            let status = rule.isEnabled ? "✓" : "✗"
            report += "\(status) [\(rule.priority)] \(rule.operation) \(rule.type): \(rule.pattern)\n"
        }
        
        return report
    }
}
