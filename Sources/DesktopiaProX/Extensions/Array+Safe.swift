//
//  Array+Safe.swift
//  DesktopiaProX
//
//  Created by Sören Gade on 01.01.23.
//

import Foundation

extension Array {

    subscript(safe index: Index) -> Element? {
        guard index >= startIndex,
              index < endIndex
        else {
            return nil
        }
        return self[index]
    }

}
