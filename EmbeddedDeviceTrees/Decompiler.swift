//
//  Decompiler.swift
//  dtc
//
//  Created by Alexander Bradley on 8/24/18.
//  Copyright © 2018 UAZ. All rights reserved.
//

import Foundation

func parseProperty(data bytes:[UInt8], offset: Int) -> DeviceTreeNodeProperty {
    let name = readkPropName(bytes: bytes, offset: offset)
    let isPlaceholder = (read32(bytes: bytes, offset: offset+kPropNameLength) & (1 << 31)) != 0
    let length = ((read32(bytes: bytes, offset: offset+kPropNameLength) & 0x7fffffff) + 0x3) & ~0x3
    let valueStart:Int = offset + kPropNameLength + 4
    var valueEnd:Int = Int(offset) + Int(length) + kPropNameLength + 3
    if length == 0 {
        valueEnd = valueStart
    }
    let value = Array(bytes[valueStart...valueEnd])
    return DeviceTreeNodeProperty(name: name, length: length, value: value, isPlaceholder: isPlaceholder)
}

func parseNode(data bytes:[UInt8], offset: Int) -> DeviceTreeNode {
    let nProperties = read32(bytes: bytes, offset: offset)
    let nChilds = read32(bytes: bytes, offset: offset + 4)
    var props = [DeviceTreeNodeProperty]()
    var childs = [DeviceTreeNode]()
    var previousOffset = offset + 8
    if nProperties != 0{
        for _ in 1...nProperties {
            let currentProperty = parseProperty(data: bytes, offset: previousOffset)
            props.append(currentProperty)
            previousOffset += currentProperty.getSize()
        }
    }
    if nChilds != 0 {
        for _ in 1...nChilds {
            let currentChild = parseNode(data: bytes, offset: previousOffset)
            childs.append(currentChild)
            previousOffset += getSize(node: currentChild)
        }
    }
    return DeviceTreeNode(nProperties: nProperties, nChildren: nChilds, props: props, children: childs)
}

func stringsFromProperty(property: DeviceTreeNodeProperty) -> ([String], Bool) {
    var strArr = [String]()
    var currStr: [UInt8] = [UInt8]()
    var isstr = true
    for c in property.value {
        if c != 0 && c < 0x20 || c >= 0x7f || string(forProperty: property) == "reg" {
            isstr = false
            break
        } else if c == 0  && currStr.count != 0{
            strArr.append(String(bytes: currStr, encoding: .utf8)!)
            currStr.removeAll()
        } else if c != 0 {
            currStr.append(c)
        }
    }
    return (strArr, isstr)
}

func value(forProperty property: DeviceTreeNodeProperty, name: String) -> String {
    if property.length == 0 {
        return """
        {
            "size": "0",
            "value": ""
        }
        """
    }
    let (strArr, isstr) = stringsFromProperty(property: property)
    if isstr && strArr.count != 0 && strArr[0].count != 1 {
        if strArr.count != 1 {
            return """
            {
                "size": "\(property.length)",
                "value": \(strArr.description)
            }
            """
        }
        if property.isPlaceholder {
            return """
                {
                    "size": "\(property.length)",
                    "placeholder": "\(strArr[0])",
                }
                """
        } else {
        return """
            {
                "size": "\(property.length)",
                "value": "\(strArr[0])"
            }
            """
        }
    }
    if property.length == 4 {
        return """
        {
            "size": "\(property.length)",
            "value": "\(read32(bytes: property.value, offset: 0))"
        }
        """
        //"0x" + property.value.reversed().hexa.lowercased()
    }
    if property.length == 8 {
        return """
        {
            "size": "\(property.length)",
            "value": "\(read64(bytes: property.value, offset: 0))"
        }
        """
    }
    return """
    {
        "size": "\(property.length)",
        "value": "\("0x" + property.value.reversed().hexa)"
    }
    """
}

func getSize(node: DeviceTreeNode) -> Int {
    return 8 + getChildrenSize(node: node) + getPropertiesSize(node: node)
}

func getPropertiesSize(node: DeviceTreeNode) -> Int {
    var size = 0
    for prop in node.props {
        size += prop.getSize()
    }
    return size
}

func getChildrenSize(node: DeviceTreeNode) -> Int {
    var size = 0
    for child in node.children {
        size += getSize(node: child)
    }
    return size
}

func string(node: DeviceTreeNode) -> String{
    var str = "{\n"
    var nodeName = ""
    for property in node.props {
        let propName = string(forProperty: property)
        if propName == "name" {
            nodeName = stringsFromProperty(property: property).0[0]
        } else {
            let propertyValue = value(forProperty: property, name: propName)
            str += "\"\(propName)\": " + propertyValue + ",\n"
        }
    }
    if node.children.count != 0 {
        str += "\"children\":{\n"
        for child in node.children {
            str += string(node: child) + ",\n"
        }
        str = String(str.dropLast().dropLast()) + "\n"
        str += "}}\n"
    } else {
        str = String(str.dropLast().dropLast()) + "}"
    }
    return "\"\(nodeName)\": \(str)"
}


func string(forProperty property: DeviceTreeNodeProperty) -> String {
    return String(bytes: property.name.filter({ $0 != 0 }), encoding: .utf8)!
}

func parseDeviceTree(data bytes: [UInt8]) -> DeviceTreeNode {
    return parseNode(data: bytes, offset: 0)
}
