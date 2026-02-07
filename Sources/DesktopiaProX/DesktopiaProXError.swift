//
//  DesktopiaProXError.swift
//  DesktopiaProX
//
//  Created by Sören Gade on 01.01.23.
//

import Foundation

public enum DesktopiaProXError: Error {

    case invalidCommandFormat
    case unknownCommandID(CommandSource, UInt8)

}
