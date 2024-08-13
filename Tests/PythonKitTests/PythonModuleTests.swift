import XCTest
@testable import PythonKit

class PythonModuleTests: XCTestCase {
    func testPythonModule() {
        let pythonKit = Python.import("pythonkit")
        XCTAssertNotNil(pythonKit)
    }

    func testCanAwait() throws {
        _ = Python

        PythonModule.testAwaitableFunction =
            PythonFunction(name: "test_awaitable") { (_, _) async throws -> PythonConvertible in
                let result = 42
                return result
            }

        // TODO: Find a way to assert the result in Swift.
        PyRun_SimpleString("""
            import asyncio
            import inspect
            import pythonkit

            async def main():
                awaitable = pythonkit.test_awaitable()
                result = await awaitable()
                print(f"Python: result == {result}")
                assert result == 42

            asyncio.run(main())
            """)
    }
}
