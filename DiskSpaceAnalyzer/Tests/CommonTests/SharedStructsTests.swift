import XCTest
@testable import Common

final class SharedStructsTests: XCTestCase {
    
    // MARK: - Point Tests
    
    func testPointCreation() throws {
        let point = Point(x: 10.5, y: 20.3)
        XCTAssertEqual(point.x, 10.5, accuracy: 0.001)
        XCTAssertEqual(point.y, 20.3, accuracy: 0.001)
    }
    
    func testPointZero() throws {
        let zero = Point.zero
        XCTAssertEqual(zero.x, 0)
        XCTAssertEqual(zero.y, 0)
    }
    
    func testPointDistance() throws {
        let point1 = Point(x: 0, y: 0)
        let point2 = Point(x: 3, y: 4)
        
        let distance = point1.distance(to: point2)
        XCTAssertEqual(distance, 5.0, accuracy: 0.001) // 3-4-5 triangle
        
        // 测试距离自身
        XCTAssertEqual(point1.distance(to: point1), 0.0)
    }
    
    func testPointArithmetic() throws {
        let point1 = Point(x: 10, y: 20)
        let point2 = Point(x: 5, y: 15)
        
        // 加法
        let sum = point1 + point2
        XCTAssertEqual(sum.x, 15)
        XCTAssertEqual(sum.y, 35)
        
        // 减法
        let difference = point1 - point2
        XCTAssertEqual(difference.x, 5)
        XCTAssertEqual(difference.y, 5)
        
        // 标量乘法
        let scaled = point1 * 2.0
        XCTAssertEqual(scaled.x, 20)
        XCTAssertEqual(scaled.y, 40)
        
        // 标量除法
        let divided = point1 / 2.0
        XCTAssertEqual(divided.x, 5)
        XCTAssertEqual(divided.y, 10)
    }
    
    func testPointCGPointConversion() throws {
        let point = Point(x: 15.5, y: 25.7)
        let cgPoint = point.cgPoint
        
        XCTAssertEqual(cgPoint.x, 15.5, accuracy: 0.001)
        XCTAssertEqual(cgPoint.y, 25.7, accuracy: 0.001)
    }
    
    // MARK: - Size Tests
    
    func testSizeCreation() throws {
        let size = Size(width: 100, height: 200)
        XCTAssertEqual(size.width, 100)
        XCTAssertEqual(size.height, 200)
    }
    
    func testSizeZero() throws {
        let zero = Size.zero
        XCTAssertEqual(zero.width, 0)
        XCTAssertEqual(zero.height, 0)
    }
    
    func testSizeArea() throws {
        let size = Size(width: 10, height: 20)
        XCTAssertEqual(size.area, 200)
        
        let zeroSize = Size.zero
        XCTAssertEqual(zeroSize.area, 0)
    }
    
    func testSizeAspectRatio() throws {
        let size = Size(width: 16, height: 9)
        XCTAssertEqual(size.aspectRatio, 16.0/9.0, accuracy: 0.001)
        
        let squareSize = Size(width: 10, height: 10)
        XCTAssertEqual(squareSize.aspectRatio, 1.0)
        
        let zeroHeightSize = Size(width: 10, height: 0)
        XCTAssertTrue(zeroHeightSize.aspectRatio.isInfinite)
    }
    
    func testSizeScaling() throws {
        let size = Size(width: 10, height: 20)
        
        let scaled = size.scaled(by: 2.0)
        XCTAssertEqual(scaled.width, 20)
        XCTAssertEqual(scaled.height, 40)
        
        let scaledNonUniform = size.scaled(widthBy: 2.0, heightBy: 0.5)
        XCTAssertEqual(scaledNonUniform.width, 20)
        XCTAssertEqual(scaledNonUniform.height, 10)
    }
    
    func testSizeCGSizeConversion() throws {
        let size = Size(width: 150.5, height: 250.7)
        let cgSize = size.cgSize
        
        XCTAssertEqual(cgSize.width, 150.5, accuracy: 0.001)
        XCTAssertEqual(cgSize.height, 250.7, accuracy: 0.001)
    }
    
    // MARK: - Rect Tests
    
    func testRectCreation() throws {
        let rect = Rect(x: 10, y: 20, width: 100, height: 200)
        XCTAssertEqual(rect.origin.x, 10)
        XCTAssertEqual(rect.origin.y, 20)
        XCTAssertEqual(rect.size.width, 100)
        XCTAssertEqual(rect.size.height, 200)
    }
    
    func testRectFromOriginAndSize() throws {
        let origin = Point(x: 5, y: 10)
        let size = Size(width: 50, height: 100)
        let rect = Rect(origin: origin, size: size)
        
        XCTAssertEqual(rect.origin.x, 5)
        XCTAssertEqual(rect.origin.y, 10)
        XCTAssertEqual(rect.size.width, 50)
        XCTAssertEqual(rect.size.height, 100)
    }
    
