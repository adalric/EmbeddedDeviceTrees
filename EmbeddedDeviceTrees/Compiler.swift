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
    if json.value.stringValue.starts(with: "0x") {
        value = String(json.value.stringValue.dropFirst().dropFirst()).hexaBytes.reversed()
    } else if json.value.string != nil {
        value = Array(json.value.stringValue.utf8)
        value.append(0)
    } else if json.value.arrayObject != nil {
        for str in json.value.arrayObject! {
            value.append(contentsOf: Array((str as! String).utf8))
            value.append(0)
        }
    } else {
        value = json.value.stringValue.hexaBytes.reversed()
    }
    let lenght = UInt32(value.count)
    return DeviceTreeNodeProperty(name: Array(name.utf8), length: lenght, value: value, isPlaceholder: false)
}

func parseDeviceTreeNode(json: JSON) -> DeviceTreeNode{
    let nChildren = json["contents"].count
    var propertiesArray = json.dictionary!
    var props = [DeviceTreeNodeProperty]()
    var children = [DeviceTreeNode]()
    if nChildren > 0 {
        let childrenArray = propertiesArray.removeValue(forKey: "contents")!
        for c in 0..<nChildren {
            children.append(parseDeviceTreeNode(json: childrenArray[c]))
        }
    }
    let nProperties = propertiesArray.count
    if nProperties != 0{
        for _ in 0..<nProperties {
            props.append(parseDeviceTreeNodeProperty(json: propertiesArray.popFirst()!))
        }
    }
    return DeviceTreeNode(nProperties: UInt32(nProperties), nChildren: UInt32(nChildren), props: props, children: children)
}

func compileDeviceTree(fromJSON json: String) -> [UInt8] {
    do{
        let dtjson = try JSON(data: (json.filter({ $0 != Character(UnicodeScalar(0)!) }).data(using: .utf8)!))
        return binaryValue(forNode: parseDeviceTreeNode(json: dtjson))
    } catch let error as NSError {
        print("Couldnt read JSON")
        print(error)
    }
    return []
}
