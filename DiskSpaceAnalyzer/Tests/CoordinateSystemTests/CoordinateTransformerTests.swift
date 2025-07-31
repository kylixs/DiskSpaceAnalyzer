import XCTest
import AppKit
@testable import CoordinateSystem
@testable import Common

final class CoordinateTransformerTests: BaseTestCase {
    
    var transformer: CoordinateTransformer!
    var testWindow: NSWindow!
    
    override func setUpWithError() throws {
        transformer = CoordinateTransformer.shared
        
        // 创建测试窗口
        testWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
    }
    
    override func tearDownWithError() throws {
        testWindow = nil
        transformer = nil
    }
    
    // MARK: - Basic Coordinate Transformation Tests
    
    func testScreenToWindowTransformation() throws {
        let screenPoint = CGPoint(x: 500, y: 400)
        let windowPoint = transformer.screenToWindow(screenPoint, in: testWindow)
        
        // 窗口位置在 (100, 100)，所以窗口坐标应该是屏幕坐标减去窗口原点
        XCTAssertEqual(windowPoint.x, 400, accuracy: 0.001) // 500 - 100
        XCTAssertEqual(windowPoint.y, 300, accuracy: 0.001) // 400 - 100
    }
    
    func testWindowToScreenTransformation() throws {
        let windowPoint = CGPoint(x: 200, y: 150)
        let screenPoint = transformer.windowToScreen(windowPoint, from: testWindow)
        
        // 屏幕坐标应该是窗口坐标加上窗口原点
        XCTAssertEqual(screenPoint.x, 300, accuracy: 0.001) // 200 + 100
        XCTAssertEqual(screenPoint.y, 250, accuracy: 0.001) // 150 + 100
    }
    
    func testWindowToContainerTransformation() throws {
        let windowPoint = CGPoint(x: 300, y: 250)
        let containerFrame = CGRect(x: 50, y: 50, width: 400, height: 300)
        
        let containerPoint = transformer.windowToContainer(windowPoint, containerFrame: containerFrame)
        
        XCTAssertEqual(containerPoint.x, 250, accuracy: 0.001) // 300 - 50
        XCTAssertEqual(containerPoint.y, 200, accuracy: 0.001) // 250 - 50
    }
    
    func testContainerToWindowTransformation() throws {
        let containerPoint = CGPoint(x: 150, y: 100)
        let containerFrame = CGRect(x: 50, y: 50, width: 400, height: 300)
        
        let windowPoint = transformer.containerToWindow(containerPoint, containerFrame: containerFrame)
        
        XCTAssertEqual(windowPoint.x, 200, accuracy: 0.001) // 150 + 50
        XCTAssertEqual(windowPoint.y, 150, accuracy: 0.001) // 100 + 50
    }
    
    func testContainerToCanvasTransformation() throws {
        let containerPoint = CGPoint(x: 100, y: 100)
        let canvasTransform = CGAffineTransform(scaleX: 2.0, y: 2.0).translatedBy(x: 50, y: 50)
        
        let canvasPoint = transformer.containerToCanvas(containerPoint, canvasTransform: canvasTransform)
        
        // 应用逆变换
        let expectedPoint = containerPoint.applying(canvasTransform.inverted())
        XCTAssertEqual(canvasPoint.x, expectedPoint.x, accuracy: 0.001)
        XCTAssertEqual(canvasPoint.y, expectedPoint.y, accuracy: 0.001)
    }
    
    func testCanvasToContainerTransformation() throws {
        let canvasPoint = CGPoint(x: 75, y: 75)
        let canvasTransform = CGAffineTransform(scaleX: 2.0, y: 2.0).translatedBy(x: 50, y: 50)
        
        let containerPoint = transformer.canvasToContainer(canvasPoint, canvasTransform: canvasTransform)
        
        // 应用变换
        let expectedPoint = canvasPoint.applying(canvasTransform)
        XCTAssertEqual(containerPoint.x, expectedPoint.x, accuracy: 0.001)
        XCTAssertEqual(containerPoint.y, expectedPoint.y, accuracy: 0.001)
    }
    
    // MARK: - Generic Transform Tests
    
    func testGenericTransform() throws {
        let point = CGPoint(x: 100, y: 200)
        let transform = CGAffineTransform(scaleX: 1.5, y: 1.5).translatedBy(x: 25, y: 35)
        
        let transformedPoint = transformer.transform(point, using: transform)
        let expectedPoint = point.applying(transform)
        
        XCTAssertEqual(transformedPoint.x, expectedPoint.x, accuracy: 0.001)
        XCTAssertEqual(transformedPoint.y, expectedPoint.y, accuracy: 0.001)
    }
    
    func testIdentityTransform() throws {
        let point = CGPoint(x: 100, y: 200)
        let identityTransform = CGAffineTransform.identity
        
        let transformedPoint = transformer.transform(point, using: identityTransform)
        
        XCTAssertEqual(transformedPoint.x, point.x, accuracy: 0.001)
        XCTAssertEqual(transformedPoint.y, point.y, accuracy: 0.001)
    }
    
    func testScaleTransform() throws {
        let point = CGPoint(x: 100, y: 200)
        let scaleTransform = CGAffineTransform(scaleX: 2.0, y: 3.0)
        
        let transformedPoint = transformer.transform(point, using: scaleTransform)
        
        XCTAssertEqual(transformedPoint.x, 200, accuracy: 0.001) // 100 * 2.0
        XCTAssertEqual(transformedPoint.y, 600, accuracy: 0.001) // 200 * 3.0
    }
    
