//===--PythonModule.swift -------------------------------------------------===//
// This file defines a custom extension module for PythonKit.
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Types from the CPython headers and related.
//===----------------------------------------------------------------------===//

typealias PyModuleDefPointer = UnsafeMutableRawPointer
typealias PyTypeObjectPointer = UnsafeMutableRawPointer

typealias allocfunc = @convention(c) (PyTypeObjectPointer, Int) -> PyObjectPointer?
typealias destructor = @convention(c) (PyObjectPointer) -> Void
typealias freefunc = @convention(c) (UnsafeMutableRawPointer) -> Void
typealias iternextfunc = @convention(c) (PyObjectPointer) -> PyObjectPointer?
typealias newfunc = @convention(c) (PyTypeObjectPointer, PyObjectPointer?, PyObjectPointer?) -> PyObjectPointer?
typealias sendfunc = @convention(c) (PyObjectPointer, PyObjectPointer, PyObjectPointer) -> Int
typealias unaryfunc = @convention(c) (PyObjectPointer) -> PyObjectPointer?

typealias PyCFunction = @convention(c) (PyObjectPointer, PyObjectPointer) -> PyObjectPointer?

// This will be 3 for the lifetime of Python 3. See PEP-384.
let Py_AbiVersion: Int = 3

// From the C headers (we're not stackless).
let Py_TPFlagsDefault: UInt64 = 0

// Our type is dynamically allocated.
let Py_TPFLAGS_HEAPTYPE: UInt64 = (1 << 9)

// The immortal value is the 32bit UInt.max value.
let Py_ImmortalRefCount: Int = Int(bitPattern: 0x00000000FFFFFFFF)

let METH_NOARGS: Int32 = 0x0004
let METH_O: Int32 = 0x0008

struct PyObject {
    var ob_refcnt: Int
    var ob_type: UnsafeMutablePointer<PyTypeObject>?
}

struct PyVarObject {
    var ob_base: PyObject
    var ob_size: Int
}

//===----------------------------------------------------------------------===//
// PythonModule Types.
//===----------------------------------------------------------------------===//

struct PyModuleDef_Base {
    var ob_base: PyObject
    var m_init: OpaquePointer?
    var m_index: Int
    var m_copy: OpaquePointer?
}

struct PyModuleDef_Slot {
    var slot: Int
    var value: OpaquePointer
}

struct PyModuleDef {
    var m_base: PyModuleDef_Base
    var m_name: UnsafePointer<Int8>
    var m_doc: UnsafePointer<Int8>?
    var m_size: Int
    var m_methods: UnsafePointer<PyMethodDef>?
    var m_slots: UnsafePointer<PyModuleDef_Slot>?
    var m_traverse: OpaquePointer?
    var m_clear: OpaquePointer?
    var m_free: OpaquePointer?
}

//===----------------------------------------------------------------------===//
// PythonType Types.
//===----------------------------------------------------------------------===//

struct PyAsyncMethods {
    var am_await: unaryfunc?
    var am_aiter: unaryfunc?
    var am_anext: unaryfunc?
    var am_send: sendfunc?
}

struct PyGetSetDef {
    var name: UnsafePointer<Int8>
    var get: OpaquePointer?
    var set: OpaquePointer?
    var doc: UnsafePointer<Int8>?
    var closure: OpaquePointer?
}

