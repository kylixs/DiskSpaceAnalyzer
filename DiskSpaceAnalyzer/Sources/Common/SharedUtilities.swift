import Foundation
import AppKit

// MARK: - 共享工具类
// 这个文件包含所有模块共享的工具类和扩展，避免重复定义

/// 字节格式化工具
public struct ByteFormatter {
    public static let shared = ByteFormatter()
    
    private let formatter: ByteCountFormatter
    
    private init() {
        self.formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
    }
    
    public func string(fromByteCount bytes: Int64) -> String {
        return formatter.string(fromByteCount: bytes)
    }
    
    public func string(fromBytes bytes: Int) -> String {
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

/// 数字格式化工具
public struct NumberFormatter {
    public static let shared = NumberFormatter()
    
    private let formatter: Foundation.NumberFormatter
    
    private init() {
        self.formatter = Foundation.NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.groupingSeparator = ","
    }
    
    public func string(from number: Int) -> String {
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    public func string(from number: Double) -> String {
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    public func compactString(from number: Int) -> String {
        let absNumber = abs(number)
        let sign = number < 0 ? "-" : ""
        
        switch absNumber {
        case 0..<1_000:
            return "\(sign)\(absNumber)"
        case 1_000..<1_000_000:
            let value = Double(absNumber) / 1_000
            return String(format: "%@%.1fK", sign, value)
        case 1_000_000..<1_000_000_000:
            let value = Double(absNumber) / 1_000_000
            return String(format: "%@%.1fM", sign, value)
        default:
            let value = Double(absNumber) / 1_000_000_000
            return String(format: "%@%.1fB", sign, value)
        }
    }
}

/// 时间格式化工具
public struct TimeFormatter {
    public static let shared = TimeFormatter()
    
    private init() {}
    
    public func string(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    public func shortString(from timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        
        if totalSeconds < 60 {
            return "\(totalSeconds)秒"
        } else if totalSeconds < 3600 {
            let minutes = totalSeconds / 60
            return "\(minutes)分钟"
        } else {
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            if minutes > 0 {
                return "\(hours)小时\(minutes)分钟"
            } else {
                return "\(hours)小时"
            }
        }
    }
}

/// 路径工具
public struct PathUtilities {
    public static func fileName(from path: String) -> String {
        return (path as NSString).lastPathComponent
    }
    
    public static func directoryName(from path: String) -> String {
        return (path as NSString).deletingLastPathComponent
    }
    
    public static func fileExtension(from path: String) -> String {
        return (path as NSString).pathExtension.lowercased()
    }
    
    public static func isHidden(_ path: String) -> Bool {
        let fileName = self.fileName(from: path)
        return fileName.hasPrefix(".")
    }
    
    public static func isSystemFile(_ path: String) -> Bool {
        let fileName = self.fileName(from: path)
        let systemFiles = [".DS_Store", ".localized", "Thumbs.db", "desktop.ini"]
        return systemFiles.contains(fileName)
    }
    
    public static func sanitizePath(_ path: String) -> String {
        var sanitized = path
        
        // 移除多余的斜杠
        sanitized = sanitized.replacingOccurrences(of: "//+", with: "/", options: .regularExpression)
        
        // 移除末尾的斜杠（除非是根目录）
        if sanitized.count > 1 && sanitized.hasSuffix("/") {
            sanitized = String(sanitized.dropLast())
        }
        
        return sanitized
    }
    
    public static func relativePath(from basePath: String, to targetPath: String) -> String {
        let baseComponents = basePath.components(separatedBy: "/")
        let targetComponents = targetPath.components(separatedBy: "/")
        
        // 找到公共前缀
        var commonCount = 0
        for (base, target) in zip(baseComponents, targetComponents) {
            if base == target {
                commonCount += 1
            } else {
                break
            }
        }
        
        // 构建相对路径
        let upLevels = baseComponents.count - commonCount
        let downPath = targetComponents.dropFirst(commonCount)
        
        var relativeParts: [String] = []
        relativeParts.append(contentsOf: Array(repeating: "..", count: upLevels))
        relativeParts.append(contentsOf: downPath)
        
        return relativeParts.joined(separator: "/")
    }
}

/// 颜色工具
public struct ColorUtilities {
    public static func interpolate(from startColor: NSColor, to endColor: NSColor, progress: CGFloat) -> NSColor {
        let clampedProgress = max(0, min(1, progress))
        
        let startComponents = startColor.cgColor.components ?? [0, 0, 0, 1]
        let endComponents = endColor.cgColor.components ?? [0, 0, 0, 1]
        
        let red = startComponents[0] + (endComponents[0] - startComponents[0]) * clampedProgress
        let green = startComponents[1] + (endComponents[1] - startComponents[1]) * clampedProgress
        let blue = startComponents[2] + (endComponents[2] - startComponents[2]) * clampedProgress
        let alpha = startComponents[3] + (endComponents[3] - startComponents[3]) * clampedProgress
        
        return NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    public static func adjustBrightness(of color: NSColor, by factor: CGFloat) -> NSColor {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        let newBrightness = max(0, min(1, brightness * factor))
        return NSColor(hue: hue, saturation: saturation, brightness: newBrightness, alpha: alpha)
    }
    
    public static func withAlpha(_ color: NSColor, alpha: CGFloat) -> NSColor {
        return color.withAlphaComponent(max(0, min(1, alpha)))
    }
}

/// 几何工具
public struct GeometryUtilities {
    public static func aspectRatio(of size: Size) -> Double {
        return size.height > 0 ? size.width / size.height : 1.0
    }
    
    public static func scaleToFit(_ size: Size, in bounds: Size) -> Size {
        let scaleX = bounds.width / size.width
        let scaleY = bounds.height / size.height
        let scale = min(scaleX, scaleY)
        
        return Size(width: size.width * scale, height: size.height * scale)
    }
    
    public static func center(_ size: Size, in bounds: Size) -> Point {
        let x = (bounds.width - size.width) / 2
        let y = (bounds.height - size.height) / 2
        return Point(x: x, y: y)
    }
    
    public static func distance(from point1: Point, to point2: Point) -> Double {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
}

/// 性能监控工具
public struct PerformanceMonitor {
    public static func measureTime<T>(operation: () throws -> T) rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        return (result, endTime - startTime)
    }
    
    public static func measureTimeAsync<T>(operation: @escaping () async throws -> T) async rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        return (result, endTime - startTime)
    }
    
    public static func memoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

/// 线程安全工具
public class ThreadSafeCounter {
    private var _value: Int = 0
    private let queue = DispatchQueue(label: "ThreadSafeCounter", attributes: .concurrent)
    
    public var value: Int {
        return queue.sync { _value }
    }
    
    public func increment() -> Int {
        return queue.sync(flags: .barrier) {
            _value += 1
            return _value
        }
    }
    
    public func decrement() -> Int {
        return queue.sync(flags: .barrier) {
            _value -= 1
            return _value
        }
    }
    
    public func reset() {
        queue.sync(flags: .barrier) {
            _value = 0
        }
    }
}

/// 缓存工具
public class LRUCache<Key: Hashable, Value> {
    private class CacheNode {
        let key: Key
        var value: Value
        var prev: CacheNode?
        var next: CacheNode?
        
        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
    
    private let capacity: Int
    private var cache: [Key: CacheNode] = [:]
    private var head: CacheNode?
    private var tail: CacheNode?
    private let queue = DispatchQueue(label: "LRUCache", attributes: .concurrent)
    
    public init(capacity: Int) {
        self.capacity = max(1, capacity)
    }
    
    public func get(_ key: Key) -> Value? {
        return queue.sync {
            guard let node = cache[key] else { return nil }
            moveToHead(node)
            return node.value
        }
    }
    
    public func set(_ key: Key, value: Value) {
        queue.sync(flags: .barrier) {
            if let existingNode = cache[key] {
                existingNode.value = value
                moveToHead(existingNode)
            } else {
                let newNode = CacheNode(key: key, value: value)
                cache[key] = newNode
                addToHead(newNode)
                
                if cache.count > capacity {
                    if let tailNode = removeTail() {
                        cache.removeValue(forKey: tailNode.key)
                    }
                }
            }
        }
    }
    
    private func moveToHead(_ node: CacheNode) {
        removeNode(node)
        addToHead(node)
    }
    
    private func addToHead(_ node: CacheNode) {
        node.prev = nil
        node.next = head
        head?.prev = node
        head = node
        
        if tail == nil {
            tail = node
        }
    }
    
    private func removeNode(_ node: CacheNode) {
        node.prev?.next = node.next
        node.next?.prev = node.prev
        
        if head === node {
            head = node.next
        }
        
        if tail === node {
            tail = node.prev
        }
    }
    
    private func removeTail() -> CacheNode? {
        guard let tailNode = tail else { return nil }
        removeNode(tailNode)
        return tailNode
    }
}
