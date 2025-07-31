import XCTest
@testable import Common

final class SharedEnumsTests: XCTestCase {
    
    // MARK: - ErrorSeverity Tests
    
    func testErrorSeverityRawValues() throws {
        XCTAssertEqual(ErrorSeverity.info.rawValue, 0)
        XCTAssertEqual(ErrorSeverity.warning.rawValue, 1)
        XCTAssertEqual(ErrorSeverity.error.rawValue, 2)
        XCTAssertEqual(ErrorSeverity.critical.rawValue, 3)
        XCTAssertEqual(ErrorSeverity.fatal.rawValue, 4)
    }
    
    func testErrorSeverityComparison() throws {
        XCTAssertTrue(ErrorSeverity.info < ErrorSeverity.warning)
        XCTAssertTrue(ErrorSeverity.warning < ErrorSeverity.error)
        XCTAssertTrue(ErrorSeverity.error < ErrorSeverity.critical)
        XCTAssertTrue(ErrorSeverity.critical < ErrorSeverity.fatal)
        
        XCTAssertFalse(ErrorSeverity.fatal < ErrorSeverity.info)
        XCTAssertFalse(ErrorSeverity.error < ErrorSeverity.warning)
    }
    
    func testErrorSeverityDescription() throws {
        XCTAssertEqual(ErrorSeverity.info.description, "Info")
        XCTAssertEqual(ErrorSeverity.warning.description, "Warning")
        XCTAssertEqual(ErrorSeverity.error.description, "Error")
        XCTAssertEqual(ErrorSeverity.critical.description, "Critical")
        XCTAssertEqual(ErrorSeverity.fatal.description, "Fatal")
    }
    
    func testErrorSeverityIsSerious() throws {
        XCTAssertFalse(ErrorSeverity.info.isSerious)
        XCTAssertFalse(ErrorSeverity.warning.isSerious)
        XCTAssertTrue(ErrorSeverity.error.isSerious)
        XCTAssertTrue(ErrorSeverity.critical.isSerious)
        XCTAssertTrue(ErrorSeverity.fatal.isSerious)
    }
    
    // MARK: - ScanStatus Tests
    
    func testScanStatusRawValues() throws {
        XCTAssertEqual(ScanStatus.pending.rawValue, "pending")
        XCTAssertEqual(ScanStatus.scanning.rawValue, "scanning")
        XCTAssertEqual(ScanStatus.processing.rawValue, "processing")
        XCTAssertEqual(ScanStatus.paused.rawValue, "paused")
        XCTAssertEqual(ScanStatus.completed.rawValue, "completed")
        XCTAssertEqual(ScanStatus.cancelled.rawValue, "cancelled")
        XCTAssertEqual(ScanStatus.failed.rawValue, "failed")
    }
    
    func testScanStatusIsActive() throws {
        XCTAssertFalse(ScanStatus.pending.isActive)
        XCTAssertTrue(ScanStatus.scanning.isActive)
        XCTAssertTrue(ScanStatus.processing.isActive)
        XCTAssertFalse(ScanStatus.paused.isActive)
        XCTAssertFalse(ScanStatus.completed.isActive)
        XCTAssertFalse(ScanStatus.cancelled.isActive)
        XCTAssertFalse(ScanStatus.failed.isActive)
    }
    
    func testScanStatusIsFinished() throws {
        XCTAssertFalse(ScanStatus.pending.isFinished)
        XCTAssertFalse(ScanStatus.scanning.isFinished)
        XCTAssertFalse(ScanStatus.processing.isFinished)
        XCTAssertFalse(ScanStatus.paused.isFinished)
        XCTAssertTrue(ScanStatus.completed.isFinished)
        XCTAssertTrue(ScanStatus.cancelled.isFinished)
        XCTAssertTrue(ScanStatus.failed.isFinished)
    }
    
