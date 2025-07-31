import XCTest
@testable import Common

final class SharedUtilitiesTests: XCTestCase {
    
    // MARK: - File Size Formatting Tests
    
    func testFormatFileSize() throws {
        // 测试字节格式化
        XCTAssertEqual(SharedUtilities.formatFileSize(0), "0 bytes")
        XCTAssertEqual(SharedUtilities.formatFileSize(1), "1 byte")
        XCTAssertEqual(SharedUtilities.formatFileSize(512), "512 bytes")
        XCTAssertEqual(SharedUtilities.formatFileSize(1024), "1.0 KB")
        XCTAssertEqual(SharedUtilities.formatFileSize(1536), "1.5 KB")
        XCTAssertEqual(SharedUtilities.formatFileSize(1048576), "1.0 MB")
        XCTAssertEqual(SharedUtilities.formatFileSize(1073741824), "1.0 GB")
        XCTAssertEqual(SharedUtilities.formatFileSize(1099511627776), "1.0 TB")
    }
    
    func testFormatFileSizeWithPrecision() throws {
        // 测试指定精度的格式化
        let size = 1536 // 1.5 KB
        XCTAssertEqual(SharedUtilities.formatFileSize(size, precision: 0), "2 KB")
        XCTAssertEqual(SharedUtilities.formatFileSize(size, precision: 1), "1.5 KB")
        XCTAssertEqual(SharedUtilities.formatFileSize(size, precision: 2), "1.50 KB")
    }
    
    func testFormatFileSizeEdgeCases() throws {
        // 测试边界情况
        XCTAssertEqual(SharedUtilities.formatFileSize(-1), "0 bytes")
        XCTAssertEqual(SharedUtilities.formatFileSize(Int64.max), "8.0 EB")
    }
    
    // MARK: - Path Validation Tests
    
    func testIsValidPath() throws {
        // 测试有效路径
        XCTAssertTrue(SharedUtilities.isValidPath("/"))
        XCTAssertTrue(SharedUtilities.isValidPath("/Users"))
        XCTAssertTrue(SharedUtilities.isValidPath("/Users/test/Documents"))
        XCTAssertTrue(SharedUtilities.isValidPath("~/Documents"))
        XCTAssertTrue(SharedUtilities.isValidPath("./relative/path"))
        
        // 测试无效路径
        XCTAssertFalse(SharedUtilities.isValidPath(""))
        XCTAssertFalse(SharedUtilities.isValidPath("   "))
        XCTAssertFalse(SharedUtilities.isValidPath("\0"))
        XCTAssertFalse(SharedUtilities.isValidPath("path\nwith\nnewlines"))
    }
    
    func testNormalizePath() throws {
        // 测试路径标准化
        XCTAssertEqual(SharedUtilities.normalizePath("~/Documents"), NSHomeDirectory() + "/Documents")
        XCTAssertEqual(SharedUtilities.normalizePath("/Users//test///file.txt"), "/Users/test/file.txt")
        XCTAssertEqual(SharedUtilities.normalizePath("/Users/test/./file.txt"), "/Users/test/file.txt")
        XCTAssertEqual(SharedUtilities.normalizePath("/Users/test/../file.txt"), "/Users/file.txt")
    }
    
    func testGetParentPath() throws {
        // 测试获取父路径
        XCTAssertEqual(SharedUtilities.getParentPath("/Users/test/file.txt"), "/Users/test")
        XCTAssertEqual(SharedUtilities.getParentPath("/Users/test/"), "/Users")
        XCTAssertEqual(SharedUtilities.getParentPath("/Users"), "/")
        XCTAssertEqual(SharedUtilities.getParentPath("/"), "/")
    }
    
    // MARK: - Timestamp Formatting Tests
    
    func testFormatTimestamp() throws {
        let date = Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
        let formatted = SharedUtilities.formatTimestamp(date)
        
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertTrue(formatted.contains("2022"))
    }
    
    func testFormatTimestampWithFormat() throws {
        let date = Date(timeIntervalSince1970: 1640995200)
        let formatted = SharedUtilities.formatTimestamp(date, format: "yyyy-MM-dd")
        
        XCTAssertEqual(formatted, "2022-01-01")
    }
    
    func testFormatDuration() throws {
        // 测试时长格式化
        XCTAssertEqual(SharedUtilities.formatDuration(0), "0s")
        XCTAssertEqual(SharedUtilities.formatDuration(30), "30s")
        XCTAssertEqual(SharedUtilities.formatDuration(90), "1m 30s")
        XCTAssertEqual(SharedUtilities.formatDuration(3661), "1h 1m 1s")
        XCTAssertEqual(SharedUtilities.formatDuration(86400), "1d 0h 0m 0s")
    }
    
    // MARK: - File Extension Tests
    
