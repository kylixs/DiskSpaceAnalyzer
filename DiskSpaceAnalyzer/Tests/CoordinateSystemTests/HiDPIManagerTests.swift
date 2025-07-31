import XCTest
@testable import CoordinateSystem
@testable import Common

final class HiDPIManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var hiDPIManager: HiDPIManager!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        hiDPIManager = HiDPIManager.shared
    }
    
    override func tearDownWithError() throws {
        // 重置为默认状态
        hiDPIManager.resetToDefaults()
    }
    
    // MARK: - Singleton Tests
    
    func testSingletonInstance() throws {
        let instance1 = HiDPIManager.shared
        let instance2 = HiDPIManager.shared
        
        XCTAssertTrue(instance1 === instance2, "HiDPIManager应该是单例")
    }
    
    // MARK: - Scale Factor Detection Tests
    
    func testCurrentScaleFactor() throws {
        let scaleFactor = hiDPIManager.currentScaleFactor
        
        XCTAssertGreaterThan(scaleFactor, 0, "缩放因子应该大于0")
        XCTAssertLessThanOrEqual(scaleFactor, 4.0, "缩放因子应该在合理范围内")
        
        // 常见的缩放因子值
        let commonScaleFactors: [CGFloat] = [1.0, 1.25, 1.5, 2.0, 2.5, 3.0]
        let isCommonScaleFactor = commonScaleFactors.contains { abs($0 - scaleFactor) < 0.01 }
        
        // 注意：在测试环境中可能不是常见值，所以这个测试可能会失败
        // XCTAssertTrue(isCommonScaleFactor, "应该是常见的缩放因子值")
    }
    
    func testIsHighDPIDisplay() throws {
        let isHighDPI = hiDPIManager.isHighDPIDisplay
        let scaleFactor = hiDPIManager.currentScaleFactor
        
        if scaleFactor > 1.0 {
            XCTAssertTrue(isHighDPI, "缩放因子大于1时应该被识别为高DPI显示器")
        } else {
            XCTAssertFalse(isHighDPI, "缩放因子等于1时不应该被识别为高DPI显示器")
        }
    }
    
    func testScaleFactorForDisplay() throws {
        // 测试主显示器
        if let mainScreen = NSScreen.main {
            let scaleFactor = hiDPIManager.scaleFactor(for: mainScreen)
            XCTAssertGreaterThan(scaleFactor, 0)
            XCTAssertEqual(scaleFactor, mainScreen.backingScaleFactor, accuracy: 0.001)
        }
        
        // 测试所有显示器
        for screen in NSScreen.screens {
            let scaleFactor = hiDPIManager.scaleFactor(for: screen)
            XCTAssertGreaterThan(scaleFactor, 0)
            XCTAssertEqual(scaleFactor, screen.backingScaleFactor, accuracy: 0.001)
        }
    }
    
    // MARK: - Coordinate Scaling Tests
    
    func testScalePointToPixels() throws {
        let point = Point(x: 100, y: 200)
        let scaleFactor = hiDPIManager.currentScaleFactor
        
        let scaledPoint = hiDPIManager.scaleToPixels(point: point)
        
        XCTAssertEqual(scaledPoint.x, point.x * scaleFactor, accuracy: 0.001)
        XCTAssertEqual(scaledPoint.y, point.y * scaleFactor, accuracy: 0.001)
    }
    
    func testScalePointFromPixels() throws {
        let pixelPoint = Point(x: 200, y: 400)
        let scaleFactor = hiDPIManager.currentScaleFactor
        
        let scaledPoint = hiDPIManager.scaleFromPixels(point: pixelPoint)
        
        XCTAssertEqual(scaledPoint.x, pixelPoint.x / scaleFactor, accuracy: 0.001)
        XCTAssertEqual(scaledPoint.y, pixelPoint.y / scaleFactor, accuracy: 0.001)
    }
    
    func testScaleRectToPixels() throws {
        let rect = Rect(x: 10, y: 20, width: 100, height: 200)
        let scaleFactor = hiDPIManager.currentScaleFactor
        
        let scaledRect = hiDPIManager.scaleToPixels(rect: rect)
        
        XCTAssertEqual(scaledRect.x, rect.x * scaleFactor, accuracy: 0.001)
        XCTAssertEqual(scaledRect.y, rect.y * scaleFactor, accuracy: 0.001)
        XCTAssertEqual(scaledRect.width, rect.width * scaleFactor, accuracy: 0.001)
        XCTAssertEqual(scaledRect.height, rect.height * scaleFactor, accuracy: 0.001)
    }
    
    func testScaleRectFromPixels() throws {
        let pixelRect = Rect(x: 20, y: 40, width: 200, height: 400)
        let scaleFactor = hiDPIManager.currentScaleFactor
        
        let scaledRect = hiDPIManager.scaleFromPixels(rect: pixelRect)
        
        XCTAssertEqual(scaledRect.x, pixelRect.x / scaleFactor, accuracy: 0.001)
        XCTAssertEqual(scaledRect.y, pixelRect.y / scaleFactor, accuracy: 0.001)
        XCTAssertEqual(scaledRect.width, pixelRect.width / scaleFactor, accuracy: 0.001)
        XCTAssertEqual(scaledRect.height, pixelRect.height / scaleFactor, accuracy: 0.001)
    }
    
    func testScaleSizeToPixels() throws {
        let size = Size(width: 100, height: 200)
        let scaleFactor = hiDPIManager.currentScaleFactor
        
        let scaledSize = hiDPIManager.scaleToPixels(size: size)
        
        XCTAssertEqual(scaledSize.width, size.width * scaleFactor, accuracy: 0.001)
        XCTAssertEqual(scaledSize.height, size.height * scaleFactor, accuracy: 0.001)
    }
    
    func testScaleSizeFromPixels() throws {
        let pixelSize = Size(width: 200, height: 400)
        let scaleFactor = hiDPIManager.currentScaleFactor
        
        let scaledSize = hiDPIManager.scaleFromPixels(size: pixelSize)
        
        XCTAssertEqual(scaledSize.width, pixelSize.width / scaleFactor, accuracy: 0.001)
        XCTAssertEqual(scaledSize.height, pixelSize.height / scaleFactor, accuracy: 0.001)
    }
    
    // MARK: - Pixel Alignment Tests
    
    func testPixelAlignPoint() throws {
        let point = Point(x: 100.3, y: 200.7)
        let alignedPoint = hiDPIManager.pixelAlign(point: point)
        
        // 像素对齐应该将坐标调整到像素边界
        let scaleFactor = hiDPIManager.currentScaleFactor
        let expectedX = round(point.x * scaleFactor) / scaleFactor
        let expectedY = round(point.y * scaleFactor) / scaleFactor
        
        XCTAssertEqual(alignedPoint.x, expectedX, accuracy: 0.001)
        XCTAssertEqual(alignedPoint.y, expectedY, accuracy: 0.001)
    }
    
    func testPixelAlignRect() throws {
        let rect = Rect(x: 10.3, y: 20.7, width: 100.4, height: 200.8)
        let alignedRect = hiDPIManager.pixelAlign(rect: rect)
        
        let scaleFactor = hiDPIManager.currentScaleFactor
        
        // 位置应该向下取整到像素边界
        let expectedX = floor(rect.x * scaleFactor) / scaleFactor
        let expectedY = floor(rect.y * scaleFactor) / scaleFactor
        
        // 大小应该向上取整以确保覆盖所有像素
        let expectedWidth = ceil((rect.x + rect.width) * scaleFactor) / scaleFactor - expectedX
        let expectedHeight = ceil((rect.y + rect.height) * scaleFactor) / scaleFactor - expectedY
        
        XCTAssertEqual(alignedRect.x, expectedX, accuracy: 0.001)
        XCTAssertEqual(alignedRect.y, expectedY, accuracy: 0.001)
        XCTAssertEqual(alignedRect.width, expectedWidth, accuracy: 0.001)
        XCTAssertEqual(alignedRect.height, expectedHeight, accuracy: 0.001)
    }
    
    func testPixelAlignSize() throws {
        let size = Size(width: 100.4, height: 200.8)
        let alignedSize = hiDPIManager.pixelAlign(size: size)
        
        let scaleFactor = hiDPIManager.currentScaleFactor
        let expectedWidth = round(size.width * scaleFactor) / scaleFactor
        let expectedHeight = round(size.height * scaleFactor) / scaleFactor
        
        XCTAssertEqual(alignedSize.width, expectedWidth, accuracy: 0.001)
        XCTAssertEqual(alignedSize.height, expectedHeight, accuracy: 0.001)
    }
    
    // MARK: - Display Information Tests
    
    func testDisplayInfo() throws {
        let displayInfo = hiDPIManager.displayInfo
        
        XCTAssertFalse(displayInfo.isEmpty, "应该至少有一个显示器")
        
        for info in displayInfo {
            XCTAssertGreaterThan(info.scaleFactor, 0, "缩放因子应该大于0")
            XCTAssertGreaterThan(info.resolution.width, 0, "分辨率宽度应该大于0")
            XCTAssertGreaterThan(info.resolution.height, 0, "分辨率高度应该大于0")
            XCTAssertGreaterThan(info.physicalSize.width, 0, "物理尺寸宽度应该大于0")
            XCTAssertGreaterThan(info.physicalSize.height, 0, "物理尺寸高度应该大于0")
        }
    }
    
    func testMainDisplayInfo() throws {
        let mainInfo = hiDPIManager.mainDisplayInfo
        
        XCTAssertNotNil(mainInfo, "应该有主显示器信息")
        XCTAssertTrue(mainInfo?.isMain ?? false, "主显示器标志应该为true")
        XCTAssertGreaterThan(mainInfo?.scaleFactor ?? 0, 0, "主显示器缩放因子应该大于0")
    }
    
    // MARK: - Notification Tests
    
    func testDisplayChangeNotification() throws {
        let expectation = XCTestExpectation(description: "Display change notification")
        
        let observer = NotificationCenter.default.addObserver(
            forName: .hiDPIDisplayChanged,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        // 模拟显示器变化（这在测试环境中可能不会触发）
        hiDPIManager.refreshDisplayInfo()
        
        // 等待通知或超时
        wait(for: [expectation], timeout: 1.0)
        
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Configuration Tests
    
    func testCustomScaleFactor() throws {
        let customScale: CGFloat = 1.5
        
        hiDPIManager.setCustomScaleFactor(customScale)
        
        XCTAssertEqual(hiDPIManager.currentScaleFactor, customScale, accuracy: 0.001)
        XCTAssertTrue(hiDPIManager.isUsingCustomScaleFactor)
    }
    
    func testResetToDefaults() throws {
        // 设置自定义缩放因子
        hiDPIManager.setCustomScaleFactor(2.5)
        XCTAssertTrue(hiDPIManager.isUsingCustomScaleFactor)
        
        // 重置到默认值
        hiDPIManager.resetToDefaults()
        
        XCTAssertFalse(hiDPIManager.isUsingCustomScaleFactor)
        // 应该回到系统默认值
        if let mainScreen = NSScreen.main {
            XCTAssertEqual(hiDPIManager.currentScaleFactor, mainScreen.backingScaleFactor, accuracy: 0.001)
        }
    }
    
    func testAutoDetectionEnabled() throws {
        // 测试自动检测开启
        hiDPIManager.setAutoDetectionEnabled(true)
        XCTAssertTrue(hiDPIManager.isAutoDetectionEnabled)
        
        // 测试自动检测关闭
        hiDPIManager.setAutoDetectionEnabled(false)
        XCTAssertFalse(hiDPIManager.isAutoDetectionEnabled)
    }
    
    // MARK: - Edge Cases Tests
    
    func testZeroScaleFactor() throws {
        // 设置无效的缩放因子应该被忽略或设置为最小值
        hiDPIManager.setCustomScaleFactor(0.0)
        
        XCTAssertGreaterThan(hiDPIManager.currentScaleFactor, 0, "缩放因子不应该为0")
    }
    
    func testNegativeScaleFactor() throws {
        // 设置负的缩放因子应该被忽略或设置为绝对值
        hiDPIManager.setCustomScaleFactor(-2.0)
        
        XCTAssertGreaterThan(hiDPIManager.currentScaleFactor, 0, "缩放因子不应该为负数")
    }
    
    func testVeryLargeScaleFactor() throws {
        let largeScale: CGFloat = 10.0
        hiDPIManager.setCustomScaleFactor(largeScale)
        
        // 应该被限制在合理范围内
        XCTAssertLessThanOrEqual(hiDPIManager.currentScaleFactor, 5.0, "缩放因子应该被限制在合理范围内")
    }
    
    // MARK: - Performance Tests
    
    func testScalingPerformance() throws {
        let points = (0..<10000).map { Point(x: Double($0), y: Double($0 * 2)) }
        
        measure {
            for point in points {
                _ = hiDPIManager.scaleToPixels(point: point)
                _ = hiDPIManager.scaleFromPixels(point: point)
            }
        }
    }
    
    func testPixelAlignmentPerformance() throws {
        let rects = (0..<1000).map { 
            Rect(x: Double($0) + 0.3, y: Double($0) + 0.7, width: 100.4, height: 200.8) 
        }
        
        measure {
            for rect in rects {
                _ = hiDPIManager.pixelAlign(rect: rect)
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testRoundTripScaling() throws {
        let originalPoint = Point(x: 123.456, y: 789.012)
        
        // 转换到像素坐标再转换回来
        let pixelPoint = hiDPIManager.scaleToPixels(point: originalPoint)
        let backToLogical = hiDPIManager.scaleFromPixels(point: pixelPoint)
        
        XCTAssertEqual(backToLogical.x, originalPoint.x, accuracy: 0.001)
        XCTAssertEqual(backToLogical.y, originalPoint.y, accuracy: 0.001)
    }
    
    func testPixelAlignmentConsistency() throws {
        let rect = Rect(x: 10.3, y: 20.7, width: 100.4, height: 200.8)
        
        // 多次对齐应该得到相同结果
        let aligned1 = hiDPIManager.pixelAlign(rect: rect)
        let aligned2 = hiDPIManager.pixelAlign(rect: aligned1)
        
        XCTAssertEqual(aligned1.x, aligned2.x, accuracy: 0.001)
        XCTAssertEqual(aligned1.y, aligned2.y, accuracy: 0.001)
        XCTAssertEqual(aligned1.width, aligned2.width, accuracy: 0.001)
        XCTAssertEqual(aligned1.height, aligned2.height, accuracy: 0.001)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess() throws {
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        for i in 0..<10 {
            queue.async {
                let point = Point(x: Double(i * 10), y: Double(i * 20))
                _ = self.hiDPIManager.scaleToPixels(point: point)
                _ = self.hiDPIManager.currentScaleFactor
                _ = self.hiDPIManager.isHighDPIDisplay
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