    func testScanStatusCanTransitionTo() throws {
        // 从pending可以转换到的状态
        XCTAssertTrue(ScanStatus.pending.canTransitionTo(.scanning))
        XCTAssertTrue(ScanStatus.pending.canTransitionTo(.cancelled))
        XCTAssertFalse(ScanStatus.pending.canTransitionTo(.processing))
        XCTAssertFalse(ScanStatus.pending.canTransitionTo(.completed))
        
        // 从scanning可以转换到的状态
        XCTAssertTrue(ScanStatus.scanning.canTransitionTo(.processing))
        XCTAssertTrue(ScanStatus.scanning.canTransitionTo(.paused))
        XCTAssertTrue(ScanStatus.scanning.canTransitionTo(.cancelled))
        XCTAssertTrue(ScanStatus.scanning.canTransitionTo(.failed))
        XCTAssertFalse(ScanStatus.scanning.canTransitionTo(.pending))
        
        // 从processing可以转换到的状态
        XCTAssertTrue(ScanStatus.processing.canTransitionTo(.completed))
        XCTAssertTrue(ScanStatus.processing.canTransitionTo(.failed))
        XCTAssertTrue(ScanStatus.processing.canTransitionTo(.cancelled))
        XCTAssertFalse(ScanStatus.processing.canTransitionTo(.scanning))
        
        // 从paused可以转换到的状态
        XCTAssertTrue(ScanStatus.paused.canTransitionTo(.scanning))
        XCTAssertTrue(ScanStatus.paused.canTransitionTo(.cancelled))
        XCTAssertFalse(ScanStatus.paused.canTransitionTo(.completed))
        
        // 完成状态不能转换到其他状态
        XCTAssertFalse(ScanStatus.completed.canTransitionTo(.scanning))
        XCTAssertFalse(ScanStatus.completed.canTransitionTo(.pending))
        XCTAssertFalse(ScanStatus.cancelled.canTransitionTo(.scanning))
        XCTAssertFalse(ScanStatus.failed.canTransitionTo(.scanning))
    }
    
    func testScanStatusDescription() throws {
        XCTAssertEqual(ScanStatus.pending.description, "Pending")
        XCTAssertEqual(ScanStatus.scanning.description, "Scanning")
        XCTAssertEqual(ScanStatus.processing.description, "Processing")
        XCTAssertEqual(ScanStatus.paused.description, "Paused")
        XCTAssertEqual(ScanStatus.completed.description, "Completed")
        XCTAssertEqual(ScanStatus.cancelled.description, "Cancelled")
        XCTAssertEqual(ScanStatus.failed.description, "Failed")
    }
    
    // MARK: - FileType Tests
    
    func testFileTypeRawValues() throws {
        XCTAssertEqual(FileType.file.rawValue, "file")
        XCTAssertEqual(FileType.directory.rawValue, "directory")
        XCTAssertEqual(FileType.symlink.rawValue, "symlink")
        XCTAssertEqual(FileType.unknown.rawValue, "unknown")
    }
    
    func testFileTypeFromExtension() throws {
        // 图片文件
        XCTAssertEqual(FileType.fromExtension("jpg"), .image)
        XCTAssertEqual(FileType.fromExtension("PNG"), .image)
        XCTAssertEqual(FileType.fromExtension("gif"), .image)
        
        // 视频文件
        XCTAssertEqual(FileType.fromExtension("mp4"), .video)
        XCTAssertEqual(FileType.fromExtension("MOV"), .video)
        XCTAssertEqual(FileType.fromExtension("avi"), .video)
        
        // 音频文件
        XCTAssertEqual(FileType.fromExtension("mp3"), .audio)
        XCTAssertEqual(FileType.fromExtension("WAV"), .audio)
        XCTAssertEqual(FileType.fromExtension("flac"), .audio)
        
        // 文档文件
        XCTAssertEqual(FileType.fromExtension("pdf"), .document)
        XCTAssertEqual(FileType.fromExtension("DOC"), .document)
        XCTAssertEqual(FileType.fromExtension("txt"), .document)
        
        // 代码文件
        XCTAssertEqual(FileType.fromExtension("swift"), .code)
        XCTAssertEqual(FileType.fromExtension("py"), .code)
        XCTAssertEqual(FileType.fromExtension("js"), .code)
        
        // 压缩文件
        XCTAssertEqual(FileType.fromExtension("zip"), .archive)
        XCTAssertEqual(FileType.fromExtension("TAR"), .archive)
        XCTAssertEqual(FileType.fromExtension("gz"), .archive)
        
        // 未知扩展名
        XCTAssertEqual(FileType.fromExtension("xyz"), .file)
        XCTAssertEqual(FileType.fromExtension(""), .file)
    }
    