    func testTranslationTransform() throws {
        let point = CGPoint(x: 100, y: 200)
        let translationTransform = CGAffineTransform(translationX: 50, y: 75)
        
        let transformedPoint = transformer.transform(point, using: translationTransform)
        
        XCTAssertEqual(transformedPoint.x, 150, accuracy: 0.001) // 100 + 50
        XCTAssertEqual(transformedPoint.y, 275, accuracy: 0.001) // 200 + 75
    }
    
    // MARK: - Composite Transform Tests
    
    func testCreateCompositeTransform() throws {
        let scaleTransform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        let translationTransform = CGAffineTransform(translationX: 50, y: 75)
        let rotationTransform = CGAffineTransform(rotationAngle: .pi / 4)
        
        let transforms = [scaleTransform, translationTransform, rotationTransform]
        let compositeTransform = transformer.createCompositeTransform(transforms)
        
        // 验证复合变换不是单位矩阵
        XCTAssertNotEqual(compositeTransform, CGAffineTransform.identity)
        
        // 验证复合变换的效果
        let point = CGPoint(x: 100, y: 100)
        let transformedPoint = transformer.transform(point, using: compositeTransform)
        
        // 手动应用变换序列
        let expectedPoint = point
            .applying(scaleTransform)
            .applying(translationTransform)
            .applying(rotationTransform)
        
        XCTAssertEqual(transformedPoint.x, expectedPoint.x, accuracy: 0.001)
        XCTAssertEqual(transformedPoint.y, expectedPoint.y, accuracy: 0.001)
    }
    
    func testEmptyCompositeTransform() throws {
        let emptyTransforms: [CGAffineTransform] = []
        let compositeTransform = transformer.createCompositeTransform(emptyTransforms)
        
        XCTAssertEqual(compositeTransform, CGAffineTransform.identity)
    }
    
    func testSingleCompositeTransform() throws {
        let singleTransform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        let compositeTransform = transformer.createCompositeTransform([singleTransform])
        
        XCTAssertEqual(compositeTransform, singleTransform)
    }
    
    // MARK: - Cache Tests
    
    func testTransformCache() throws {
        let cacheKey = "test_transform"
        let transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        
        // 初始时缓存应该为空
        XCTAssertNil(transformer.getCachedTransform(for: cacheKey))
        
        // 缓存变换
        transformer.cacheTransform(transform, for: cacheKey)
        
        // 验证缓存
        let cachedTransform = transformer.getCachedTransform(for: cacheKey)
        XCTAssertNotNil(cachedTransform)
        XCTAssertEqual(cachedTransform!, transform)
    }
    
    func testCacheInvalidation() throws {
        let cacheKey = "test_transform"
        let transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        
        // 缓存变换
        transformer.cacheTransform(transform, for: cacheKey)
        XCTAssertNotNil(transformer.getCachedTransform(for: cacheKey))
        
        // 清除缓存
        transformer.clearTransformCache()
        XCTAssertNil(transformer.getCachedTransform(for: cacheKey))
    }
    
    // MARK: - Coordinate System Chain Tests
    
    func testFullCoordinateChain() throws {
        // 测试完整的坐标变换链：屏幕 -> 窗口 -> 容器 -> 画布
        let screenPoint = CGPoint(x: 500, y: 400)
        let containerFrame = CGRect(x: 50, y: 50, width: 400, height: 300)
        let canvasTransform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        // 屏幕 -> 窗口
        let windowPoint = transformer.screenToWindow(screenPoint, in: testWindow)
        
        // 窗口 -> 容器
        let containerPoint = transformer.windowToContainer(windowPoint, containerFrame: containerFrame)
        
        // 容器 -> 画布
        let canvasPoint = transformer.containerToCanvas(containerPoint, canvasTransform: canvasTransform)
        
        // 验证反向变换
        let backToContainer = transformer.canvasToContainer(canvasPoint, canvasTransform: canvasTransform)
        let backToWindow = transformer.containerToWindow(backToContainer, containerFrame: containerFrame)
        let backToScreen = transformer.windowToScreen(backToWindow, from: testWindow)
        
        XCTAssertEqual(backToScreen.x, screenPoint.x, accuracy: 0.001)
        XCTAssertEqual(backToScreen.y, screenPoint.y, accuracy: 0.001)
    }
    
    // MARK: - Edge Cases Tests
    
    func testZeroSizeContainer() throws {
        let windowPoint = CGPoint(x: 100, y: 100)
        let zeroContainer = CGRect(x: 50, y: 50, width: 0, height: 0)
        
        let containerPoint = transformer.windowToContainer(windowPoint, containerFrame: zeroContainer)
        XCTAssertEqual(containerPoint.x, 50, accuracy: 0.001)
        XCTAssertEqual(containerPoint.y, 50, accuracy: 0.001)
    }
    
    func testNegativeCoordinates() throws {
        let negativePoint = CGPoint(x: -100, y: -200)
        let transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        
        let transformedPoint = transformer.transform(negativePoint, using: transform)
        
        XCTAssertEqual(transformedPoint.x, -200, accuracy: 0.001)
        XCTAssertEqual(transformedPoint.y, -400, accuracy: 0.001)
    }
    
    // MARK: - Performance Tests
    
    func testTransformPerformance() throws {
        let points = (0..<10000).map { CGPoint(x: Double($0), y: Double($0 * 2)) }
        let transform = CGAffineTransform(scaleX: 1.5, y: 1.5).translatedBy(x: 100, y: 200)
        
        measure {
            for point in points {
                _ = transformer.transform(point, using: transform)
            }
        }
    }
    
    func testCompositeTransformPerformance() throws {
        let transforms = [
            CGAffineTransform(scaleX: 1.1, y: 1.1),
            CGAffineTransform(translationX: 10, y: 10),
            CGAffineTransform(rotationAngle: 0.1)
        ]
        
        measure {
            for _ in 0..<1000 {
                _ = transformer.createCompositeTransform(transforms)
            }
        }
    }
}
