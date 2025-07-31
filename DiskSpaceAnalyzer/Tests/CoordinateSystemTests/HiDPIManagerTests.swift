import XCTest
import AppKit
@testable import CoordinateSystem
@testable import Common

final class HiDPIManagerTests: BaseTestCase {
    
    var hiDPIManager: HiDPIManager!
    
    override func setUpWithError() throws {
        hiDPIManager = HiDPIManager.shared
        hiDPIManager.initialize()
    }
    
    override func tearDownWithError() throws {
        hiDPIManager = nil
    }
    
    // MARK: - Initialization Tests
    
    func testHiDPIManagerInitialization() throws {
        XCTAssertNotNil(hiDPIManager)
        XCTAssertGreaterThan(hiDPIManager.mainDisplayScaleFactor, 0)
        XCTAssertNotNil(hiDPIManager.displayScaleFactors)
    }
    
    func testMainDisplayScaleFactor() throws {
        let scaleFactor = hiDPIManager.mainDisplayScaleFactor
        
        XCTAssertGreaterThan(scaleFactor, 0, "主显示器缩放因子应该大于0")
        XCTAssertLessThanOrEqual(scaleFactor, 5.0, "缩放因子应该在合理范围内")
        
        // 验证与系统值一致
        if let mainScreen = NSScreen.main {
            XCTAssertEqual(scaleFactor, mainScreen.backingScaleFactor, accuracy: 0.001)
        }
    }
    
    func testIsHiDPI() throws {
        let isHiDPI = hiDPIManager.isHiDPI
        let scaleFactor = hiDPIManager.mainDisplayScaleFactor
        
        if scaleFactor > 1.0 {
            XCTAssertTrue(isHiDPI, "缩放因子大于1时应该被识别为HiDPI")
        } else {
            XCTAssertFalse(isHiDPI, "缩放因子等于1时不应该被识别为HiDPI")
        }
    }
    
    // MARK: - Scale Factor Tests
    
    func testGetScaleFactorForScreen() throws {
        // 测试主显示器
        if let mainScreen = NSScreen.main {
            let scaleFactor = hiDPIManager.getScaleFactor(for: mainScreen)
            XCTAssertGreaterThan(scaleFactor, 0)
            XCTAssertEqual(scaleFactor, mainScreen.backingScaleFactor, accuracy: 0.001)
        }
        
        // 测试所有显示器
        for screen in NSScreen.screens {
            let scaleFactor = hiDPIManager.getScaleFactor(for: screen)
            XCTAssertGreaterThan(scaleFactor, 0)
            XCTAssertEqual(scaleFactor, screen.backingScaleFactor, accuracy: 0.001)
        }
    }
    
    func testGetScaleFactorForNilScreen() throws {
        let scaleFactor = hiDPIManager.getScaleFactor(for: nil)
        XCTAssertEqual(scaleFactor, hiDPIManager.mainDisplayScaleFactor, accuracy: 0.001)
    }
    
    // MARK: - Pixel Alignment Tests
    
    func testPixelAlignPoint() throws {
        let point = CGPoint(x: 100.3, y: 200.7)
        let alignedPoint = hiDPIManager.pixelAlign(point, on: NSScreen.main)
        
        // 像素对齐应该将坐标调整到像素边界
        let scaleFactor = hiDPIManager.mainDisplayScaleFactor
        let expectedX = round(point.x * scaleFactor) / scaleFactor
        let expectedY = round(point.y * scaleFactor) / scaleFactor
        
        XCTAssertEqual(alignedPoint.x, expectedX, accuracy: 0.001)
        XCTAssertEqual(alignedPoint.y, expectedY, accuracy: 0.001)
    }
    
    func testPixelAlignPointWithNilScreen() throws {
        let point = CGPoint(x: 100.3, y: 200.7)
        let alignedPoint = hiDPIManager.pixelAlign(point, on: nil)
        
        // 应该使用主显示器的缩放因子
        let scaleFactor = hiDPIManager.mainDisplayScaleFactor
        let expectedX = round(point.x * scaleFactor) / scaleFactor
        let expectedY = round(point.y * scaleFactor) / scaleFactor
        
        XCTAssertEqual(alignedPoint.x, expectedX, accuracy: 0.001)
        XCTAssertEqual(alignedPoint.y, expectedY, accuracy: 0.001)
    }
    
    func testPixelAlignWithIntegerCoordinates() throws {
        let point = CGPoint(x: 100, y: 200)
        let alignedPoint = hiDPIManager.pixelAlign(point, on: NSScreen.main)
        
        // 整数坐标应该保持不变
        XCTAssertEqual(alignedPoint.x, point.x, accuracy: 0.001)
        XCTAssertEqual(alignedPoint.y, point.y, accuracy: 0.001)
    }
    
    // MARK: - Display Scale Factors Tests
    