    func testFileTypeIsMedia() throws {
        XCTAssertTrue(FileType.image.isMedia)
        XCTAssertTrue(FileType.video.isMedia)
        XCTAssertTrue(FileType.audio.isMedia)
        XCTAssertFalse(FileType.document.isMedia)
        XCTAssertFalse(FileType.code.isMedia)
        XCTAssertFalse(FileType.file.isMedia)
    }
    
    func testFileTypeDescription() throws {
        XCTAssertEqual(FileType.file.description, "File")
        XCTAssertEqual(FileType.directory.description, "Directory")
        XCTAssertEqual(FileType.image.description, "Image")
        XCTAssertEqual(FileType.video.description, "Video")
        XCTAssertEqual(FileType.audio.description, "Audio")
        XCTAssertEqual(FileType.document.description, "Document")
        XCTAssertEqual(FileType.code.description, "Code")
        XCTAssertEqual(FileType.archive.description, "Archive")
        XCTAssertEqual(FileType.symlink.description, "Symlink")
        XCTAssertEqual(FileType.unknown.description, "Unknown")
    }
    
    // MARK: - SortOrder Tests
    
    func testSortOrderRawValues() throws {
        XCTAssertEqual(SortOrder.name.rawValue, "name")
        XCTAssertEqual(SortOrder.size.rawValue, "size")
        XCTAssertEqual(SortOrder.type.rawValue, "type")
        XCTAssertEqual(SortOrder.dateModified.rawValue, "dateModified")
        XCTAssertEqual(SortOrder.dateCreated.rawValue, "dateCreated")
    }
    
    func testSortOrderDescription() throws {
        XCTAssertEqual(SortOrder.name.description, "Name")
        XCTAssertEqual(SortOrder.size.description, "Size")
        XCTAssertEqual(SortOrder.type.description, "Type")
        XCTAssertEqual(SortOrder.dateModified.description, "Date Modified")
        XCTAssertEqual(SortOrder.dateCreated.description, "Date Created")
    }
    
    func testSortOrderIsDateBased() throws {
        XCTAssertFalse(SortOrder.name.isDateBased)
        XCTAssertFalse(SortOrder.size.isDateBased)
        XCTAssertFalse(SortOrder.type.isDateBased)
        XCTAssertTrue(SortOrder.dateModified.isDateBased)
        XCTAssertTrue(SortOrder.dateCreated.isDateBased)
    }
    
    // MARK: - ViewMode Tests
    
    func testViewModeRawValues() throws {
        XCTAssertEqual(ViewMode.treemap.rawValue, "treemap")
        XCTAssertEqual(ViewMode.list.rawValue, "list")
        XCTAssertEqual(ViewMode.tree.rawValue, "tree")
        XCTAssertEqual(ViewMode.sunburst.rawValue, "sunburst")
    }
    
    func testViewModeDescription() throws {
        XCTAssertEqual(ViewMode.treemap.description, "TreeMap")
        XCTAssertEqual(ViewMode.list.description, "List")
        XCTAssertEqual(ViewMode.tree.description, "Tree")
        XCTAssertEqual(ViewMode.sunburst.description, "Sunburst")
    }
    
    func testViewModeSupportsZoom() throws {
        XCTAssertTrue(ViewMode.treemap.supportsZoom)
        XCTAssertFalse(ViewMode.list.supportsZoom)
        XCTAssertTrue(ViewMode.tree.supportsZoom)
        XCTAssertTrue(ViewMode.sunburst.supportsZoom)
    }
    
    func testViewModeIsHierarchical() throws {
        XCTAssertTrue(ViewMode.treemap.isHierarchical)
        XCTAssertFalse(ViewMode.list.isHierarchical)
        XCTAssertTrue(ViewMode.tree.isHierarchical)
        XCTAssertTrue(ViewMode.sunburst.isHierarchical)
    }
    
    // MARK: - LogLevel Tests
    
    func testLogLevelRawValues() throws {
        XCTAssertEqual(LogLevel.debug.rawValue, 0)
        XCTAssertEqual(LogLevel.info.rawValue, 1)
        XCTAssertEqual(LogLevel.warning.rawValue, 2)
        XCTAssertEqual(LogLevel.error.rawValue, 3)
        XCTAssertEqual(LogLevel.critical.rawValue, 4)
    }
    
