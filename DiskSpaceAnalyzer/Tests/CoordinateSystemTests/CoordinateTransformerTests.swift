import XCTest
@testable import Core

class CoordinateTransformerTests: XCTestCase {
    
    var transformer: CoordinateTransformer!
    
    override func setUp() {
        super.setUp()
        transformer = CoordinateTransformer()
    }
    
    override func tearDown() {
        transformer = nil
        super.tearDown()
    }
    
    // MARK: - Basic Transform Tests
    
    func testSameSpaceTransform() {
        let point = CGPoint(x: 100, y: 200)
        let result = transformer.transform(point: point, from: .screen, to: .screen)
        
        XCTAssertEqual(result.point, point, "Same space transform should return original point")
        XCTAssertEqual(result.space, .screen, "Result space should match target space")
        XCTAssertEqual(result.accuracy, 1.0, accuracy: 0.001, "Same space transform should have perfect accuracy")
    }
    
    func testTransformAccuracy() {
        let point = CGPoint(x: 100.5, y: 200.7)
        let result = transformer.transform(point: point, from: .screen, to: .canvas)
        
        XCTAssertGreaterThan(result.accuracy, 0.9, "Transform accuracy should be high")
        XCTAssertLessThanOrEqual(result.accuracy, 1.0, "Transform accuracy should not exceed 1.0")
    }
    
    func testBatchTransform() {
        let points = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: 100, y: 100),
            CGPoint(x: 200, y: 300)
        ]
        
        let results = transformer.transformBatch(points: points, from: .screen, to: .window)
        
        XCTAssertEqual(results.count, points.count, "Batch transform should return same number of results")
        
        for (index, result) in results.enumerated() {
            XCTAssertEqual(result.space, .window, "All results should have target space")
            XCTAssertGreaterThan(result.accuracy, 0.9, "All results should have high accuracy")
        }
    }
    
    // MARK: - Cache Tests
    
    func testCachePerformance() {
        let point = CGPoint(x: 100, y: 200)
        
        // 清除缓存
        transformer.clearCache()
        
        // 第一次变换（应该缓存未命中）
        let startTime1 = CFAbsoluteTimeGetCurrent()
        _ = transformer.transform(point: point, from: .screen, to: .window)
        let duration1 = CFAbsoluteTimeGetCurrent() - startTime1
        
        // 第二次相同变换（应该缓存命中）
        let startTime2 = CFAbsoluteTimeGetCurrent()
        _ = transformer.transform(point: point, from: .screen, to: .window)
        let duration2 = CFAbsoluteTimeGetCurrent() - startTime2
        
        let stats = transformer.getCacheStats()
        XCTAssertGreaterThan(stats.hits, 0, "Should have cache hits")
        XCTAssertGreaterThan(stats.hitRate, 0, "Should have positive hit rate")
    }
    
    func testCacheStats() {
        transformer.clearCache()
        
        let initialStats = transformer.getCacheStats()
        XCTAssertEqual(initialStats.hits, 0, "Initial cache hits should be 0")
        XCTAssertEqual(initialStats.misses, 0, "Initial cache misses should be 0")
        XCTAssertEqual(initialStats.hitRate, 0, "Initial hit rate should be 0")
        
        // 执行一些变换
        let point = CGPoint(x: 100, y: 200)
        _ = transformer.transform(point: point, from: .screen, to: .window)
        _ = transformer.transform(point: point, from: .screen, to: .window)  // 应该命中缓存
        
        let finalStats = transformer.getCacheStats()
        XCTAssertGreaterThan(finalStats.hits + finalStats.misses, 0, "Should have some cache activity")
    }
    
    // MARK: - Precision Tests
    
    func testSubPixelPrecision() {
        let point = CGPoint(x: 100.123456789, y: 200.987654321)
        let precisePoint = point.withSubPixelPrecision()
        
        XCTAssertEqual(precisePoint.x, Double(point.x), accuracy: 0.0000001, "Should maintain sub-pixel precision")
        XCTAssertEqual(precisePoint.y, Double(point.y), accuracy: 0.0000001, "Should maintain sub-pixel precision")
    }
    
    func testPixelAlignment() {
        let point = CGPoint(x: 100.7, y: 200.3)
        let alignedPoint = point.pixelAligned()
        
        XCTAssertEqual(alignedPoint.x, 101, "Should round to nearest pixel")
        XCTAssertEqual(alignedPoint.y, 200, "Should round to nearest pixel")
    }
    
    // MARK: - Performance Tests
    
    func testTransformPerformance() {
        let points = (0..<1000).map { i in
            CGPoint(x: CGFloat(i), y: CGFloat(i * 2))
        }
        
        measure {
            for point in points {
                _ = transformer.transform(point: point, from: .screen, to: .canvas)
            }
        }
    }
    
    func testBatchTransformPerformance() {
        let points = (0..<1000).map { i in
            CGPoint(x: CGFloat(i), y: CGFloat(i * 2))
        }
        
        measure {
            _ = transformer.transformBatch(points: points, from: .screen, to: .canvas)
        }
    }
    
    // MARK: - Edge Cases
    
    func testZeroPoint() {
        let zeroPoint = CGPoint.zero
        let result = transformer.transform(point: zeroPoint, from: .screen, to: .window)
        
        XCTAssertNotNil(result, "Should handle zero point")
        XCTAssertEqual(result.space, .window, "Should have correct target space")
    }
    
    func testNegativeCoordinates() {
        let negativePoint = CGPoint(x: -100, y: -200)
        let result = transformer.transform(point: negativePoint, from: .screen, to: .container)
        
        XCTAssertNotNil(result, "Should handle negative coordinates")
        XCTAssertEqual(result.space, .container, "Should have correct target space")
    }
    
    func testLargeCoordinates() {
        let largePoint = CGPoint(x: 10000, y: 20000)
        let result = transformer.transform(point: largePoint, from: .window, to: .canvas)
        
        XCTAssertNotNil(result, "Should handle large coordinates")
        XCTAssertEqual(result.space, .canvas, "Should have correct target space")
    }
}
