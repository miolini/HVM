import MetalKit

// MARK: - Type Definitions
typealias u8 = UInt8
typealias u16 = UInt16
typealias u32 = UInt32
typealias i32 = Int32
typealias f32 = Float
typealias f64 = Double
typealias u64 = UInt64

// MARK: - Constants
let TPB_L2: u32 = 7
let TPB: u32 = 1 << TPB_L2
let BPG_L2: u32 = 7
let BPG: u32 = 1 << BPG_L2
let TPG: u32 = TPB * BPG

let FALSE = false
let TRUE = true

// MARK: - Type Aliases
typealias Tag = u8
typealias Val = u32
typealias Port = u32
typealias Pair = u64
typealias Rule = u8
typealias Numb = u32

// MARK: - Constants
let L_NODE_LEN: u32 = 0x2000
let L_VARS_LEN: u32 = 0x2000
let G_NODE_LEN: u32 = 1 << 29
let G_VARS_LEN: u32 = 1 << 29
let G_RBAG_LEN: u32 = TPB * BPG * 256 * 3

// MARK: - Structs
struct RBag {
    var hi_end: u32
    var hi_buf: [Pair]
    var lo_end: u32
    var lo_buf: [Pair]
}

struct LNet {
    var node_buf: [Pair]
    var vars_buf: [Port]
}

struct GNet {
    var rbag_use_A: u32
    var rbag_use_B: u32
    var rbag_buf_A: [Pair]
    var rbag_buf_B: [Pair]
    var node_buf: [Pair]
    var vars_buf: [Port]
    var node_put: [u32]
    var vars_put: [u32]
    var rbag_pos: [u32]
    var mode: u8
    var itrs: u64
    var iadd: u64
    var leak: u64
    var turn: u32
    var down: u8
    var rdec: u8
}

struct Net {
    var l_node_dif: i32
    var l_vars_dif: i32
    var l_node_buf: [Pair]
    var l_vars_buf: [Port]
    var g_rbag_use_A: UnsafePointer<u32>
    var g_rbag_use_B: UnsafePointer<u32>
    var g_rbag_buf_A: UnsafePointer<Pair>
    var g_rbag_buf_B: UnsafePointer<Pair>
    var g_node_buf: UnsafePointer<Pair>
    var g_vars_buf: UnsafePointer<Port>
    var g_node_put: UnsafePointer<u32>
    var g_vars_put: UnsafePointer<u32>
}

struct TM {
    var page: u32
    var nput: u32
    var vput: u32
    var mode: u32
    var itrs: u32
    var leak: u32
    var nloc: [u32]
    var vloc: [u32]
    var rbag: RBag
}

struct Def {
    var name: String
    var safe: Bool
    var rbag_len: u32
    var node_len: u32
    var vars_len: u32
    var root: Port
    var rbag_buf: [Pair]
    var node_buf: [Pair]
}

struct Book {
    var defs_len: u32
    var defs_buf: [Def]
}

// MARK: - Functions
func new_port(tag: Tag, val: Val) -> Port {
    return (val << 3) | UInt32(tag)
}

func get_tag(port: Port) -> Tag {
    return Tag(port & 7)
}

func get_val(port: Port) -> Val {
    return port >> 3
}

func new_pair(fst: Port, snd: Port) -> Pair {
    return (u64(snd) << 32) | u64(fst)
}

func get_fst(pair: Pair) -> Port {
    return Port(pair & 0xFFFFFFFF)
}

func get_snd(pair: Pair) -> Port {
    return Port(pair >> 32)
}

// Define your rules here
let LINK: Rule = 1
let CALL: Rule = 2
let COMM: Rule = 3
let OPER: Rule = 4
let SWIT: Rule = 5
let VOID: Rule = 6

func get_rule(a: Port, b: Port) -> Rule {
    // Your logic to determine the rule
    return LINK
}

// Interactions
func interact_link(net: inout Net, tm: inout TM, a: Port, b: Port) -> Bool {
    // Your optimized interaction logic here
    return true
}

func interact_call(net: inout Net, tm: inout TM, a: Port, b: Port) -> Bool {
    // Your optimized interaction logic here
    return true
}

func interact_comm(net: inout Net, tm: inout TM, a: Port, b: Port) -> Bool {
    // Your optimized interaction logic here
    return true
}

func interact_oper(net: inout Net, tm: inout TM, a: Port, b: Port) -> Bool {
    // Your optimized interaction logic here
    return true
}

func interact_swit(net: inout Net, tm: inout TM, a: Port, b: Port) -> Bool {
    // Your optimized interaction logic here
    return true
}

