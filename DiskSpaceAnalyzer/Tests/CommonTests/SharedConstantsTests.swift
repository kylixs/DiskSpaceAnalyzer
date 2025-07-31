import XCTest
@testable import Common

final class SharedConstantsTests: BaseTestCase {
    
    // MARK: - Application Constants Tests
    
    func testApplicationConstants() throws {
        // 验证应用基本信息
        XCTAssertFalse(AppConstants.appName.isEmpty, "应用名称不能为空")
        XCTAssertFalse(AppConstants.appVersion.isEmpty, "应用版本不能为空")
        XCTAssertFalse(AppConstants.appBundleId.isEmpty, "Bundle ID不能为空")
        
        // 验证版本格式
        let versionPattern = #"^\d+\.\d+(\.\d+)?$"#
        let versionRegex = try NSRegularExpression(pattern: versionPattern)
        let versionRange = NSRange(location: 0, length: AppConstants.appVersion.count)
        XCTAssertTrue(versionRegex.firstMatch(in: AppConstants.appVersion, range: versionRange) != nil,
                     "版本号格式应为 x.y 或 x.y.z")
        
        // 验证Bundle ID格式
        XCTAssertTrue(AppConstants.appBundleId.contains("."), "Bundle ID应包含域名格式")
    }
    
    // MARK: - Window Constants Tests
    
    func testWindowConstants() throws {
        // 验证窗口尺寸
        XCTAssertGreaterThan(AppConstants.defaultWindowWidth, 0, "默认窗口宽度应大于0")
        XCTAssertGreaterThan(AppConstants.defaultWindowHeight, 0, "默认窗口高度应大于0")
        XCTAssertGreaterThan(AppConstants.minWindowWidth, 0, "最小窗口宽度应大于0")
        XCTAssertGreaterThan(AppConstants.minWindowHeight, 0, "最小窗口高度应大于0")
        
        // 验证窗口尺寸关系
        XCTAssertGreaterThanOrEqual(AppConstants.defaultWindowWidth, AppConstants.minWindowWidth,
                                   "默认窗口宽度应不小于最小宽度")
        XCTAssertGreaterThanOrEqual(AppConstants.defaultWindowHeight, AppConstants.minWindowHeight,
                                   "默认窗口高度应不小于最小高度")
    }
    
    // MARK: - UI Layout Constants Tests
    
    func testUILayoutConstants() throws {
        // 验证界面布局常量
        XCTAssertGreaterThan(AppConstants.toolbarHeight, 0, "工具栏高度应大于0")
        XCTAssertGreaterThan(AppConstants.progressBarHeight, 0, "进度栏高度应大于0")
        XCTAssertGreaterThan(AppConstants.statusBarHeight, 0, "状态栏高度应大于0")
        
        // 验证分栏比例
        XCTAssertGreaterThan(AppConstants.splitViewLeftRatio, 0, "左侧分栏比例应大于0")
        XCTAssertLessThan(AppConstants.splitViewLeftRatio, 1.0, "左侧分栏比例应小于1")
        XCTAssertGreaterThan(AppConstants.splitViewRightRatio, 0, "右侧分栏比例应大于0")
        XCTAssertLessThan(AppConstants.splitViewRightRatio, 1.0, "右侧分栏比例应小于1")
        
        // 验证分栏比例总和
        let totalRatio = AppConstants.splitViewLeftRatio + AppConstants.splitViewRightRatio
        XCTAssertEqual(totalRatio, 1.0, accuracy: 0.001, "分栏比例总和应为1.0")
    }
    
    // MARK: - Performance Thresholds Tests
    
    func testPerformanceThresholds() throws {
        // 验证性能阈值
        XCTAssertGreaterThan(PerformanceThresholds.uiResponseTime, 0, "UI响应时间阈值应大于0")
        XCTAssertLessThan(PerformanceThresholds.uiResponseTime, 1.0, "UI响应时间阈值应在合理范围内")
        
        XCTAssertGreaterThan(PerformanceThresholds.minScanSpeed, 0, "最小扫描速度应大于0")
        XCTAssertLessThan(PerformanceThresholds.maxScanSpeed, 100000, "最大扫描速度应在合理范围内")
        XCTAssertLessThan(PerformanceThresholds.minScanSpeed, PerformanceThresholds.maxScanSpeed,
                         "最小扫描速度应小于最大扫描速度")
        
        // 验证内存阈值
        XCTAssertGreaterThan(PerformanceThresholds.memoryWarningThreshold, 0, "内存警告阈值应大于0")
        XCTAssertGreaterThan(PerformanceThresholds.memoryCriticalThreshold, 0, "内存严重阈值应大于0")
        XCTAssertLessThan(PerformanceThresholds.memoryWarningThreshold, PerformanceThresholds.memoryCriticalThreshold,
                         "内存警告阈值应小于严重阈值")
        
        // 验证CPU阈值
        XCTAssertGreaterThan(PerformanceThresholds.cpuWarningThreshold, 0, "CPU警告阈值应大于0")
        XCTAssertLessThan(PerformanceThresholds.cpuWarningThreshold, 1.0, "CPU警告阈值应小于1")
        XCTAssertGreaterThan(PerformanceThresholds.cpuCriticalThreshold, 0, "CPU严重阈值应大于0")
        XCTAssertLessThan(PerformanceThresholds.cpuCriticalThreshold, 1.0, "CPU严重阈值应小于1")
        XCTAssertLessThan(PerformanceThresholds.cpuWarningThreshold, PerformanceThresholds.cpuCriticalThreshold,
                         "CPU警告阈值应小于严重阈值")
    }
    
