import XCTest
@testable import PythonKit

class PythonModuleTests: XCTestCase {
    func testPythonModule() {
        let module = PythonModule()
        XCTAssertNotNil(module.pythonObject)

        let pythonKit = Python.import("pythonkit")
        XCTAssertNotNil(pythonKit)
    }

    func testAwaitablePythonFunction() throws {
        let _ = PythonAwaitableFunction()
        XCTAssertTrue(PythonAwaitableFunction.ready)

        let pythonKit = Python.import("pythonkit")
        let awaitable = pythonKit.Awaitable()
        XCTAssertNotNil(awaitable)
    }
}
