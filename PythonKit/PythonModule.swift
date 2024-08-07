//===--PythonModule.swift -------------------------------------------------===//
// This file defines types related to Python Modules and an interop layer.
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//

typealias PyModuleDefPointer = UnsafeMutableRawPointer
typealias PyTypeObjectPointer = UnsafeMutableRawPointer

// This will be 3 for the lifetime of Python 3. See PEP-384.
let PyAbiVersion: Int = 3

// From the C headers (we're not stackless).
let PyTPFlagsDefault: Int = 0

// The immortal value is 0xFFFFFFFF.
let PyImmortalRefCount: Int = Int(UInt32.max)

//===----------------------------------------------------------------------===//
// PythonModule Types.
//===----------------------------------------------------------------------===//

struct PyObject {
    var ob_refcnt: Int
    var ob_type: OpaquePointer?
}

struct PyVarObject {
    var ob_base: PyObject
    var ob_size: Int
}

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
    var am_await: OpaquePointer?
    var am_aiter: OpaquePointer?
    var am_anext: OpaquePointer?
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
    var tp_dealloc: OpaquePointer?
    var tp_vectorcall_offset: Int?
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
    var tp_flags: Int
    var tp_doc: UnsafePointer<Int8>?
    var tp_traverse: OpaquePointer?
    var tp_clear: OpaquePointer?
    var tp_richcompare: OpaquePointer?
    var tp_weaklistoffset: Int
    var tp_iter: OpaquePointer?
    var tp_iternext: OpaquePointer?
    var tp_methods: UnsafePointer<PyMethodDef>?
    var tp_members: UnsafePointer<UnsafePointer<Int8>>?
    var tp_getset: UnsafePointer<PyGetSetDef>?
    var tp_base: OpaquePointer?
    var tp_dict: OpaquePointer?
    var tp_descr_get: OpaquePointer?
    var tp_descr_set: OpaquePointer?
    var tp_dictoffset: Int
    var tp_init: OpaquePointer?
    var tp_alloc: OpaquePointer?
    var tp_new: OpaquePointer?
    var tp_free: OpaquePointer?
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
    var tp_watched: UInt8
    var tp_versions_used: UInt16
}

//===----------------------------------------------------------------------===//
// PythonModule
//===----------------------------------------------------------------------===//

struct PythonModule : PythonConvertible {
    private static let moduleName: StaticString = "PythonKit"
    private static let moduleDef = PyModuleDef(
        m_base: PyModuleDef_Base(
            ob_base: PyObject(
                ob_refcnt: PyImmortalRefCount,
                ob_type: nil
            ),
            m_init: nil,
            m_index: 0,
            m_copy: nil
        ),
        m_name: UnsafeRawPointer(moduleName.utf8Start).assumingMemoryBound(to: Int8.self),
        m_doc: nil,
        m_size: -1,
        m_methods: nil,
        m_slots: nil,
        m_traverse: nil,
        m_clear: nil,
        m_free: nil
    )

    public var pythonObject: PythonObject

    init() {
        let moduleDefinition: UnsafeMutablePointer<PyModuleDef> = .allocate(capacity: 1)
        moduleDefinition.pointee = Self.moduleDef

        _ = Python // Ensure Python is initialized.

        let pyModPointer = PyModule_Create(moduleDefinition, PyAbiVersion)
        pythonObject = PythonObject(consuming: pyModPointer)
    }
}
