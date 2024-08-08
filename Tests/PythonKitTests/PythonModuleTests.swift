import XCTest
@testable import PythonKit

class PythonModuleTests: XCTestCase {
    func testPythonModule() {
        let pythonKit = Python.import("pythonkit")
        XCTAssertNotNil(pythonKit)
    }

    func testAwaitablePythonFunction() throws {
        let pythonKit = Python.import("pythonkit")
        let awaitable = pythonKit.Awaitable()
        XCTAssertNotNil(awaitable)
    }
}