    func testRectZero() throws {
        let zero = Rect.zero
        XCTAssertEqual(zero.origin, Point.zero)
        XCTAssertEqual(zero.size, Size.zero)
    }
    
    func testRectBounds() throws {
        let rect = Rect(x: 10, y: 20, width: 100, height: 200)
        
        XCTAssertEqual(rect.minX, 10)
        XCTAssertEqual(rect.minY, 20)
        XCTAssertEqual(rect.maxX, 110)
        XCTAssertEqual(rect.maxY, 220)
        XCTAssertEqual(rect.midX, 60)
        XCTAssertEqual(rect.midY, 120)
    }
    
    func testRectCenter() throws {
        let rect = Rect(x: 10, y: 20, width: 100, height: 200)
        let center = rect.center
        
        XCTAssertEqual(center.x, 60)
        XCTAssertEqual(center.y, 120)
    }
    
    func testRectArea() throws {
        let rect = Rect(x: 0, y: 0, width: 10, height: 20)
        XCTAssertEqual(rect.area, 200)
        
        let zeroRect = Rect.zero
        XCTAssertEqual(zeroRect.area, 0)
    }
    
    func testRectContainsPoint() throws {
        let rect = Rect(x: 10, y: 20, width: 100, height: 200)
        
        // 内部点
        XCTAssertTrue(rect.contains(Point(x: 50, y: 100)))
        XCTAssertTrue(rect.contains(Point(x: 60, y: 120))) // center
        
        // 边界点
        XCTAssertTrue(rect.contains(Point(x: 10, y: 20))) // min corner
        XCTAssertFalse(rect.contains(Point(x: 110, y: 220))) // max corner (exclusive)
        
        // 外部点
        XCTAssertFalse(rect.contains(Point(x: 5, y: 100)))
        XCTAssertFalse(rect.contains(Point(x: 50, y: 15)))
        XCTAssertFalse(rect.contains(Point(x: 150, y: 100)))
        XCTAssertFalse(rect.contains(Point(x: 50, y: 250)))
    }
    
    func testRectIntersection() throws {
        let rect1 = Rect(x: 0, y: 0, width: 100, height: 100)
        let rect2 = Rect(x: 50, y: 50, width: 100, height: 100)
        
        // 相交
        XCTAssertTrue(rect1.intersects(rect2))
        XCTAssertTrue(rect2.intersects(rect1))
        
        // 不相交
        let rect3 = Rect(x: 200, y: 200, width: 50, height: 50)
        XCTAssertFalse(rect1.intersects(rect3))
        XCTAssertFalse(rect3.intersects(rect1))
        
        // 相邻但不相交
        let rect4 = Rect(x: 100, y: 0, width: 50, height: 50)
        XCTAssertFalse(rect1.intersects(rect4))
    }
    
    func testRectUnion() throws {
        let rect1 = Rect(x: 0, y: 0, width: 50, height: 50)
        let rect2 = Rect(x: 25, y: 25, width: 50, height: 50)
        
        let union = rect1.union(rect2)
        
        XCTAssertEqual(union.minX, 0)
        XCTAssertEqual(union.minY, 0)
        XCTAssertEqual(union.maxX, 75)
        XCTAssertEqual(union.maxY, 75)
    }
    
    func testRectInset() throws {
        let rect = Rect(x: 10, y: 20, width: 100, height: 200)
        let inset = rect.insetBy(dx: 5, dy: 10)
        
        XCTAssertEqual(inset.x, 15)
        XCTAssertEqual(inset.y, 30)
        XCTAssertEqual(inset.width, 90)
        XCTAssertEqual(inset.height, 180)
    }
    
    func testRectOffset() throws {
        let rect = Rect(x: 10, y: 20, width: 100, height: 200)
        let offset = rect.offsetBy(dx: 5, dy: -10)
        
        XCTAssertEqual(offset.x, 15)
        XCTAssertEqual(offset.y, 10)
        XCTAssertEqual(offset.width, 100)
        XCTAssertEqual(offset.height, 200)
    }
    
    func testRectCGRectConversion() throws {
        let rect = Rect(x: 10.5, y: 20.7, width: 100.3, height: 200.9)
        let cgRect = rect.cgRect
        
        XCTAssertEqual(cgRect.origin.x, 10.5, accuracy: 0.001)
        XCTAssertEqual(cgRect.origin.y, 20.7, accuracy: 0.001)
        XCTAssertEqual(cgRect.size.width, 100.3, accuracy: 0.001)
        XCTAssertEqual(cgRect.size.height, 200.9, accuracy: 0.001)
    }
    
