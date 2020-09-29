//
//  main.swift
//  dtc
//
//  Created by Alexander Bradley on 8/23/18.
//  Copyright © 2018 UAZ. All rights reserved.
//

import Foundation
import Darwin


var PROGRAM_NAME: String = "EmbeddedDeviceTrees"

func readBinary(fromFile file: String) -> [UInt8] {
    if let data = NSData(contentsOfFile: file) {
        var buffer = [UInt8](repeating: 0, count: data.length)
        data.getBytes(&buffer, length: data.length)
        return buffer
    }
    return []
}

func writeFile(toFile file: String, data: String){
    do {
        try data.write(toFile: file, atomically: false, encoding: .utf8)
    }
    catch let error as NSError {
        print("Ooops! Something went wrong: \(error)")
    }
}

func printHelpMenu(){
    print("""
    Usage: \(PROGRAM_NAME) [OPTIONS] FILE
    Version: 2

    Options:
      -h, --help\t\t\tShows this menu
      -d, --decode  PATH bin|im4p\tDecode Device Tree in IM4P format
      -e, --encode  PATH\tEncode Device Tree in IM4P format
      -o, --out\t\t\tPath to write output
    """
    )
}

func main(args: [String]){
    PROGRAM_NAME = (args[0] as NSString).lastPathComponent
    
    var DECODE_FLAG = false
    var ENCODE_FLAG = false
    var WRITE_FLAG  = false
    var INAME: String = ""
    var ONAME: String = ""
    var IM4P_IN = false
    
    for i in 1..<args.count {
        switch args[i] {
        case "-h", "--help":
            printHelpMenu()
            return
        case "-d", "--decode":
            DECODE_FLAG = true
            if i+2 >= args.count {
                print("Missing arguments.")
                printHelpMenu()
                exit(1)
            }
            INAME = args[i+1]
            if args[i+2] == "bin" {} else if args[i+2] == "im4p"{
                IM4P_IN = true
            } else {
                print("Decode can be done from IM4P or Binary files.")
                printHelpMenu()
                exit(1)
            }
        case "-e", "--encode":
            ENCODE_FLAG = true
            if i+1 >= args.count {
                print("Missing PATH.")
                printHelpMenu()
                exit(1)
            }
            INAME = args[i+1]
        case "-o", "--out":
            WRITE_FLAG = true
            if i+1 >= args.count {
                print("Missing PATH.")
                printHelpMenu()
                exit(1)
            }
            ONAME = args[i+1]
        default:
            continue
        }
    }
    
    if (!ENCODE_FLAG && !DECODE_FLAG) || (ENCODE_FLAG && DECODE_FLAG) || (!checkFileExists(file: INAME)) {
        print("Invalid operation.")
        printHelpMenu()
        exit(2)
    }
    
    var JSON_REPRESENTATION = ""
    
    if DECODE_FLAG{
        if IM4P_IN{
            let cs = (INAME as NSString).utf8String
            let buffer = UnsafePointer<Int8>(cs)
            let size = UnsafeMutablePointer<Int>.allocate(capacity: 64)
            let type = UnsafeMutablePointer<UInt32>.allocate(capacity: 32)
            var build: UnsafeMutablePointer<Int8>? = UnsafeMutablePointer<Int8>.allocate(capacity: 64)
            build!.assign(repeating: 0, count: 64)
            let str = read_from_file(buffer, size, type, &build)
            let array = Array(UnsafeBufferPointer(start: str, count: size.pointee))
            fputs("\u{001B}[0;31m\(String(cString: build!)) - \(UInt32toSting(integer: type.pointee))\u{001B}[0;0m\n", stderr)
            JSON_REPRESENTATION = "{\(string(node: parseDeviceTree(data: array)))}".data(using: .utf8)!.prettyPrintedJSONString!
        } else {
            JSON_REPRESENTATION = "{\(string(node: parseDeviceTree(data: readBinary(fromFile: INAME))))}".data(using: .utf8)!.prettyPrintedJSONString!
        }
        if WRITE_FLAG {
            writeFile(toFile: ONAME, data: JSON_REPRESENTATION) 
        } else {
            print(JSON_REPRESENTATION)
        }
    } else if ENCODE_FLAG {
        do{
            let binaryTree = try compileDeviceTree(fromJSON: String(contentsOfFile: INAME))
//            let size = UnsafeMutablePointer<Int>.allocate(capacity: 64)
//            let pointer = UnsafeMutablePointer<UInt8>(mutating: binaryTree)
//            let imgdat = getIM4P(pointer, binaryTree.count, size)
            if WRITE_FLAG {
//                let pointerCompiled = UnsafeBufferPointer(start: pointer, count: size.pointee)
                let data = Data(binaryTree)
                try! data.write(to: URL(fileURLWithPath: ONAME))
            } else {
                print("Cannot write to STDOUT.")
                exit(3)
            }
        }catch {
            print("Error opening file")
        }
    }
    
    
//
//    if !valid {
//        print("Invalid option.")
//        printHelpMenu()
//    }
    
    
    
//    if args[1] == "decompile" {
//        print("Decompiling")
//
//    } else if args[1] == "compile" {
//        do{
//            print("Compiling")
//
//            let binaryTree = try compileDeviceTree(fromJSON: String(contentsOfFile: args[2]))
//            let pointer = UnsafeBufferPointer(start:binaryTree, count:binaryTree.count)
//            let data = Data(buffer:pointer)
//            try data.write(to: URL(fileURLWithPath: args[3]))
//        } catch {
//            print("Error opening file")
//        }
//    }
}

 main(args: CommandLine.arguments)
