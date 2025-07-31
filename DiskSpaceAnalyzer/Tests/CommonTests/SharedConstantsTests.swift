import XCTest
@testable import Common

final class SharedConstantsTests: XCTestCase {
    
    // MARK: - Application Constants Tests
    
    func testApplicationConstants() throws {
        // 验证应用基本信息
        XCTAssertFalse(SharedConstants.appName.isEmpty, "应用名称不能为空")
        XCTAssertFalse(SharedConstants.appVersion.isEmpty, "应用版本不能为空")
        XCTAssertFalse(SharedConstants.appBundleId.isEmpty, "Bundle ID不能为空")
        
        // 验证版本格式
        let versionPattern = #"^\d+\.\d+(\.\d+)?$"#
        let versionRegex = try NSRegularExpression(pattern: versionPattern)
        let versionRange = NSRange(location: 0, length: SharedConstants.appVersion.count)
        XCTAssertTrue(versionRegex.firstMatch(in: SharedConstants.appVersion, range: versionRange) != nil,
                     "版本号格式应为 x.y 或 x.y.z")
        
        // 验证Bundle ID格式
        XCTAssertTrue(SharedConstants.appBundleId.contains("."), "Bundle ID应包含域名格式")
    }
    
    // MARK: - File System Constants Tests
    
    func testFileSystemConstants() throws {
        // 验证文件大小限制
        XCTAssertGreaterThan(SharedConstants.maxFileSize, 0, "最大文件大小应大于0")
        XCTAssertLessThanOrEqual(SharedConstants.maxFileSize, Int64.max, "最大文件大小不应超过Int64最大值")
        
        // 验证目录深度限制
        XCTAssertGreaterThan(SharedConstants.maxDirectoryDepth, 0, "最大目录深度应大于0")
        XCTAssertLessThan(SharedConstants.maxDirectoryDepth, 1000, "最大目录深度应在合理范围内")
        
        // 验证扫描限制
        XCTAssertGreaterThan(SharedConstants.maxFilesPerDirectory, 0, "每目录最大文件数应大于0")
        XCTAssertGreaterThan(SharedConstants.scanTimeoutSeconds, 0, "扫描超时时间应大于0")
    }
    
    // MARK: - Cache Constants Tests
    
    func testCacheConstants() throws {
        // 验证缓存大小
        XCTAssertGreaterThan(SharedConstants.defaultCacheSize, 0, "默认缓存大小应大于0")
        XCTAssertLessThan(SharedConstants.defaultCacheSize, 1024 * 1024 * 1024, "缓存大小应在合理范围内") // < 1GB
        
        // 验证缓存过期时间
        XCTAssertGreaterThan(SharedConstants.cacheExpirationTime, 0, "缓存过期时间应大于0")
        XCTAssertLessThan(SharedConstants.cacheExpirationTime, 86400 * 30, "缓存过期时间应在合理范围内") // < 30天
        
        // 验证最大缓存条目数
        XCTAssertGreaterThan(SharedConstants.maxCacheEntries, 0, "最大缓存条目数应大于0")
        XCTAssertLessThan(SharedConstants.maxCacheEntries, 1000000, "最大缓存条目数应在合理范围内")
    }
    
    // MARK: - UI Constants Tests
    
    func testUIConstants() throws {
        // 验证最小窗口尺寸
        XCTAssertGreaterThan(SharedConstants.minWindowWidth, 0, "最小窗口宽度应大于0")
        XCTAssertGreaterThan(SharedConstants.minWindowHeight, 0, "最小窗口高度应大于0")
        XCTAssertLessThan(SharedConstants.minWindowWidth, 2000, "最小窗口宽度应在合理范围内")
        XCTAssertLessThan(SharedConstants.minWindowHeight, 2000, "最小窗口高度应在合理范围内")
        
        // 验证默认窗口尺寸
        XCTAssertGreaterThanOrEqual(SharedConstants.defaultWindowWidth, SharedConstants.minWindowWidth,
                                   "默认窗口宽度应不小于最小宽度")
        XCTAssertGreaterThanOrEqual(SharedConstants.defaultWindowHeight, SharedConstants.minWindowHeight,
                                   "默认窗口高度应不小于最小高度")
        
        // 验证动画时长
        XCTAssertGreaterThan(SharedConstants.animationDuration, 0, "动画时长应大于0")
        XCTAssertLessThan(SharedConstants.animationDuration, 5.0, "动画时长应在合理范围内")
    }
    
    // MARK: - TreeMap Constants Tests
    
    func testTreeMapConstants() throws {
        // 验证TreeMap相关常量
        XCTAssertGreaterThan(SharedConstants.minRectSize, 0, "最小矩形大小应大于0")
        XCTAssertLessThan(SharedConstants.minRectSize, 100, "最小矩形大小应在合理范围内")
        
        XCTAssertGreaterThan(SharedConstants.defaultPadding, 0, "默认内边距应大于0")
        XCTAssertLessThan(SharedConstants.defaultPadding, 50, "默认内边距应在合理范围内")
        
        XCTAssertGreaterThan(SharedConstants.maxZoomLevel, 1.0, "最大缩放级别应大于1")
        XCTAssertLessThan(SharedConstants.maxZoomLevel, 100.0, "最大缩放级别应在合理范围内")
        
        XCTAssertGreaterThan(SharedConstants.minZoomLevel, 0, "最小缩放级别应大于0")
        XCTAssertLessThan(SharedConstants.minZoomLevel, 1.0, "最小缩放级别应小于1")
        XCTAssertLessThan(SharedConstants.minZoomLevel, SharedConstants.maxZoomLevel, "最小缩放级别应小于最大缩放级别")
    }
    
