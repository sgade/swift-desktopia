//
//  Bool+UInt8.swift
//  swift-desktopia
//
//  Created by Sören Gade on 07.02.26.
//

extension Bool {

    var byte: UInt8 {
        self ? 0x01 : 0x00
    }

}
