//
//  Definitions.swift
//  dtc
//
//  Created by Alexander Bradley on 8/24/18.
//  Copyright © 2018 UAZ. All rights reserved.
//

import Foundation

let kPropNameLength = 32

struct DeviceTreeNode {
    var nProperties: UInt32
    var nChildren: UInt32
    var props: [DeviceTreeNodeProperty]
    var children: [DeviceTreeNode]
}

struct DeviceTreeNodeProperty {
    var name: [UInt8]
    var length: UInt32
    var value: [UInt8]
    var isPlaceholder: Bool

    func getSize() -> Int {
        return name.count + 4 + Int(length)
    }
}
