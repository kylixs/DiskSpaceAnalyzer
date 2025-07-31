import XCTest
@testable import Common

final class SharedEnumsTests: XCTestCase {
    
    // MARK: - ErrorSeverity Tests
    
    func testErrorSeverityRawValues() throws {
        XCTAssertEqual(ErrorSeverity.info.rawValue, "info")
        XCTAssertEqual(ErrorSeverity.warning.rawValue, "warning")
        XCTAssertEqual(ErrorSeverity.error.rawValue, "error")
        XCTAssertEqual(ErrorSeverity.critical.rawValue, "critical")
        XCTAssertEqual(ErrorSeverity.fatal.rawValue, "fatal")
    }
    
    func testErrorSeverityComparison() throws {
        XCTAssertTrue(ErrorSeverity.info < ErrorSeverity.warning)
        XCTAssertTrue(ErrorSeverity.warning < ErrorSeverity.error)
        XCTAssertTrue(ErrorSeverity.error < ErrorSeverity.critical)
        XCTAssertTrue(ErrorSeverity.critical < ErrorSeverity.fatal)
        
        XCTAssertFalse(ErrorSeverity.fatal < ErrorSeverity.info)
        XCTAssertFalse(ErrorSeverity.error < ErrorSeverity.warning)
    }
    
    func testErrorSeverityDisplayName() throws {
        XCTAssertEqual(ErrorSeverity.info.displayName, "信息")
        XCTAssertEqual(ErrorSeverity.warning.displayName, "警告")
        XCTAssertEqual(ErrorSeverity.error.displayName, "错误")
        XCTAssertEqual(ErrorSeverity.critical.displayName, "严重错误")
        XCTAssertEqual(ErrorSeverity.fatal.displayName, "致命错误")
    }
    
    // MARK: - ScanStatus Tests
    
    func testScanStatusRawValues() throws {
        XCTAssertEqual(ScanStatus.pending.rawValue, "pending")
        XCTAssertEqual(ScanStatus.preparing.rawValue, "preparing")
        XCTAssertEqual(ScanStatus.scanning.rawValue, "scanning")
        XCTAssertEqual(ScanStatus.processing.rawValue, "processing")
        XCTAssertEqual(ScanStatus.paused.rawValue, "paused")
        XCTAssertEqual(ScanStatus.completed.rawValue, "completed")
        XCTAssertEqual(ScanStatus.cancelled.rawValue, "cancelled")
        XCTAssertEqual(ScanStatus.failed.rawValue, "failed")
    }
    
    func testScanStatusIsActive() throws {
        XCTAssertFalse(ScanStatus.pending.isActive)
        XCTAssertTrue(ScanStatus.preparing.isActive)
        XCTAssertTrue(ScanStatus.scanning.isActive)
        XCTAssertTrue(ScanStatus.processing.isActive)
        XCTAssertFalse(ScanStatus.paused.isActive)
        XCTAssertFalse(ScanStatus.completed.isActive)
        XCTAssertFalse(ScanStatus.cancelled.isActive)
        XCTAssertFalse(ScanStatus.failed.isActive)
    }
    
    func testScanStatusIsFinished() throws {
        XCTAssertFalse(ScanStatus.pending.isFinished)
        XCTAssertFalse(ScanStatus.preparing.isFinished)
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
        
        // 完成状态不能转换到其他状态
        XCTAssertFalse(ScanStatus.completed.canTransitionTo(.scanning))
        XCTAssertFalse(ScanStatus.completed.canTransitionTo(.pending))
        XCTAssertFalse(ScanStatus.cancelled.canTransitionTo(.scanning))
        XCTAssertFalse(ScanStatus.failed.canTransitionTo(.scanning))
    }
    
