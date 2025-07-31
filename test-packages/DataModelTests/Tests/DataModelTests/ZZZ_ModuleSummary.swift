import XCTest
@testable import DataModel
@testable import Common

final class ZZZ_ModuleSummary: BaseTestCase {
    
    func testZZZ_PrintModuleSummary() throws {
        let summary = ModuleTestSummary.generateSummary(moduleName: "DataModel")
        ModuleTestSummary.printSummary(summary)
    }
}