func interact_void(net: inout Net, tm: inout TM, a: Port, b: Port) -> Bool {
    // Your optimized interaction logic here
    return true
}

func interact(net: inout Net, tm: inout TM, redex: Pair) -> Bool {
    let a = get_fst(pair: redex)
    let b = get_snd(pair: redex)
    let rule = get_rule(a: a, b: b)
    
    var success = false
    switch rule {
    case LINK:
        success = interact_link(net: &net, tm: &tm, a: a, b: b)
    case CALL:
        success = interact_call(net: &net, tm: &tm, a: a, b: b)
    case COMM:
        success = interact_comm(net: &net, tm: &tm, a: a, b: b)
    case OPER:
        success = interact_oper(net: &net, tm: &tm, a: a, b: b)
    case SWIT:
        success = interact_swit(net: &net, tm: &tm, a: a, b: b)
    case VOID:
        success = interact_void(net: &net, tm: &tm, a: a, b: b)
    default:
        success = false
    }
    
    if success {
        tm.itrs += 1
    }
    
    return success
}

// MARK: - Main Metal Kernel Function
let device = MTLCreateSystemDefaultDevice()!
let library = device.makeDefaultLibrary()!
let commandQueue = device.makeCommandQueue()!

func evaluate(gnet: inout GNet) {
    guard let kernelFunction = library.makeFunction(name: "evaluateKernel") else {
        fatalError("Unable to find kernel function.")
    }
    
    guard let pipelineState = try? device.makeComputePipelineState(function: kernelFunction) else {
        fatalError("Unable to create pipeline state.")
    }
    
    guard let commandBuffer = commandQueue.makeCommandBuffer(),
          let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
        fatalError("Unable to create command buffer or compute encoder.")
    }
    
    computeEncoder.setComputePipelineState(pipelineState)
    
    // Bind the gnet buffer to the GPU
    let gnetData = NSData(bytes: &gnet, length: MemoryLayout<GNet>.size)
    let gnetBuffer = device.makeBuffer(bytes: gnetData.bytes, length: gnetData.length, options: [])!
    computeEncoder.setBuffer(gnetBuffer, offset: 0, index: 0)
    
    let gridSize = MTLSize(width: Int(TPB), height: Int(BPG), depth: 1)
    let threadGroupSize = MTLSize(width: 1, height: 1, depth: 1)
    
    computeEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadGroupSize)
    computeEncoder.endEncoding()
    
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
}

@_cdecl("hvm_m")
public func hvm_m(_ book_buffer: UnsafePointer<UInt32>?) {
    print("hvm_m called with buffer: \(String(describing: book_buffer))")
    let start = CFAbsoluteTimeGetCurrent()

    guard let device = MTLCreateSystemDefaultDevice() else {
        fatalError("No default Metal device found. Metal is not supported on this device.")
    }
    print("Default Metal device: \(device.name)")

    // Load the book
    guard let buffer = book_buffer else {
        fatalError("No book buffer provided")
    }
    
    // Print the full string from the buffer
    var bufferString = ""
    var uint32Buffer = buffer
    while true {
        let uint32Value = uint32Buffer.pointee
        if uint32Value == 0 { // assuming null-terminated string
            break
        }
        if let scalar = UnicodeScalar(uint32Value) {
            bufferString.append(String(scalar).first!)
        } else {
            bufferString.append("?")
        }
        uint32Buffer += 1
    }
    print("Buffer string: \(bufferString)")

    let book = Book(defs_len: 0, defs_buf: [])
    print("Book loaded.")

    // Create a command queue
    guard device.makeCommandQueue() != nil else {
        fatalError("Failed to create command queue.")
    }
    print("Command queue created successfully.")

    // Create and operate on GNet
    let gnet = GNet(
        rbag_use_A: 0, rbag_use_B: 0, rbag_buf_A: [], rbag_buf_B: [], 
        node_buf: [], vars_buf: [], node_put: [], vars_put: [], 
        rbag_pos: [], mode: 0, itrs: 0, iadd: 0, leak: 0, 
        turn: 0, down: 0, rdec: 0
    )
    // Placeholder for bootRedex and normalize methods
    // gnet.bootRedex()
    // gnet.normalize()

    // Timing and result output
    let end = CFAbsoluteTimeGetCurrent()
    let duration = end - start

    // Placeholder for printResult and getItrs methods
    // gnet.printResult()
    let itrs = 0 // gnet.getItrs()

    print("- ITRS: \(itrs)")
    print("- LEAK: \(gnet.leak)")
    print("- TIME: \(String(format: "%.2f", duration))s")
    print("- MIPS: \(String(format: "%.2f", Double(itrs) / duration / 1_000_000.0))")
}
