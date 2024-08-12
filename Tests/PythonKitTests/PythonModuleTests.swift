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

        // Verify methods we expect to be present are present.
        let methods = Python.dir(awaitable)
        XCTAssertFalse(methods.contains("_should_not_exist_")) // Sanity check.
        XCTAssertTrue(methods.contains("magic"))
        XCTAssertTrue(methods.contains("handle"))
        XCTAssertTrue(methods.contains("set_handle"))
        XCTAssertTrue(methods.contains("result"))
        XCTAssertTrue(methods.contains("set_result"))

        // Veryify __next__ is present.
        XCTAssertNotNil(awaitable.__next__)
    }

    func testAwaitableMethods() throws {
        let awaitable = Python.import("pythonkit").Awaitable()
        let index = PythonObject(1)
        awaitable.set_handle(index)
        XCTAssertEqual(awaitable.handle(), 1)

        let result = PythonObject("some result")
        awaitable.set_result(result)
        XCTAssertEqual(awaitable.result(), "some result")
    }
}