    // MARK: - File Type Constants Tests
    
    func testSupportedFileTypes() throws {
        // 验证支持的文件类型
        XCTAssertFalse(SupportedFileTypes.supportedImageTypes.isEmpty, "支持的图片类型不应为空")
        XCTAssertFalse(SupportedFileTypes.supportedVideoTypes.isEmpty, "支持的视频类型不应为空")
        XCTAssertFalse(SupportedFileTypes.supportedAudioTypes.isEmpty, "支持的音频类型不应为空")
        XCTAssertFalse(SupportedFileTypes.supportedDocumentTypes.isEmpty, "支持的文档类型不应为空")
        
        // 验证常见文件类型存在
        XCTAssertTrue(SupportedFileTypes.supportedImageTypes.contains("jpg"), "应支持jpg图片")
        XCTAssertTrue(SupportedFileTypes.supportedImageTypes.contains("png"), "应支持png图片")
        XCTAssertTrue(SupportedFileTypes.supportedVideoTypes.contains("mp4"), "应支持mp4视频")
        XCTAssertTrue(SupportedFileTypes.supportedAudioTypes.contains("mp3"), "应支持mp3音频")
        XCTAssertTrue(SupportedFileTypes.supportedDocumentTypes.contains("pdf"), "应支持pdf文档")
        
        // 验证文件类型格式
        for imageType in SupportedFileTypes.supportedImageTypes {
            XCTAssertFalse(imageType.isEmpty, "图片类型不应为空")
            XCTAssertFalse(imageType.contains("."), "图片类型不应包含点号")
        }
    }
    
    // MARK: - Color Constants Tests
    
    func testDefaultColors() throws {
        // 验证默认颜色
        XCTAssertNotNil(DefaultColors.defaultFileColor, "默认文件颜色不应为nil")
        XCTAssertNotNil(DefaultColors.defaultDirectoryColor, "默认目录颜色不应为nil")
        XCTAssertNotNil(DefaultColors.highlightColor, "高亮颜色不应为nil")
        XCTAssertNotNil(DefaultColors.selectionColor, "选择颜色不应为nil")
        
        // 验证颜色数组
        XCTAssertFalse(DefaultColors.fileTypeColors.isEmpty, "文件类型颜色数组不应为空")
        XCTAssertGreaterThan(DefaultColors.fileTypeColors.count, 5, "应有足够的文件类型颜色")
        
        // 验证颜色有效性
        for color in DefaultColors.fileTypeColors {
            XCTAssertNotNil(color, "颜色不应为nil")
        }
    }
    
    // MARK: - Network Constants Tests
    
    func testNetworkConfig() throws {
        // 验证网络超时设置
        XCTAssertGreaterThan(NetworkConfig.networkTimeout, 0, "网络超时时间应大于0")
        XCTAssertLessThan(NetworkConfig.networkTimeout, 300, "网络超时时间应在合理范围内") // < 5分钟
        
        // 验证重试次数
        XCTAssertGreaterThanOrEqual(NetworkConfig.maxRetryCount, 0, "最大重试次数应不小于0")
        XCTAssertLessThan(NetworkConfig.maxRetryCount, 10, "最大重试次数应在合理范围内")
    }
    
    // MARK: - Log Constants Tests
    
    func testLogConfig() throws {
        // 验证日志级别
        XCTAssertNotNil(LogConfig.defaultLogLevel, "默认日志级别不应为nil")
        
        // 验证日志文件大小限制
        XCTAssertGreaterThan(LogConfig.maxLogFileSize, 0, "最大日志文件大小应大于0")
        XCTAssertLessThan(LogConfig.maxLogFileSize, 100 * 1024 * 1024, "日志文件大小应在合理范围内") // < 100MB
        
        // 验证日志文件数量限制
        XCTAssertGreaterThan(LogConfig.maxLogFiles, 0, "最大日志文件数应大于0")
        XCTAssertLessThan(LogConfig.maxLogFiles, 100, "最大日志文件数应在合理范围内")
    }
    
    // MARK: - TreeMap Constants Tests
    
