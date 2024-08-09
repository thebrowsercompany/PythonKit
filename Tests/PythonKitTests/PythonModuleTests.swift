import XCTest
@testable import PythonKit

class PythonModuleTests: XCTestCase {
    func testPythonModule() {
        let pythonKit = Python.import("pythonkit")
        XCTAssertNotNil(pythonKit)
    }

    func testAwaitable() throws {
        // Verify we can call Swift methods from Python.
        let awaitable = Python.import("pythonkit").Awaitable()
        XCTAssertEqual(awaitable.magic(), 0x08675309)

        // Verify we can convert to the native Swift type.
        let pkAwaitable = PythonKitAwaitable(awaitable)!
        XCTAssertNotNil(pkAwaitable)
        XCTAssertEqual(pkAwaitable.aw_magic, 0x08675309)
    }
}
