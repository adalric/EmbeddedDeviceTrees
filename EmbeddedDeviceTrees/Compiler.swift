//
//  Compiler.swift
//  dtc
//
//  Created by Alexander Bradley on 8/24/18.
//  Copyright © 2018 UAZ. All rights reserved.
//

import Foundation
import SwiftyJSON

func binaryValue(forNode node: DeviceTreeNode) -> [UInt8] {
    return split32(bytes: node.nProperties) + split32(bytes: node.nChildren) + binaryValue(forProperties: node.props) + binaryValue(forNodes: node.children)
}

func binaryValue(forProperties props:[DeviceTreeNodeProperty]) -> [UInt8] {
    var array = [UInt8]()
    for prop in props {
        array.append(contentsOf: binaryValue(forProperty: prop))
    }
    return array
}

func binaryValue(forNodes children: [DeviceTreeNode]) -> [UInt8] {
    var array = [UInt8]()
    for child in children {
        array.append(contentsOf: binaryValue(forNode: child))
    }
    return array
}

func binaryValue(forProperty property: DeviceTreeNodeProperty) -> [UInt8] {
    let namePadded = extendArray(array: property.name, newSize: 32)
    let lengthArr = split32(bytes: (property.length + 3) & ~0x03)
    let valuePadded = extendArray(array: property.value, newSize: Int(read32(bytes: lengthArr, offset: 0)))
    return namePadded + lengthArr + valuePadded
}

func parseDeviceTreeNodeProperty(json: (key: String, value: JSON))  -> DeviceTreeNodeProperty{
    var name = ""
    var value = [UInt8]()
    name = json.key
    let contents = json.value.dictionary!
    var isPlaceholder = false
    var valueContent = JSON()
    if contents.keys.contains("placeholder") {
        isPlaceholder = true
        valueContent = contents["placeholder"]!
    } else {
        valueContent = contents["value"]!
    }
    var size: UInt32 = 0
    var padding = 0

    if valueContent.stringValue.starts(with: "0x") {
        value = String(valueContent.stringValue.dropFirst().dropFirst()).hexaBytes.reversed()
    } else if contents["size"]!.string! == "4" {
        let valueInt: UInt32? = UInt32(valueContent.stringValue)
        if valueInt != nil {
            value = withUnsafeBytes(of: valueInt!.littleEndian, Array.init)
        } else {
            padding = 1
            value = Array(valueContent.stringValue.utf8)
            value.append(0)
        }
    } else if contents["size"]!.string! == "8" {
        let valueInt: UInt64? = UInt64(valueContent.stringValue)
        if valueInt != nil {
            value = withUnsafeBytes(of: valueInt!.littleEndian, Array.init)
        } else {
            padding = 1
            value = Array(valueContent.stringValue.utf8)
            value.append(0)
        }
    } else if valueContent.string != nil {
        padding = 1
        value = Array(valueContent.stringValue.utf8)
        value.append(0)
    } else if valueContent.arrayObject != nil {
        for str in valueContent.arrayObject! {
            value.append(contentsOf: Array((str as! String).utf8))
            value.append(0)
        }
        padding = 1
    } else {
        value = valueContent.stringValue.hexaBytes.reversed()
    }
    
    if Int(contents["size"]!.string!)! != (value.count) && Int(contents["size"]!.string!)! < (value.count + padding) && contents["size"]!.string! != "0" {
        print("Warning: Size (\(contents["size"]!.string!)) for property \(name) is not enough to fit value (\(valueContent.stringValue)). Increasing to \(value.count + 2)")
        size = UInt32(value.count + 2)
    } else {
        size = UInt32(contents["size"]!.string!)!
    }
    return DeviceTreeNodeProperty(name: Array(name.utf8), length: size, value: value, isPlaceholder: isPlaceholder)
}

func parseDeviceTreeNode(json: (key: String, value: JSON)) -> DeviceTreeNode{
    let nChildren = json.value["children"].count
    var propertiesArray = json.value.dictionary!
    propertiesArray["name"] = JSON(["value": json.key, "size": "\(json.key.count + 1)"])
    var props = [DeviceTreeNodeProperty]()
    var children = [DeviceTreeNode]()
    if nChildren > 0 {
        var childrenArray = propertiesArray.removeValue(forKey: "children")!.dictionary!
        for c in 0..<nChildren {
            children.append(parseDeviceTreeNode(json: childrenArray.popFirst()!))
        }
    }
    let nProperties = propertiesArray.count
    if nProperties != 0{
        for _ in 0..<nProperties {
            props.append(parseDeviceTreeNodeProperty(json: propertiesArray.popFirst()!))
        }
    }
    var nameArray = Array(json.value.stringValue.utf8)
    nameArray.append(0)
    return DeviceTreeNode(nProperties: UInt32(nProperties), nChildren: UInt32(nChildren), props: props, children: children)
}

func compileDeviceTree(fromJSON json: String) -> [UInt8] {
    do{
        let dtjson = try JSON(data: (json.filter({ $0 != Character(UnicodeScalar(0)!) }).data(using: .utf8)!))
        let dtName = Array(dtjson.dictionary!.keys)[0]
        let treeNode = parseDeviceTreeNode(json: (key: dtName, value: dtjson[dtName]))
        return binaryValue(forNode: treeNode)
    } catch let error as NSError {
        print("Couldnt read JSON")
        print(error)
    }
    return []
}
