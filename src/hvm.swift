import MetalKit
import Foundation

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

    _ = Book(buffer: book_buffer)
    print("Book loaded.")

    // Create a command queue
    guard device.makeCommandQueue() != nil else {
        fatalError("Failed to create command queue.")
    }
    print("Command queue created successfully.")

    // Create and operate on GNet
    let gnet = GNet()
    gnet.bootRedex()
    gnet.normalize()

    // Timing and result output
    let end = CFAbsoluteTimeGetCurrent()
    let duration = end - start

    gnet.printResult()
    let itrs = gnet.getItrs()

    print("- ITRS: \(itrs)")
    print("- LEAK: \(gnet.getLeak())")
    print("- TIME: \(String(format: "%.2f", duration))s")
    print("- MIPS: \(String(format: "%.2f", Double(itrs) / duration / 1_000_000.0))")
}

func getLoadedLibraries() -> [String]? {
    let imageCount = _dyld_image_count()
    var libraries = [String]()

    for i in 0..<imageCount {
        if let cString = _dyld_get_image_name(i) {
            let name = String(cString: cString)
            libraries.append(name)
        }
    }

    return libraries
}

class Book {
    init(buffer: UnsafePointer<UInt32>?) {
        if let buffer = buffer {
            print("Book loaded with buffer: \(buffer)")
        } else {
            print("No book buffer provided")
        }
    }
}

class GNet {
    func bootRedex() {
        print("Booted root redex")
    }

    func normalize() {
        print("Normalized GNet")
    }

    func printResult() {
        print("Result: (dummy)")
    }

    func getItrs() -> UInt64 {
        return 0
    }

    func getLeak() -> UInt64 {
        return 0
    }
}