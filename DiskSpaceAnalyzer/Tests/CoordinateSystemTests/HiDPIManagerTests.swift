import XCTest
@testable import Core

class HiDPIManagerTests: XCTestCase {
    
    var hiDPIManager: HiDPIManager!
    
    override func setUp() {
        super.setUp()
        hiDPIManager = HiDPIManager.shared
    }
    
    // MARK: - Scale Factor Tests
    
    func testMainDisplayScaleFactor() {
        let scaleFactor = hiDPIManager.getMainDisplayScaleFactor()
        
        XCTAssertGreaterThan(scaleFactor, 0, "Scale factor should be positive")
        XCTAssertLessThanOrEqual(scaleFactor, 4.0, "Scale factor should be reasonable")
    }
    
    func testScaleFactorForPoint() {
        let point = CGPoint(x: 100, y: 100)
        let scaleFactor = hiDPIManager.getScaleFactor(for: point)
        
        XCTAssertGreaterThan(scaleFactor, 0, "Scale factor should be positive")
        XCTAssertLessThanOrEqual(scaleFactor, 4.0, "Scale factor should be reasonable")
    }
    
    // MARK: - Scaling Tests
    
    func testApplyHiDPIScaling() {
        let point = CGPoint(x: 100, y: 200)
        let scaleFactor: CGFloat = 2.0
        let scaledPoint = hiDPIManager.applyHiDPIScaling(to: point, scaleFactor: scaleFactor)
        
        XCTAssertEqual(scaledPoint.x, 200, "X coordinate should be scaled")
        XCTAssertEqual(scaledPoint.y, 400, "Y coordinate should be scaled")
    }
    
    func testRemoveHiDPIScaling() {
        let scaledPoint = CGPoint(x: 200, y: 400)
        let scaleFactor: CGFloat = 2.0
        let originalPoint = hiDPIManager.removeHiDPIScaling(from: scaledPoint, scaleFactor: scaleFactor)
        
        XCTAssertEqual(originalPoint.x, 100, "X coordinate should be unscaled")
        XCTAssertEqual(originalPoint.y, 200, "Y coordinate should be unscaled")
    }
    
    func testScalingRoundTrip() {
        let originalPoint = CGPoint(x: 123.456, y: 789.012)
        let scaleFactor: CGFloat = 1.5
        
        let scaledPoint = hiDPIManager.applyHiDPIScaling(to: originalPoint, scaleFactor: scaleFactor)
        let unscaledPoint = hiDPIManager.removeHiDPIScaling(from: scaledPoint, scaleFactor: scaleFactor)
        
        XCTAssertEqual(unscaledPoint.x, originalPoint.x, accuracy: 0.001, "Round trip should preserve X coordinate")
        XCTAssertEqual(unscaledPoint.y, originalPoint.y, accuracy: 0.001, "Round trip should preserve Y coordinate")
    }
    
    // MARK: - Size Scaling Tests
    
    func testSizeScaling() {
        let size = CGSize(width: 100, height: 200)
        let scaleFactor: CGFloat = 2.0
        
        let scaledSize = hiDPIManager.applyHiDPIScaling(to: size, scaleFactor: scaleFactor)
        XCTAssertEqual(scaledSize.width, 200, "Width should be scaled")
        XCTAssertEqual(scaledSize.height, 400, "Height should be scaled")
        
        let unscaledSize = hiDPIManager.removeHiDPIScaling(from: scaledSize, scaleFactor: scaleFactor)
        XCTAssertEqual(unscaledSize.width, 100, "Width should be unscaled")
        XCTAssertEqual(unscaledSize.height, 200, "Height should be unscaled")
    }
    
    // MARK: - Rect Scaling Tests
    