    func testDisplayScaleFactors() throws {
        let scaleFactors = hiDPIManager.displayScaleFactors
        
        // 在某些测试环境中，displayScaleFactors可能为空，这是正常的
        // 验证所有缩放因子都是正数（如果存在的话）
        for (_, scaleFactor) in scaleFactors {
            XCTAssertGreaterThan(scaleFactor, 0, "所有缩放因子都应该大于0")
            XCTAssertLessThanOrEqual(scaleFactor, 5.0, "缩放因子应该在合理范围内")
        }
        
        // 如果有缩放因子，验证主显示器的缩放因子在字典中
        if !scaleFactors.isEmpty {
            let mainScaleFactor = hiDPIManager.mainDisplayScaleFactor
            XCTAssertTrue(scaleFactors.values.contains(mainScaleFactor), "主显示器缩放因子应该在字典中")
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testZeroCoordinates() throws {
        let zeroPoint = CGPoint.zero
        let alignedPoint = hiDPIManager.pixelAlign(zeroPoint, on: NSScreen.main)
        
        XCTAssertEqual(alignedPoint.x, 0, accuracy: 0.001)
        XCTAssertEqual(alignedPoint.y, 0, accuracy: 0.001)
    }
    
    func testNegativeCoordinates() throws {
        let negativePoint = CGPoint(x: -100.3, y: -200.7)
        let alignedPoint = hiDPIManager.pixelAlign(negativePoint, on: NSScreen.main)
        
        let scaleFactor = hiDPIManager.mainDisplayScaleFactor
        let expectedX = round(negativePoint.x * scaleFactor) / scaleFactor
        let expectedY = round(negativePoint.y * scaleFactor) / scaleFactor
        
        XCTAssertEqual(alignedPoint.x, expectedX, accuracy: 0.001)
        XCTAssertEqual(alignedPoint.y, expectedY, accuracy: 0.001)
    }
    
    func testVeryLargeCoordinates() throws {
        let largePoint = CGPoint(x: 10000.5, y: 20000.7)
        let alignedPoint = hiDPIManager.pixelAlign(largePoint, on: NSScreen.main)
        
        let scaleFactor = hiDPIManager.mainDisplayScaleFactor
        let expectedX = round(largePoint.x * scaleFactor) / scaleFactor
        let expectedY = round(largePoint.y * scaleFactor) / scaleFactor
        
        XCTAssertEqual(alignedPoint.x, expectedX, accuracy: 0.001)
        XCTAssertEqual(alignedPoint.y, expectedY, accuracy: 0.001)
    }
    
    func testVerySmallCoordinates() throws {
        let smallPoint = CGPoint(x: 0.001, y: 0.002)
        let alignedPoint = hiDPIManager.pixelAlign(smallPoint, on: NSScreen.main)
        
        let scaleFactor = hiDPIManager.mainDisplayScaleFactor
        let expectedX = round(smallPoint.x * scaleFactor) / scaleFactor
        let expectedY = round(smallPoint.y * scaleFactor) / scaleFactor
        
        XCTAssertEqual(alignedPoint.x, expectedX, accuracy: 0.001)
        XCTAssertEqual(alignedPoint.y, expectedY, accuracy: 0.001)
    }
    
    // MARK: - Multiple Displays Tests
    
    func testMultipleDisplays() throws {
        let screens = NSScreen.screens
        
        for screen in screens {
            let scaleFactor = hiDPIManager.getScaleFactor(for: screen)
            XCTAssertGreaterThan(scaleFactor, 0)
            XCTAssertEqual(scaleFactor, screen.backingScaleFactor, accuracy: 0.001)
            
            // 测试像素对齐
            let testPoint = CGPoint(x: 100.5, y: 200.5)
            let alignedPoint = hiDPIManager.pixelAlign(testPoint, on: screen)
            
            let expectedX = round(testPoint.x * scaleFactor) / scaleFactor
            let expectedY = round(testPoint.y * scaleFactor) / scaleFactor
            
            XCTAssertEqual(alignedPoint.x, expectedX, accuracy: 0.001)
            XCTAssertEqual(alignedPoint.y, expectedY, accuracy: 0.001)
        }
    }
    
    // MARK: - Performance Tests
    
    func testPixelAlignPerformance() throws {
        let points = (0..<10000).map { CGPoint(x: Double($0) + 0.5, y: Double($0 * 2) + 0.7) }
        
        measure {
            for point in points {
                _ = hiDPIManager.pixelAlign(point, on: NSScreen.main)
            }
        }
    }
    
    func testGetScaleFactorPerformance() throws {
        let screens = Array(repeating: NSScreen.main, count: 10000)
        
        measure {
            for screen in screens {
                _ = hiDPIManager.getScaleFactor(for: screen)
            }
        }
    }
    
    // MARK: - Consistency Tests
    
    func testPixelAlignConsistency() throws {
        let point = CGPoint(x: 100.3, y: 200.7)
        
        // 多次对齐应该得到相同结果
        let aligned1 = hiDPIManager.pixelAlign(point, on: NSScreen.main)
        let aligned2 = hiDPIManager.pixelAlign(aligned1, on: NSScreen.main)
        
        XCTAssertEqual(aligned1.x, aligned2.x, accuracy: 0.001)
        XCTAssertEqual(aligned1.y, aligned2.y, accuracy: 0.001)
    }
    
    func testScaleFactorConsistency() throws {
        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("没有主显示器")
        }
        
        // 多次获取应该得到相同结果
        let factor1 = hiDPIManager.getScaleFactor(for: mainScreen)
        let factor2 = hiDPIManager.getScaleFactor(for: mainScreen)
        
        XCTAssertEqual(factor1, factor2, accuracy: 0.001)
    }
    
    // MARK: - Thread Safety Tests
    
    func testThreadSafety() throws {
        let expectation = XCTestExpectation(description: "Thread safety test")
        expectation.expectedFulfillmentCount = 10
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        for i in 0..<10 {
            queue.async {
                let point = CGPoint(x: Double(i * 10) + 0.5, y: Double(i * 20) + 0.7)
                _ = self.hiDPIManager.pixelAlign(point, on: NSScreen.main)
                _ = self.hiDPIManager.getScaleFactor(for: NSScreen.main)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