    // MARK: - ScanStatistics Tests
    
    func testScanStatisticsCreation() throws {
        let stats = ScanStatistics()
        
        XCTAssertEqual(stats.filesScanned, 0)
        XCTAssertEqual(stats.directoriesScanned, 0)
        XCTAssertEqual(stats.totalBytesScanned, 0)
        XCTAssertEqual(stats.scanDuration, 0)
        XCTAssertEqual(stats.errorCount, 0)
    }
    
    func testScanStatisticsUpdate() throws {
        var stats = ScanStatistics()
        
        stats.updateFileCount(10)
        stats.updateDirectoryCount(5)
        stats.updateBytesScanned(1024)
        stats.updateDuration(30.5)
        stats.incrementErrorCount()
        
        XCTAssertEqual(stats.filesScanned, 10)
        XCTAssertEqual(stats.directoriesScanned, 5)
        XCTAssertEqual(stats.totalBytesScanned, 1024)
        XCTAssertEqual(stats.scanDuration, 30.5, accuracy: 0.001)
        XCTAssertEqual(stats.errorCount, 1)
    }
    
    func testScanStatisticsReset() throws {
        var stats = ScanStatistics()
        stats.filesScanned = 100
        stats.directoriesScanned = 50
        stats.totalBytesScanned = 2048
        stats.scanDuration = 60.0
        stats.errorCount = 5
        
        stats.reset()
        
        XCTAssertEqual(stats.filesScanned, 0)
        XCTAssertEqual(stats.directoriesScanned, 0)
        XCTAssertEqual(stats.totalBytesScanned, 0)
        XCTAssertEqual(stats.scanDuration, 0)
        XCTAssertEqual(stats.errorCount, 0)
    }
    
    func testScanStatisticsCalculations() throws {
        var stats = ScanStatistics()
        stats.filesScanned = 100
        stats.directoriesScanned = 20
        stats.totalBytesScanned = 1024 * 1024 // 1MB
        stats.scanDuration = 10.0 // 10 seconds
        
        XCTAssertEqual(stats.totalItemsScanned, 120)
        XCTAssertEqual(stats.averageFileSize, 1024 * 1024 / 100)
        XCTAssertEqual(stats.scanSpeed, 12.0, accuracy: 0.001) // items per second
        XCTAssertEqual(stats.bytesPerSecond, 1024 * 1024 / 10, accuracy: 0.001)
    }
    
    // MARK: - ByteFormatter Tests
    
    func testByteFormatterSingleton() throws {
        let formatter1 = ByteFormatter.shared
        let formatter2 = ByteFormatter.shared
        
        XCTAssertTrue(formatter1 === formatter2, "ByteFormatter应该是单例")
    }
    
    func testByteFormatterStringFromBytes() throws {
        let formatter = ByteFormatter.shared
        
        XCTAssertEqual(formatter.string(fromBytes: 0), "0 bytes")
        XCTAssertEqual(formatter.string(fromBytes: 1), "1 byte")
        XCTAssertEqual(formatter.string(fromBytes: 512), "512 bytes")
        XCTAssertEqual(formatter.string(fromBytes: 1024), "1.0 KB")
        XCTAssertEqual(formatter.string(fromBytes: 1536), "1.5 KB")
        XCTAssertEqual(formatter.string(fromBytes: 1048576), "1.0 MB")
        XCTAssertEqual(formatter.string(fromBytes: 1073741824), "1.0 GB")
    }
    
    func testByteFormatterStringFromByteCount() throws {
        let formatter = ByteFormatter.shared
        
        // 测试与系统ByteCountFormatter的兼容性
        let result1 = formatter.string(fromByteCount: 1024)
        let result2 = formatter.string(fromByteCount: 1048576)
        
        XCTAssertFalse(result1.isEmpty)
        XCTAssertFalse(result2.isEmpty)
        XCTAssertTrue(result1.contains("KB") || result1.contains("kB"))
        XCTAssertTrue(result2.contains("MB"))
    }
    
    // MARK: - Performance Tests
    
    func testPointPerformance() throws {
        let points = (0..<10000).map { Point(x: Double($0), y: Double($0 * 2)) }
        
        measure {
            var totalDistance: Double = 0
            for i in 0..<points.count-1 {
                totalDistance += points[i].distance(to: points[i+1])
            }
        }
    }
    
    func testRectPerformance() throws {
        let rects = (0..<1000).map { Rect(x: Double($0), y: Double($0), width: 100, height: 100) }
        
        measure {
            var intersectionCount = 0
            for i in 0..<rects.count {
                for j in i+1..<rects.count {
                    if rects[i].intersects(rects[j]) {
                        intersectionCount += 1
                    }
                }
            }
        }
    }
}