    func testTreeMapConstants() throws {
        // 验证TreeMap相关常量
        XCTAssertGreaterThan(AppConstants.minRectSize, 0, "最小矩形大小应大于0")
        XCTAssertLessThan(AppConstants.minRectSize, 100, "最小矩形大小应在合理范围内")
        
        XCTAssertGreaterThan(AppConstants.maxRectSize, AppConstants.minRectSize, "最大矩形大小应大于最小矩形大小")
        
        XCTAssertGreaterThan(AppConstants.rectBorderWidth, 0, "矩形边框宽度应大于0")
        XCTAssertLessThan(AppConstants.rectBorderWidth, 10, "矩形边框宽度应在合理范围内")
        
        XCTAssertGreaterThanOrEqual(AppConstants.rectCornerRadius, 0, "矩形圆角半径应不小于0")
        XCTAssertLessThan(AppConstants.rectCornerRadius, 20, "矩形圆角半径应在合理范围内")
    }
    
    // MARK: - Animation Constants Tests
    
    func testAnimationConstants() throws {
        // 验证动画时长
        XCTAssertGreaterThan(AppConstants.defaultAnimationDuration, 0, "默认动画时长应大于0")
        XCTAssertLessThan(AppConstants.defaultAnimationDuration, 5.0, "默认动画时长应在合理范围内")
        
        XCTAssertGreaterThan(AppConstants.fastAnimationDuration, 0, "快速动画时长应大于0")
        XCTAssertLessThan(AppConstants.fastAnimationDuration, AppConstants.defaultAnimationDuration,
                         "快速动画时长应小于默认时长")
        
        XCTAssertGreaterThan(AppConstants.slowAnimationDuration, AppConstants.defaultAnimationDuration,
                         "慢速动画时长应大于默认时长")
        XCTAssertLessThan(AppConstants.slowAnimationDuration, 10.0, "慢速动画时长应在合理范围内")
    }
    
    // MARK: - File System Constants Tests
    
    func testFileSystemConstants() throws {
        // 验证文件系统限制
        XCTAssertGreaterThan(AppConstants.maxPathLength, 0, "最大路径长度应大于0")
        XCTAssertGreaterThan(AppConstants.maxFileNameLength, 0, "最大文件名长度应大于0")
        XCTAssertLessThan(AppConstants.maxFileNameLength, AppConstants.maxPathLength,
                         "最大文件名长度应小于最大路径长度")
        
        // 验证扫描超时
        XCTAssertGreaterThan(AppConstants.defaultScanTimeout, 0, "默认扫描超时时间应大于0")
        XCTAssertLessThan(AppConstants.defaultScanTimeout, 3600, "扫描超时时间应在合理范围内") // < 1小时
    }
    
    // MARK: - Performance Constants Tests
    
    func testPerformanceConstants() throws {
        // 验证性能相关常量
        XCTAssertGreaterThan(AppConstants.maxConcurrentScans, 0, "最大并发扫描数应大于0")
        XCTAssertLessThan(AppConstants.maxConcurrentScans, 20, "最大并发扫描数应在合理范围内")
        
        XCTAssertGreaterThan(AppConstants.defaultUpdateInterval, 0, "默认更新间隔应大于0")
        XCTAssertLessThan(AppConstants.defaultUpdateInterval, 5.0, "默认更新间隔应在合理范围内")
        
        XCTAssertGreaterThan(AppConstants.maxMemoryUsage, 0, "最大内存使用应大于0")
        XCTAssertLessThan(AppConstants.maxMemoryUsage, 1024 * 1024 * 1024, "最大内存使用应在合理范围内") // < 1GB
        
        XCTAssertGreaterThan(AppConstants.maxCacheSize, 0, "最大缓存大小应大于0")
        XCTAssertLessThan(AppConstants.maxCacheSize, 100000, "最大缓存大小应在合理范围内")
    }
    
    // MARK: - Constants Consistency Tests
    
    func testConstantsConsistency() throws {
        // 验证窗口尺寸一致性
        XCTAssertLessThanOrEqual(AppConstants.minWindowWidth, AppConstants.defaultWindowWidth,
                                "最小窗口宽度应不大于默认宽度")
        XCTAssertLessThanOrEqual(AppConstants.minWindowHeight, AppConstants.defaultWindowHeight,
                                "最小窗口高度应不大于默认高度")
        
        // 验证性能设置一致性
        XCTAssertLessThanOrEqual(AppConstants.maxConcurrentScans, ProcessInfo.processInfo.processorCount * 4,
                                "最大并发扫描数应与CPU核心数相关")
        
        // 验证动画时长一致性
        XCTAssertLessThan(AppConstants.fastAnimationDuration, AppConstants.defaultAnimationDuration,
                         "快速动画应比默认动画快")
        XCTAssertGreaterThan(AppConstants.slowAnimationDuration, AppConstants.defaultAnimationDuration,
                            "慢速动画应比默认动画慢")
    }
}
