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
    private static let moduleDef = PyModuleDef(
        m_base: PyModuleDef_Base(
            ob_base: PyObject(
                ob_refcnt: Py_ImmortalRefCount,
                ob_type: nil
            ),
            m_init: nil,
            m_index: 0,
            m_copy: nil
        ),
        m_name: UnsafeRawPointer(moduleName.utf8Start).assumingMemoryBound(to: Int8.self),
        m_doc: UnsafeRawPointer(moduleDoc.utf8Start).assumingMemoryBound(to: Int8.self),
        m_size: -1,
        m_methods: nil,
        m_slots: nil,
        m_traverse: nil,
        m_clear: nil,
        m_free: nil
    )

    // PythonConvertible conformance.
    public var pythonObject: PythonObject

    internal var awaitableManager: AwaitableManager = AwaitableManager()

    init() {
        let moduleDefinition: UnsafeMutablePointer<PyModuleDef> = .allocate(capacity: 1)
        moduleDefinition.pointee = Self.moduleDef

        let module = PyModule_Create(moduleDefinition, Py_AbiVersion)
        let moduleName = PyUnicode_InternFromString(
            UnsafeRawPointer(Self.moduleName.utf8Start).assumingMemoryBound(to: Int8.self))
        let modules = PyImport_GetModuleDict()
        let success = _PyImport_FixupExtensionObject(module, moduleName, moduleName, modules)
        guard success == 0 else {
            fatalError("Failed to fixup extension object.")
        }

        pythonObject = PythonObject(consuming: module)

        // Ready the type.
        guard addType(pythonKitAwaitableType) else {
            fatalError("Failed to add Awaitable type.")
        }

        // Add the Awaitable object of the type.
        guard addObject(pythonKitAwaitableType, named: "Awaitable") else {
            fatalError("Failed to add Awaitable object.")
        }
    }

    let pythonKitAwaitableType: UnsafeMutablePointer<PyTypeObject> = {
        // For __name__ and __doc__.
        let pythonKitAwaitableName: StaticString = "Awaitable"
        let pythonKitAwaitableDoc: StaticString = "PythonKit Awaitable Function"

        // The async methods.
        let pythonKitAwaitableAsyncMethods = UnsafeMutablePointer<PyAsyncMethods>.allocate(capacity: 1)
        pythonKitAwaitableAsyncMethods.initialize(to: PyAsyncMethods(
            am_await: PythonKitAwaitable.next,
            am_aiter: nil,
            am_anext: nil,
            am_send: nil))

        // The methods.
        let methods: [(StaticString, PyCFunction, Int32)] = [
            ("magic", PythonKitAwaitable.magic, METH_NOARGS),
            ("handle", PythonKitAwaitable.handle, METH_NOARGS),
            ("set_handle", PythonKitAwaitable.setHandle, METH_O),
            ("result", PythonKitAwaitable.result, METH_NOARGS),
            ("set_result", PythonKitAwaitable.setResult, METH_O),
        ]

        // Build the [PyMethodDef] structure.
        let pythonKitAwaitableMethods = UnsafeMutablePointer<PyMethodDef>.allocate(capacity: methods.count + 1)
        for (index, (name, fn, meth)) in methods.enumerated() {
            pythonKitAwaitableMethods[index] = PyMethodDef(
                ml_name: UnsafeRawPointer(name.utf8Start).assumingMemoryBound(to: Int8.self),
                ml_meth: unsafeBitCast(fn, to: OpaquePointer.self),
                ml_flags: meth,
                ml_doc: nil)
        }
        // Sentinel value.
        pythonKitAwaitableMethods[methods.count] = PyMethodDef(
            ml_name: nil, ml_meth: nil, ml_flags: 0, ml_doc: nil)

        // The type. This layout currently matches Python 3.11.
        // TODO: We should have conditionals to support other versions.
        let pythonKitAwaitableType = UnsafeMutablePointer<PyTypeObject>.allocate(capacity: 1)
        pythonKitAwaitableType.initialize(to: PyTypeObject(
            ob_base: PyVarObject(
                ob_base: PyObject(
                    ob_refcnt: Py_ImmortalRefCount,
                    ob_type: nil
                ),
                ob_size: 0
            ),
            tp_name: UnsafeRawPointer(pythonKitAwaitableName.utf8Start).assumingMemoryBound(to: Int8.self),
            tp_basicsize: MemoryLayout<PythonKitAwaitable>.size,
            tp_itemsize: 0,
            tp_dealloc: PythonKitAwaitable.dealloc,
            tp_vectorcall_offset: 0,
            tp_getattr: nil,
            tp_setattr: nil,
            tp_as_async: pythonKitAwaitableAsyncMethods,
            tp_repr: nil,
            tp_as_number: nil,
            tp_as_sequence: nil,
            tp_as_mapping: nil,
            tp_hash: nil,
            tp_call: nil,
            tp_str: nil,
            tp_getattro: nil,
            tp_setattro: nil,
            tp_as_buffer: nil,
            tp_flags: Py_TPFlagsDefault | Py_TPFLAGS_HEAPTYPE,
            tp_doc: UnsafeRawPointer(pythonKitAwaitableDoc.utf8Start).assumingMemoryBound(to: Int8.self),
            tp_traverse: nil,
            tp_clear: nil,
            tp_richcompare: nil,
            tp_weaklistoffset: 0,
            tp_iter: nil,
            tp_iternext: PythonKitAwaitable.next,
            tp_methods: pythonKitAwaitableMethods,
            tp_members: nil,
            tp_getset: nil,
            tp_base: nil,
            tp_dict: nil,
            tp_descr_get: nil,
            tp_descr_set: nil,
            tp_dictoffset: 0,
            tp_init: nil,
            tp_alloc: PyType_GenericAlloc,
            tp_new: PythonKitAwaitable.new,
            tp_free: PyObject_Free,
            tp_is_gc: nil,
            tp_bases: nil,
            tp_mro: nil,
            tp_cache: nil,
            tp_subclasses: nil,
            tp_weaklist: nil,
            tp_del: nil,
            tp_version_tag: 0,
            tp_finalize: nil,
            tp_vectorcall: nil))

        return pythonKitAwaitableType
    }()
}
