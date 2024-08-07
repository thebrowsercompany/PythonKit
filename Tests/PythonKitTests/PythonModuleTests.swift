import XCTest
@testable import PythonKit

class PythonModuleTests: XCTestCase {
    func testPythonModule() {
        let module = PythonModule()
        XCTAssertNotNil(module.pythonObject)

        PythonAwaitableFunction.ensurePythonAwaitableType(in: module)
    }
}