struct PyTypeObject {
    var ob_base: PyVarObject
    var tp_name: UnsafePointer<Int8>
    var tp_basicsize: Int
    var tp_itemsize: Int
    var tp_dealloc: destructor?
    var tp_vectorcall_offset: Int
    var tp_getattr: OpaquePointer?
    var tp_setattr: OpaquePointer?
    var tp_as_async: UnsafePointer<PyAsyncMethods>?
    var tp_repr: OpaquePointer?
    var tp_as_number: OpaquePointer?
    var tp_as_sequence: OpaquePointer?
    var tp_as_mapping: OpaquePointer?
    var tp_hash: OpaquePointer?
    var tp_call: OpaquePointer?
    var tp_str: OpaquePointer?
    var tp_getattro: OpaquePointer?
    var tp_setattro: OpaquePointer?
    var tp_as_buffer: OpaquePointer?
    var tp_flags: UInt64
    var tp_doc: UnsafePointer<Int8>?
    var tp_traverse: OpaquePointer?
    var tp_clear: OpaquePointer?
    var tp_richcompare: OpaquePointer?
    var tp_weaklistoffset: Int
    var tp_iter: OpaquePointer?
    var tp_iternext: iternextfunc?
    var tp_methods: UnsafePointer<PyMethodDef>?
    var tp_members: UnsafePointer<UnsafePointer<Int8>>?
    var tp_getset: UnsafePointer<PyGetSetDef>?
    var tp_base: OpaquePointer?
    var tp_dict: OpaquePointer?
    var tp_descr_get: OpaquePointer?
    var tp_descr_set: OpaquePointer?
    var tp_dictoffset: Int
    var tp_init: OpaquePointer?
    var tp_alloc: allocfunc?
    var tp_new: newfunc?
    var tp_free: freefunc?
    var tp_is_gc: OpaquePointer?
    var tp_bases: OpaquePointer?
    var tp_mro: OpaquePointer?
    var tp_cache: OpaquePointer?
    var tp_subclasses: OpaquePointer?
    var tp_weaklist: OpaquePointer?
    var tp_del: OpaquePointer?
    var tp_version_tag: UInt
    var tp_finalize: OpaquePointer?
    var tp_vectorcall: OpaquePointer?
}

//===----------------------------------------------------------------------===//
// PythonModule for injecting the `pythonkit` extension.
//===----------------------------------------------------------------------===//

struct PythonModule : PythonConvertible {
    private static let moduleName: StaticString = "pythonkit"
    private static let moduleDoc: StaticString = "PythonKit Extension Module"

    // PythonConvertible conformance.
    public var pythonObject: PythonObject

    private let moduleDef: PyModuleDef

    init() {
        // Define module-level methods.
        let methods: [(StaticString, PyCFunction, Int32)] = [
            ("get_test_awaitable", PythonModule.getTestAwaitable, METH_NOARGS),
        ]
        let methodDefs = Self.generateMethodDefs(from: methods)

        // Define the module.
        moduleDef = PyModuleDef(
            m_base: PyModuleDef_Base(
                ob_base: PyObject(
                    ob_refcnt: Py_ImmortalRefCount,
                    ob_type: nil
                ),
                m_init: nil,
                m_index: 0,
                m_copy: nil
            ),
            m_name: UnsafeRawPointer(Self.moduleName.utf8Start).assumingMemoryBound(to: Int8.self),
            m_doc: UnsafeRawPointer(Self.moduleDoc.utf8Start).assumingMemoryBound(to: Int8.self),
            m_size: -1,
            m_methods: methodDefs,
            m_slots: nil,
            m_traverse: nil,
            m_clear: nil,
            m_free: nil
        )

        let moduleDefinition: UnsafeMutablePointer<PyModuleDef> = .allocate(capacity: 1)
        moduleDefinition.pointee = moduleDef

        let module = PyModule_Create(moduleDefinition, Py_AbiVersion)
        let moduleName = PyUnicode_InternFromString(
            UnsafeRawPointer(Self.moduleName.utf8Start).assumingMemoryBound(to: Int8.self))
        let modules = PyImport_GetModuleDict()
        let success = _PyImport_FixupExtensionObject(module, moduleName, moduleName, modules)
        guard success == 0 else {
            fatalError("Failed to fixup extension object.")
        }

        pythonObject = PythonObject(consuming: module)
    }

    private static func generateMethodDefs(from methods: [(StaticString, PyCFunction, Int32)]) -> UnsafeMutablePointer<PyMethodDef> {
        let methodDefs = UnsafeMutablePointer<PyMethodDef>.allocate(capacity: methods.count + 1)
        for (index, (name, fn, meth)) in methods.enumerated() {
            methodDefs[index] = PyMethodDef(
                ml_name: UnsafeRawPointer(name.utf8Start).assumingMemoryBound(to: Int8.self),
                ml_meth: unsafeBitCast(fn, to: OpaquePointer.self),
                ml_flags: meth,
                ml_doc: nil)
        }
        // Sentinel value.
        methodDefs[methods.count] = PyMethodDef(
            ml_name: nil, ml_meth: nil, ml_flags: 0, ml_doc: nil)
        return methodDefs
    }
}