    func testLogLevelComparison() throws {
        XCTAssertTrue(LogLevel.debug < LogLevel.info)
        XCTAssertTrue(LogLevel.info < LogLevel.warning)
        XCTAssertTrue(LogLevel.warning < LogLevel.error)
        XCTAssertTrue(LogLevel.error < LogLevel.critical)
        
        XCTAssertFalse(LogLevel.critical < LogLevel.debug)
        XCTAssertFalse(LogLevel.error < LogLevel.warning)
    }
    
    func testLogLevelDescription() throws {
        XCTAssertEqual(LogLevel.debug.description, "DEBUG")
        XCTAssertEqual(LogLevel.info.description, "INFO")
        XCTAssertEqual(LogLevel.warning.description, "WARNING")
        XCTAssertEqual(LogLevel.error.description, "ERROR")
        XCTAssertEqual(LogLevel.critical.description, "CRITICAL")
    }
    
    func testLogLevelShouldLog() throws {
        let currentLevel = LogLevel.warning
        
        XCTAssertFalse(LogLevel.debug.shouldLog(at: currentLevel))
        XCTAssertFalse(LogLevel.info.shouldLog(at: currentLevel))
        XCTAssertTrue(LogLevel.warning.shouldLog(at: currentLevel))
        XCTAssertTrue(LogLevel.error.shouldLog(at: currentLevel))
        XCTAssertTrue(LogLevel.critical.shouldLog(at: currentLevel))
    }
    
    // MARK: - Enum Codable Tests
    
    func testErrorSeverityCodable() throws {
        let severity = ErrorSeverity.critical
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(severity)
        let decoded = try decoder.decode(ErrorSeverity.self, from: data)
        
        XCTAssertEqual(severity, decoded)
    }
    
    func testScanStatusCodable() throws {
        let status = ScanStatus.processing
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(status)
        let decoded = try decoder.decode(ScanStatus.self, from: data)
        
        XCTAssertEqual(status, decoded)
    }
    
    func testFileTypeCodable() throws {
        let fileType = FileType.image
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(fileType)
        let decoded = try decoder.decode(FileType.self, from: data)
        
        XCTAssertEqual(fileType, decoded)
    }
    
    func testViewModeCodable() throws {
        let viewMode = ViewMode.treemap
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(viewMode)
        let decoded = try decoder.decode(ViewMode.self, from: data)
        
        XCTAssertEqual(viewMode, decoded)
    }
    
    // MARK: - Enum CaseIterable Tests
    
    func testErrorSeverityAllCases() throws {
        let allCases = ErrorSeverity.allCases
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.info))
        XCTAssertTrue(allCases.contains(.warning))
        XCTAssertTrue(allCases.contains(.error))
        XCTAssertTrue(allCases.contains(.critical))
        XCTAssertTrue(allCases.contains(.fatal))
    }
    
    func testScanStatusAllCases() throws {
        let allCases = ScanStatus.allCases
        XCTAssertEqual(allCases.count, 7)
        XCTAssertTrue(allCases.contains(.pending))
        XCTAssertTrue(allCases.contains(.scanning))
        XCTAssertTrue(allCases.contains(.processing))
        XCTAssertTrue(allCases.contains(.paused))
        XCTAssertTrue(allCases.contains(.completed))
        XCTAssertTrue(allCases.contains(.cancelled))
        XCTAssertTrue(allCases.contains(.failed))
    }
    
    func testFileTypeAllCases() throws {
        let allCases = FileType.allCases
        XCTAssertGreaterThanOrEqual(allCases.count, 10)
        XCTAssertTrue(allCases.contains(.file))
        XCTAssertTrue(allCases.contains(.directory))
        XCTAssertTrue(allCases.contains(.image))
        XCTAssertTrue(allCases.contains(.video))
        XCTAssertTrue(allCases.contains(.audio))
    }
    
    func testViewModeAllCases() throws {
        let allCases = ViewMode.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.treemap))
        XCTAssertTrue(allCases.contains(.list))
        XCTAssertTrue(allCases.contains(.tree))
        XCTAssertTrue(allCases.contains(.sunburst))
    }
}