    func testRectScaling() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 200)
        let scaleFactor: CGFloat = 2.0
        
        let scaledRect = hiDPIManager.applyHiDPIScaling(to: rect, scaleFactor: scaleFactor)
        XCTAssertEqual(scaledRect.origin.x, 20, "Origin X should be scaled")
        XCTAssertEqual(scaledRect.origin.y, 40, "Origin Y should be scaled")
        XCTAssertEqual(scaledRect.size.width, 200, "Width should be scaled")
        XCTAssertEqual(scaledRect.size.height, 400, "Height should be scaled")
        
        let unscaledRect = hiDPIManager.removeHiDPIScaling(from: scaledRect, scaleFactor: scaleFactor)
        XCTAssertEqual(unscaledRect.origin.x, 10, "Origin X should be unscaled")
        XCTAssertEqual(unscaledRect.origin.y, 20, "Origin Y should be unscaled")
        XCTAssertEqual(unscaledRect.size.width, 100, "Width should be unscaled")
        XCTAssertEqual(unscaledRect.size.height, 200, "Height should be unscaled")
    }
    
    // MARK: - Pixel Alignment Tests
    
    func testPixelAlignment() {
        let point = CGPoint(x: 100.7, y: 200.3)
        let scaleFactor: CGFloat = 1.0
        let alignedPoint = hiDPIManager.pixelAlign(point, scaleFactor: scaleFactor)
        
        XCTAssertEqual(alignedPoint.x, 101, "X should be rounded to nearest pixel")
        XCTAssertEqual(alignedPoint.y, 200, "Y should be rounded to nearest pixel")
    }
    
    func testPixelAlignmentWithScaling() {
        let point = CGPoint(x: 100.7, y: 200.3)
        let scaleFactor: CGFloat = 2.0
        let alignedPoint = hiDPIManager.pixelAlign(point, scaleFactor: scaleFactor)
        
        // With 2x scaling, should align to 0.5 pixel boundaries
        XCTAssertEqual(alignedPoint.x, 101.0, accuracy: 0.01, "X should be aligned to scaled pixel boundary")
        XCTAssertEqual(alignedPoint.y, 200.0, accuracy: 0.01, "Y should be aligned to scaled pixel boundary")
    }
    
    func testRectPixelAlignment() {
        let rect = CGRect(x: 10.3, y: 20.7, width: 100.4, height: 200.8)
        let scaleFactor: CGFloat = 1.0
        let alignedRect = hiDPIManager.pixelAlign(rect, scaleFactor: scaleFactor)
        
        XCTAssertEqual(alignedRect.origin.x, 10, "Origin X should be floored")
        XCTAssertEqual(alignedRect.origin.y, 20, "Origin Y should be floored")
        XCTAssertEqual(alignedRect.size.width, 101, "Width should be ceiled")
        XCTAssertEqual(alignedRect.size.height, 201, "Height should be ceiled")
    }
    
    // MARK: - Display Info Tests
    
    func testGetAllDisplayInfos() {
        let displayInfos = hiDPIManager.getAllDisplayInfos()
        
        XCTAssertGreaterThan(displayInfos.count, 0, "Should have at least one display")
        
        let mainDisplay = displayInfos.first { $0.isMain }
        XCTAssertNotNil(mainDisplay, "Should have a main display")
    }
    
    func testNonIntegerScalingSupport() {
        let supportsNonInteger = hiDPIManager.supportsNonIntegerScaling()
        // This test just ensures the method works, result depends on hardware
        XCTAssertNotNil(supportsNonInteger, "Should return a boolean value")
    }
    
    func testRecommendedLineWidth() {
        let lineWidth = hiDPIManager.getRecommendedLineWidth()
        
        XCTAssertGreaterThan(lineWidth, 0, "Line width should be positive")
        XCTAssertLessThanOrEqual(lineWidth, 1.0, "Line width should not exceed 1.0")
    }
    
    // MARK: - Extension Tests
    
    func testCGPointExtensions() {
        let point = CGPoint(x: 100, y: 200)
        let scaleFactor: CGFloat = 2.0
        
        let scaledPoint = point.scaledForHiDPI(factor: scaleFactor)
        XCTAssertEqual(scaledPoint.x, 200, "Extension should scale X coordinate")
        XCTAssertEqual(scaledPoint.y, 400, "Extension should scale Y coordinate")
        
        let unscaledPoint = scaledPoint.unscaledForHiDPI(factor: scaleFactor)
        XCTAssertEqual(unscaledPoint.x, 100, "Extension should unscale X coordinate")
        XCTAssertEqual(unscaledPoint.y, 200, "Extension should unscale Y coordinate")
        
        let alignedPoint = CGPoint(x: 100.7, y: 200.3).pixelAligned(factor: 1.0)
        XCTAssertEqual(alignedPoint.x, 101, "Extension should align X coordinate")
        XCTAssertEqual(alignedPoint.y, 200, "Extension should align Y coordinate")
    }
    
    func testCGSizeExtensions() {
        let size = CGSize(width: 100, height: 200)
        let scaleFactor: CGFloat = 2.0
        
        let scaledSize = size.scaledForHiDPI(factor: scaleFactor)
        XCTAssertEqual(scaledSize.width, 200, "Extension should scale width")
        XCTAssertEqual(scaledSize.height, 400, "Extension should scale height")
        
        let unscaledSize = scaledSize.unscaledForHiDPI(factor: scaleFactor)
        XCTAssertEqual(unscaledSize.width, 100, "Extension should unscale width")
        XCTAssertEqual(unscaledSize.height, 200, "Extension should unscale height")
    }
    
    func testCGRectExtensions() {
        let rect = CGRect(x: 10, y: 20, width: 100, height: 200)
        let scaleFactor: CGFloat = 2.0
        
        let scaledRect = rect.scaledForHiDPI(factor: scaleFactor)
        XCTAssertEqual(scaledRect.origin.x, 20, "Extension should scale origin X")
        XCTAssertEqual(scaledRect.origin.y, 40, "Extension should scale origin Y")
        XCTAssertEqual(scaledRect.size.width, 200, "Extension should scale width")
        XCTAssertEqual(scaledRect.size.height, 400, "Extension should scale height")
        
        let unscaledRect = scaledRect.unscaledForHiDPI(factor: scaleFactor)
        XCTAssertEqual(unscaledRect.origin.x, 10, "Extension should unscale origin X")
        XCTAssertEqual(unscaledRect.origin.y, 20, "Extension should unscale origin Y")
        XCTAssertEqual(unscaledRect.size.width, 100, "Extension should unscale width")
        XCTAssertEqual(unscaledRect.size.height, 200, "Extension should unscale height")
        
        let alignedRect = CGRect(x: 10.3, y: 20.7, width: 100.4, height: 200.8).pixelAligned(factor: 1.0)
        XCTAssertEqual(alignedRect.origin.x, 10, "Extension should align origin X")
        XCTAssertEqual(alignedRect.origin.y, 20, "Extension should align origin Y")
        XCTAssertEqual(alignedRect.size.width, 101, "Extension should align width")
        XCTAssertEqual(alignedRect.size.height, 201, "Extension should align height")
    }
    
    // MARK: - Edge Cases
    
    func testZeroScaleFactor() {
        let point = CGPoint(x: 100, y: 200)
        let scaleFactor: CGFloat = 0.0
        
        let result = hiDPIManager.removeHiDPIScaling(from: point, scaleFactor: scaleFactor)
        XCTAssertEqual(result, point, "Should return original point when scale factor is zero")
    }
    
    func testNegativeScaleFactor() {
        let point = CGPoint(x: 100, y: 200)
        let scaleFactor: CGFloat = -1.0
        
        let scaledPoint = hiDPIManager.applyHiDPIScaling(to: point, scaleFactor: scaleFactor)
        XCTAssertEqual(scaledPoint.x, -100, "Should handle negative scale factor")
        XCTAssertEqual(scaledPoint.y, -200, "Should handle negative scale factor")
    }
}