    func testGetFileExtension() throws {
        XCTAssertEqual(SharedUtilities.getFileExtension("file.txt"), "txt")
        XCTAssertEqual(SharedUtilities.getFileExtension("archive.tar.gz"), "gz")
        XCTAssertEqual(SharedUtilities.getFileExtension("README"), "")
        XCTAssertEqual(SharedUtilities.getFileExtension(".hidden"), "")
        XCTAssertEqual(SharedUtilities.getFileExtension("file."), "")
    }
    
    func testIsImageFile() throws {
        XCTAssertTrue(SharedUtilities.isImageFile("photo.jpg"))
        XCTAssertTrue(SharedUtilities.isImageFile("image.PNG"))
        XCTAssertTrue(SharedUtilities.isImageFile("graphic.svg"))
        XCTAssertFalse(SharedUtilities.isImageFile("document.txt"))
        XCTAssertFalse(SharedUtilities.isImageFile("video.mp4"))
    }
    
    func testIsVideoFile() throws {
        XCTAssertTrue(SharedUtilities.isVideoFile("movie.mp4"))
        XCTAssertTrue(SharedUtilities.isVideoFile("clip.MOV"))
        XCTAssertTrue(SharedUtilities.isVideoFile("video.avi"))
        XCTAssertFalse(SharedUtilities.isVideoFile("audio.mp3"))
        XCTAssertFalse(SharedUtilities.isVideoFile("image.jpg"))
    }
    
    func testIsAudioFile() throws {
        XCTAssertTrue(SharedUtilities.isAudioFile("song.mp3"))
        XCTAssertTrue(SharedUtilities.isAudioFile("track.WAV"))
        XCTAssertTrue(SharedUtilities.isAudioFile("audio.flac"))
        XCTAssertFalse(SharedUtilities.isAudioFile("video.mp4"))
        XCTAssertFalse(SharedUtilities.isAudioFile("document.pdf"))
    }
    
    // MARK: - Color Utilities Tests
    
    func testGenerateColorForPath() throws {
        let color1 = SharedUtilities.generateColorForPath("/Users/test")
        let color2 = SharedUtilities.generateColorForPath("/Users/test")
        let color3 = SharedUtilities.generateColorForPath("/Users/other")
        
        // 相同路径应该生成相同颜色
        XCTAssertEqual(color1, color2)
        
        // 不同路径应该生成不同颜色
        XCTAssertNotEqual(color1, color3)
    }
    
    func testGenerateColorForSize() throws {
        let smallColor = SharedUtilities.generateColorForSize(1024)      // 1KB
        let mediumColor = SharedUtilities.generateColorForSize(1048576)  // 1MB
        let largeColor = SharedUtilities.generateColorForSize(1073741824) // 1GB
        
        // 不同大小应该生成不同的颜色
        XCTAssertNotEqual(smallColor, mediumColor)
        XCTAssertNotEqual(mediumColor, largeColor)
        XCTAssertNotEqual(smallColor, largeColor)
    }
    
    // MARK: - Hash Utilities Tests
    
    func testCalculateHash() throws {
        let data1 = "Hello, World!".data(using: .utf8)!
        let data2 = "Hello, World!".data(using: .utf8)!
        let data3 = "Different data".data(using: .utf8)!
        
        let hash1 = SharedUtilities.calculateHash(data1)
        let hash2 = SharedUtilities.calculateHash(data2)
        let hash3 = SharedUtilities.calculateHash(data3)
        
        // 相同数据应该生成相同哈希
        XCTAssertEqual(hash1, hash2)
        
        // 不同数据应该生成不同哈希
        XCTAssertNotEqual(hash1, hash3)
        
        // 哈希长度应该固定
        XCTAssertEqual(hash1.count, 64) // SHA256 hex string
    }
    
    func testCalculateFileHash() throws {
        // 创建临时文件
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_hash.txt")
        let testData = "Test file content for hashing".data(using: .utf8)!
        
        try testData.write(to: testFile)
        
        // 计算文件哈希
        let hash = SharedUtilities.calculateFileHash(testFile.path)
        XCTAssertNotNil(hash)
        XCTAssertEqual(hash?.count, 64)
        
        // 清理
        try? FileManager.default.removeItem(at: testFile)
    }
    
    // MARK: - Performance Tests
    
    func testFormatFileSizePerformance() throws {
        measure {
            for i in 0..<10000 {
                _ = SharedUtilities.formatFileSize(Int64(i * 1024))
            }
        }
    }
    
    func testPathValidationPerformance() throws {
        let paths = (0..<1000).map { "/Users/test/path\($0)/file.txt" }
        
        measure {
            for path in paths {
                _ = SharedUtilities.isValidPath(path)
            }
        }
    }
}
