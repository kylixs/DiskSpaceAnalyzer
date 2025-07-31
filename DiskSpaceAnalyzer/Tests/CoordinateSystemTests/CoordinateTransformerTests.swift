import XCTest
@testable import CoordinateSystem
@testable import Common

final class CoordinateTransformerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var transformer: CoordinateTransformer!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        transformer = CoordinateTransformer()
    }
    
    override func tearDownWithError() throws {
        transformer = nil
    }
    
    // MARK: - Initialization Tests
    
    func testCoordinateTransformerInitialization() throws {
        XCTAssertNotNil(transformer)
        XCTAssertEqual(transformer.currentScale, 1.0, accuracy: 0.001)
        XCTAssertEqual(transformer.currentOffset, Point.zero)
        XCTAssertTrue(transformer.transformationStack.isEmpty)
    }
    
    // MARK: - Basic Transformation Tests
    
    func testTranslation() throws {
        let originalPoint = Point(x: 100, y: 200)
        let offset = Point(x: 50, y: 75)
        
        transformer.translate(by: offset)
        let transformedPoint = transformer.transform(point: originalPoint)
        
        XCTAssertEqual(transformedPoint.x, 150, accuracy: 0.001)
        XCTAssertEqual(transformedPoint.y, 275, accuracy: 0.001)
    }
    
    func testScaling() throws {
        let originalPoint = Point(x: 100, y: 200)
        let scale = 2.0
        
        transformer.scale(by: scale)
        let transformedPoint = transformer.transform(point: originalPoint)
        
        XCTAssertEqual(transformedPoint.x, 200, accuracy: 0.001)
        XCTAssertEqual(transformedPoint.y, 400, accuracy: 0.001)
    }
    
    func testScalingAroundPoint() throws {
        let originalPoint = Point(x: 100, y: 100)
        let centerPoint = Point(x: 50, y: 50)
        let scale = 2.0
        
        transformer.scale(by: scale, around: centerPoint)
        let transformedPoint = transformer.transform(point: originalPoint)
        
        // 点(100,100)围绕(50,50)缩放2倍应该变成(150,150)
        XCTAssertEqual(transformedPoint.x, 150, accuracy: 0.001)
        XCTAssertEqual(transformedPoint.y, 150, accuracy: 0.001)
    }
    
    func testCombinedTransformations() throws {
        let originalPoint = Point(x: 100, y: 200)
        
        // 先缩放2倍，再平移(50, 75)
        transformer.scale(by: 2.0)
        transformer.translate(by: Point(x: 50, y: 75))
        
        let transformedPoint = transformer.transform(point: originalPoint)
        
        XCTAssertEqual(transformedPoint.x, 250, accuracy: 0.001) // (100*2)+50
        XCTAssertEqual(transformedPoint.y, 475, accuracy: 0.001) // (200*2)+75
    }
    
    // MARK: - Rectangle Transformation Tests
    
    func testRectangleTransformation() throws {
        let originalRect = Rect(x: 10, y: 20, width: 100, height: 200)
        
        transformer.scale(by: 2.0)
        transformer.translate(by: Point(x: 50, y: 75))
        
        let transformedRect = transformer.transform(rect: originalRect)
        
        XCTAssertEqual(transformedRect.x, 70, accuracy: 0.001)    // (10*2)+50
        XCTAssertEqual(transformedRect.y, 115, accuracy: 0.001)   // (20*2)+75
        XCTAssertEqual(transformedRect.width, 200, accuracy: 0.001)  // 100*2
        XCTAssertEqual(transformedRect.height, 400, accuracy: 0.001) // 200*2
    }
    
    // MARK: - Inverse Transformation Tests
    
    func testInverseTransformation() throws {
        let originalPoint = Point(x: 100, y: 200)
        
        transformer.scale(by: 2.0)
        transformer.translate(by: Point(x: 50, y: 75))
        
        let transformedPoint = transformer.transform(point: originalPoint)
        let inversePoint = transformer.inverseTransform(point: transformedPoint)
        
        XCTAssertEqual(inversePoint.x, originalPoint.x, accuracy: 0.001)
        XCTAssertEqual(inversePoint.y, originalPoint.y, accuracy: 0.001)
    }
    
    func testInverseRectangleTransformation() throws {
        let originalRect = Rect(x: 10, y: 20, width: 100, height: 200)
        
        transformer.scale(by: 1.5)
        transformer.translate(by: Point(x: 25, y: 35))
        
        let transformedRect = transformer.transform(rect: originalRect)
        let inverseRect = transformer.inverseTransform(rect: transformedRect)
        
        XCTAssertEqual(inverseRect.x, originalRect.x, accuracy: 0.001)
        XCTAssertEqual(inverseRect.y, originalRect.y, accuracy: 0.001)
        XCTAssertEqual(inverseRect.width, originalRect.width, accuracy: 0.001)
        XCTAssertEqual(inverseRect.height, originalRect.height, accuracy: 0.001)
    }
    
    // MARK: - Transformation Stack Tests
    
    func testPushPopTransformation() throws {
        let originalPoint = Point(x: 100, y: 200)
        
        // 初始变换
        transformer.scale(by: 2.0)
        let firstTransform = transformer.transform(point: originalPoint)
        
        // 保存当前状态并应用新变换
        transformer.pushTransformation()
        transformer.translate(by: Point(x: 50, y: 75))
        let secondTransform = transformer.transform(point: originalPoint)
        
        // 恢复之前的状态
        transformer.popTransformation()
        let restoredTransform = transformer.transform(point: originalPoint)
        
        XCTAssertEqual(firstTransform.x, restoredTransform.x, accuracy: 0.001)
        XCTAssertEqual(firstTransform.y, restoredTransform.y, accuracy: 0.001)
        XCTAssertNotEqual(secondTransform.x, restoredTransform.x, accuracy: 0.001)
    }
    
    func testNestedTransformationStack() throws {
        let originalPoint = Point(x: 100, y: 100)
        
        // 第一层变换
        transformer.scale(by: 2.0)
        transformer.pushTransformation()
        
        // 第二层变换
        transformer.translate(by: Point(x: 50, y: 50))
        transformer.pushTransformation()
        
        // 第三层变换
        transformer.scale(by: 0.5)
        let deepTransform = transformer.transform(point: originalPoint)
        
        // 逐层恢复
        transformer.popTransformation() // 恢复到第二层
        let secondLayerTransform = transformer.transform(point: originalPoint)
        
        transformer.popTransformation() // 恢复到第一层
        let firstLayerTransform = transformer.transform(point: originalPoint)
        
        XCTAssertNotEqual(deepTransform.x, secondLayerTransform.x, accuracy: 0.001)
        XCTAssertNotEqual(secondLayerTransform.x, firstLayerTransform.x, accuracy: 0.001)
        XCTAssertEqual(firstLayerTransform.x, 200, accuracy: 0.001) // 只有2倍缩放
    }
    
    // MARK: - Reset Tests
    
    func testResetTransformation() throws {
        let originalPoint = Point(x: 100, y: 200)
        
        // 应用多个变换
        transformer.scale(by: 2.0)
        transformer.translate(by: Point(x: 50, y: 75))
        transformer.pushTransformation()
        transformer.scale(by: 0.5)
        
        // 重置所有变换
        transformer.reset()
        
        let transformedPoint = transformer.transform(point: originalPoint)
        
        XCTAssertEqual(transformedPoint.x, originalPoint.x, accuracy: 0.001)
        XCTAssertEqual(transformedPoint.y, originalPoint.y, accuracy: 0.001)
        XCTAssertEqual(transformer.currentScale, 1.0, accuracy: 0.001)
        XCTAssertEqual(transformer.currentOffset, Point.zero)
        XCTAssertTrue(transformer.transformationStack.isEmpty)
    }
    
    // MARK: - Bounds Transformation Tests
    
    func testTransformBounds() throws {
        let bounds = Rect(x: 0, y: 0, width: 1000, height: 800)
        
        transformer.scale(by: 0.5)
        transformer.translate(by: Point(x: 100, y: 100))
        
        let transformedBounds = transformer.transformBounds(bounds)
        
        XCTAssertEqual(transformedBounds.x, 100, accuracy: 0.001)
        XCTAssertEqual(transformedBounds.y, 100, accuracy: 0.001)
        XCTAssertEqual(transformedBounds.width, 500, accuracy: 0.001)
        XCTAssertEqual(transformedBounds.height, 400, accuracy: 0.001)
    }
    
    func testFitToRect() throws {
        let sourceRect = Rect(x: 0, y: 0, width: 200, height: 100)
        let targetRect = Rect(x: 50, y: 50, width: 400, height: 300)
        
        transformer.fitToRect(source: sourceRect, target: targetRect, maintainAspectRatio: true)
        
        let transformedRect = transformer.transform(rect: sourceRect)
        
        // 应该保持宽高比，所以会按较小的缩放因子缩放
        XCTAssertTrue(transformedRect.width <= targetRect.width)
        XCTAssertTrue(transformedRect.height <= targetRect.height)
        
        // 应该居中
        let centerX = transformedRect.x + transformedRect.width / 2
        let centerY = transformedRect.y + transformedRect.height / 2
        let targetCenterX = targetRect.x + targetRect.width / 2
        let targetCenterY = targetRect.y + targetRect.height / 2
        
        XCTAssertEqual(centerX, targetCenterX, accuracy: 1.0)
        XCTAssertEqual(centerY, targetCenterY, accuracy: 1.0)
    }
    
    // MARK: - Caching Tests
    
    func testTransformationCaching() throws {
        let point = Point(x: 100, y: 200)
        
        transformer.scale(by: 2.0)
        transformer.translate(by: Point(x: 50, y: 75))
        
        // 第一次变换应该计算并缓存
        let transform1 = transformer.transform(point: point)
        
        // 第二次变换应该使用缓存
        let transform2 = transformer.transform(point: point)
        
        XCTAssertEqual(transform1.x, transform2.x, accuracy: 0.001)
        XCTAssertEqual(transform1.y, transform2.y, accuracy: 0.001)
    }
    
    func testCacheInvalidation() throws {
        let point = Point(x: 100, y: 200)
        
        transformer.scale(by: 2.0)
        let transform1 = transformer.transform(point: point)
        
        // 修改变换应该使缓存失效
        transformer.translate(by: Point(x: 50, y: 75))
        let transform2 = transformer.transform(point: point)
        
        XCTAssertNotEqual(transform1.x, transform2.x, accuracy: 0.001)
        XCTAssertNotEqual(transform1.y, transform2.y, accuracy: 0.001)
    }
    
    // MARK: - Edge Cases Tests
    
    func testZeroScale() throws {
        let point = Point(x: 100, y: 200)
        
        transformer.scale(by: 0.0)
        let transformedPoint = transformer.transform(point: point)
        
        XCTAssertEqual(transformedPoint.x, 0, accuracy: 0.001)
        XCTAssertEqual(transformedPoint.y, 0, accuracy: 0.001)
    }
    
    func testNegativeScale() throws {
        let point = Point(x: 100, y: 200)
        
        transformer.scale(by: -1.0)
        let transformedPoint = transformer.transform(point: point)
        
        XCTAssertEqual(transformedPoint.x, -100, accuracy: 0.001)
        XCTAssertEqual(transformedPoint.y, -200, accuracy: 0.001)
    }
    
    func testVeryLargeTransformation() throws {
        let point = Point(x: 1, y: 1)
        
        transformer.scale(by: 1000000.0)
        let transformedPoint = transformer.transform(point: point)
        
        XCTAssertEqual(transformedPoint.x, 1000000.0, accuracy: 0.001)
        XCTAssertEqual(transformedPoint.y, 1000000.0, accuracy: 0.001)
    }
    
    func testVerySmallTransformation() throws {
        let point = Point(x: 1000000, y: 1000000)
        
        transformer.scale(by: 0.000001)
        let transformedPoint = transformer.transform(point: point)
        
        XCTAssertEqual(transformedPoint.x, 1.0, accuracy: 0.001)
        XCTAssertEqual(transformedPoint.y, 1.0, accuracy: 0.001)
    }
    
    // MARK: - Performance Tests
    
    func testTransformationPerformance() throws {
        let points = (0..<10000).map { Point(x: Double($0), y: Double($0 * 2)) }
        
        transformer.scale(by: 1.5)
        transformer.translate(by: Point(x: 100, y: 200))
        
        measure {
            for point in points {
                _ = transformer.transform(point: point)
            }
        }
    }
    
    func testStackOperationPerformance() throws {
        measure {
            for _ in 0..<1000 {
                transformer.pushTransformation()
                transformer.scale(by: 1.1)
                transformer.translate(by: Point(x: 1, y: 1))
                transformer.popTransformation()
            }
        }
    }
    
    // MARK: - Matrix Operations Tests
    
    func testTransformationMatrix() throws {
        transformer.scale(by: 2.0)
        transformer.translate(by: Point(x: 50, y: 75))
        
        let matrix = transformer.transformationMatrix
        
        // 验证矩阵元素
        XCTAssertEqual(matrix.a, 2.0, accuracy: 0.001)  // x缩放
        XCTAssertEqual(matrix.d, 2.0, accuracy: 0.001)  // y缩放
        XCTAssertEqual(matrix.tx, 50, accuracy: 0.001)  // x平移
        XCTAssertEqual(matrix.ty, 75, accuracy: 0.001)  // y平移
    }
    
    func testSetTransformationMatrix() throws {
        let matrix = CGAffineTransform(scaleX: 1.5, y: 1.5).translatedBy(x: 25, y: 35)
        
        transformer.setTransformationMatrix(matrix)
        
        let point = Point(x: 100, y: 200)
        let transformedPoint = transformer.transform(point: point)
        
        XCTAssertEqual(transformedPoint.x, 175, accuracy: 0.001) // (100*1.5)+25
        XCTAssertEqual(transformedPoint.y, 335, accuracy: 0.001) // (200*1.5)+35
    }
}