    func testScanStatusDisplayName() throws {
        XCTAssertEqual(ScanStatus.pending.displayName, "等待中")
        XCTAssertEqual(ScanStatus.preparing.displayName, "准备中")
        XCTAssertEqual(ScanStatus.scanning.displayName, "扫描中")
        XCTAssertEqual(ScanStatus.processing.displayName, "处理中")
        XCTAssertEqual(ScanStatus.paused.displayName, "已暂停")
        XCTAssertEqual(ScanStatus.completed.displayName, "已完成")
        XCTAssertEqual(ScanStatus.cancelled.displayName, "已取消")
        XCTAssertEqual(ScanStatus.failed.displayName, "失败")
    }
    
    // MARK: - FileType Tests
    
    func testFileTypeRawValues() throws {
        XCTAssertEqual(FileType.directory.rawValue, "directory")
        XCTAssertEqual(FileType.regularFile.rawValue, "regularFile")
        XCTAssertEqual(FileType.symbolicLink.rawValue, "symbolicLink")
        XCTAssertEqual(FileType.hardLink.rawValue, "hardLink")
        XCTAssertEqual(FileType.unknown.rawValue, "unknown")
    }
    
    func testFileTypeDisplayName() throws {
        XCTAssertEqual(FileType.directory.displayName, "目录")
        XCTAssertEqual(FileType.regularFile.displayName, "文件")
        XCTAssertEqual(FileType.symbolicLink.displayName, "符号链接")
        XCTAssertEqual(FileType.hardLink.displayName, "硬链接")
        XCTAssertEqual(FileType.unknown.displayName, "未知")
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
        XCTAssertEqual(LogLevel.debug.rawValue, "debug")
        XCTAssertEqual(LogLevel.info.rawValue, "info")
        XCTAssertEqual(LogLevel.warning.rawValue, "warning")
        XCTAssertEqual(LogLevel.error.rawValue, "error")
    }
    
    func testLogLevelComparison() throws {
        XCTAssertTrue(LogLevel.debug < LogLevel.info)
        XCTAssertTrue(LogLevel.info < LogLevel.warning)
        XCTAssertTrue(LogLevel.warning < LogLevel.error)
        
        XCTAssertFalse(LogLevel.error < LogLevel.debug)
        XCTAssertFalse(LogLevel.error < LogLevel.warning)
    }
    
    func testLogLevelDescription() throws {
        XCTAssertEqual(LogLevel.debug.description, "DEBUG")
        XCTAssertEqual(LogLevel.info.description, "INFO")
        XCTAssertEqual(LogLevel.warning.description, "WARNING")
        XCTAssertEqual(LogLevel.error.description, "ERROR")
    }
    
    func testLogLevelShouldLog() throws {
        let currentLevel = LogLevel.warning
        
        XCTAssertFalse(LogLevel.debug.shouldLog(at: currentLevel))
        XCTAssertFalse(LogLevel.info.shouldLog(at: currentLevel))
        XCTAssertTrue(LogLevel.warning.shouldLog(at: currentLevel))
        XCTAssertTrue(LogLevel.error.shouldLog(at: currentLevel))
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
        let fileType = FileType.regularFile
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
        XCTAssertEqual(allCases.count, 8)
        XCTAssertTrue(allCases.contains(.pending))
        XCTAssertTrue(allCases.contains(.preparing))
        XCTAssertTrue(allCases.contains(.scanning))
        XCTAssertTrue(allCases.contains(.processing))
        XCTAssertTrue(allCases.contains(.paused))
        XCTAssertTrue(allCases.contains(.completed))
        XCTAssertTrue(allCases.contains(.cancelled))
        XCTAssertTrue(allCases.contains(.failed))
    }
    
    func testFileTypeAllCases() throws {
        let allCases = FileType.allCases
        XCTAssertGreaterThanOrEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.directory))
        XCTAssertTrue(allCases.contains(.regularFile))
        XCTAssertTrue(allCases.contains(.symbolicLink))
        XCTAssertTrue(allCases.contains(.hardLink))
        XCTAssertTrue(allCases.contains(.unknown))
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
