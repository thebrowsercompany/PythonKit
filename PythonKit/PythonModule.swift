//===--PythonModule.swift -------------------------------------------------===//
// This file defines types related to Python Modules and an interop layer.
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//

typealias PyModuleDefPointer = UnsafeMutableRawPointer
typealias PyTypeObjectPointer = UnsafeMutableRawPointer

// This will be 3 for the lifetime of Python 3. See PEP-384.
let PyAbiVersion: Int = 3

//===----------------------------------------------------------------------===//
// PythonModule Types.
//===----------------------------------------------------------------------===//

struct PyObject {
    var ob_refcnt: UInt32
    var ob_type: OpaquePointer?
}

struct PyVarObject {
    var ob_base: PyObject
    var ob_size: Int32
}

struct PyModuleDef_Base {
    var ob_base: PyObject
    var m_init: OpaquePointer?
    var m_index: Int32
    var m_copy: OpaquePointer?
}

struct PyModuleDef_Slot {
    var slot: Int32
    var value: OpaquePointer
}

struct PyModuleDef {
    var m_base: PyModuleDef_Base
    var m_name: UnsafePointer<Int8>
    var m_doc: UnsafePointer<Int8>?
    var m_size: Int32
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
    var tp_basicsize: Int32
    var tp_itemsize: Int32
    var tp_dealloc: OpaquePointer?
    var tp_vectorcall_offset: Int32?
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
    var tp_flags: Int32
    var tp_doc: UnsafePointer<Int8>?
    var tp_traverse: OpaquePointer?
    var tp_clear: OpaquePointer?
    var tp_richcompare: OpaquePointer?
    var tp_weaklistoffset: Int32
    var tp_iter: OpaquePointer?
    var tp_iternext: OpaquePointer?
    var tp_methods: UnsafePointer<PyMethodDef>?
    var tp_members: UnsafePointer<UnsafePointer<Int8>>?
    var tp_getset: UnsafePointer<PyGetSetDef>?
    var tp_base: OpaquePointer?
    var tp_dict: OpaquePointer?
    var tp_descr_get: OpaquePointer?
    var tp_descr_set: OpaquePointer?
    var tp_dictoffset: Int32
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
    var tp_version_tag: UInt32
    var tp_finalize: OpaquePointer?
    var tp_vectorcall: OpaquePointer?
    var tp_watched: UInt8
    var tp_versions_used: UInt16
}

//===----------------------------------------------------------------------===//
// PythonModule
//===----------------------------------------------------------------------===//

struct PythonModule {
    private static let moduleName: StaticString = "PythonKit"
    private static let moduleDef = PyModuleDef(
        m_base: PyModuleDef_Base(
            ob_base: PyObject(
                ob_refcnt: UInt32.max, // _Py_IMMORTAL_REFCNT
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
}

extension PythonModule: PythonConvertible {
    public var pythonObject: PythonObject {
        let moduleDefinition: UnsafeMutablePointer<PyModuleDef> = .allocate(capacity: 1)
        moduleDefinition.pointee = Self.moduleDef

        _ = Python // Ensure Python is initialized.
        let pyModPointer = PyModule_Create(moduleDefinition, PyAbiVersion)
        return PythonObject(consuming: pyModPointer)
    }
}