    // MARK: - Performance Constants Tests
    
    func testPerformanceConstants() throws {
        // 验证性能相关常量
        XCTAssertGreaterThan(SharedConstants.maxConcurrentOperations, 0, "最大并发操作数应大于0")
        XCTAssertLessThan(SharedConstants.maxConcurrentOperations, 100, "最大并发操作数应在合理范围内")
        
        XCTAssertGreaterThan(SharedConstants.backgroundQueueQoS.rawValue, 0, "后台队列QoS应有效")
        
        XCTAssertGreaterThan(SharedConstants.memoryWarningThreshold, 0, "内存警告阈值应大于0")
        XCTAssertLessThan(SharedConstants.memoryWarningThreshold, 1.0, "内存警告阈值应小于1")
    }
    
    // MARK: - File Type Constants Tests
    
    func testFileTypeConstants() throws {
        // 验证支持的文件类型
        XCTAssertFalse(SharedConstants.supportedImageTypes.isEmpty, "支持的图片类型不应为空")
        XCTAssertFalse(SharedConstants.supportedVideoTypes.isEmpty, "支持的视频类型不应为空")
        XCTAssertFalse(SharedConstants.supportedAudioTypes.isEmpty, "支持的音频类型不应为空")
        XCTAssertFalse(SharedConstants.supportedDocumentTypes.isEmpty, "支持的文档类型不应为空")
        
        // 验证常见文件类型存在
        XCTAssertTrue(SharedConstants.supportedImageTypes.contains("jpg"), "应支持jpg图片")
        XCTAssertTrue(SharedConstants.supportedImageTypes.contains("png"), "应支持png图片")
        XCTAssertTrue(SharedConstants.supportedVideoTypes.contains("mp4"), "应支持mp4视频")
        XCTAssertTrue(SharedConstants.supportedAudioTypes.contains("mp3"), "应支持mp3音频")
        XCTAssertTrue(SharedConstants.supportedDocumentTypes.contains("pdf"), "应支持pdf文档")
        
        // 验证文件类型格式
        for imageType in SharedConstants.supportedImageTypes {
            XCTAssertFalse(imageType.isEmpty, "图片类型不应为空")
            XCTAssertFalse(imageType.contains("."), "图片类型不应包含点号")
        }
    }
    
    // MARK: - Color Constants Tests
    
    func testColorConstants() throws {
        // 验证默认颜色
        XCTAssertNotNil(SharedConstants.defaultFileColor, "默认文件颜色不应为nil")
        XCTAssertNotNil(SharedConstants.defaultDirectoryColor, "默认目录颜色不应为nil")
        XCTAssertNotNil(SharedConstants.highlightColor, "高亮颜色不应为nil")
        XCTAssertNotNil(SharedConstants.selectionColor, "选择颜色不应为nil")
        
        // 验证颜色数组
        XCTAssertFalse(SharedConstants.fileTypeColors.isEmpty, "文件类型颜色数组不应为空")
        XCTAssertGreaterThan(SharedConstants.fileTypeColors.count, 5, "应有足够的文件类型颜色")
        
        // 验证颜色有效性
        for color in SharedConstants.fileTypeColors {
            XCTAssertNotNil(color, "颜色不应为nil")
        }
    }
    
    // MARK: - Network Constants Tests
    
    func testNetworkConstants() throws {
        // 验证网络超时设置
        XCTAssertGreaterThan(SharedConstants.networkTimeout, 0, "网络超时时间应大于0")
        XCTAssertLessThan(SharedConstants.networkTimeout, 300, "网络超时时间应在合理范围内") // < 5分钟
        
        // 验证重试次数
        XCTAssertGreaterThanOrEqual(SharedConstants.maxRetryCount, 0, "最大重试次数应不小于0")
        XCTAssertLessThan(SharedConstants.maxRetryCount, 10, "最大重试次数应在合理范围内")
    }
    
    // MARK: - Logging Constants Tests
    
    func testLoggingConstants() throws {
        // 验证日志级别
        XCTAssertNotNil(SharedConstants.defaultLogLevel, "默认日志级别不应为nil")
        
        // 验证日志文件大小限制
        XCTAssertGreaterThan(SharedConstants.maxLogFileSize, 0, "最大日志文件大小应大于0")
        XCTAssertLessThan(SharedConstants.maxLogFileSize, 100 * 1024 * 1024, "日志文件大小应在合理范围内") // < 100MB
        
        // 验证日志文件数量限制
        XCTAssertGreaterThan(SharedConstants.maxLogFiles, 0, "最大日志文件数应大于0")
        XCTAssertLessThan(SharedConstants.maxLogFiles, 100, "最大日志文件数应在合理范围内")
    }
    
    // MARK: - Constants Consistency Tests
    
    func testConstantsConsistency() throws {
        // 验证窗口尺寸一致性
        XCTAssertLessThanOrEqual(SharedConstants.minWindowWidth, SharedConstants.defaultWindowWidth,
                                "最小窗口宽度应不大于默认宽度")
        XCTAssertLessThanOrEqual(SharedConstants.minWindowHeight, SharedConstants.defaultWindowHeight,
                                "最小窗口高度应不大于默认高度")
        
        // 验证缓存设置一致性
        XCTAssertLessThanOrEqual(SharedConstants.defaultCacheSize / SharedConstants.maxCacheEntries, 1024 * 1024,
                                "平均每个缓存条目大小应在合理范围内")
        
        // 验证性能设置一致性
        XCTAssertLessThanOrEqual(SharedConstants.maxConcurrentOperations, ProcessInfo.processInfo.processorCount * 4,
                                "最大并发操作数应与CPU核心数相关")
    }
}
