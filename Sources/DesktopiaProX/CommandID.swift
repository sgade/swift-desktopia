//
//  CommandID.swift
//  DesktopiaProX
//
//  Created by Sören Gade on 01.01.23.
//

public enum CommandID: Sendable {

    case app(App)
    case desk(Desk)

}

// MARK: RawRepresentable

extension CommandID {

    public var rawValue: UInt8 {
        switch self {
        case let .app(command):
            command.rawValue

        case let .desk(command):
            command.rawValue
        }
    }

}

// MARK: - App

public extension CommandID {

    enum App: UInt8, Sendable {

        case heartbeat      = 0xAA
        case showStatus     = 0x07

        case moveUp         = 0x01
        case moveDown       = 0x02

        case saveToMemory1  = 0x03
        case saveToMemory2  = 0x04

        case moveToMemory1  = 0x05
        case moveToMemory2  = 0x06
        case moveToMemory3  = 0x27

        case standReminder  = 0xAB

    }
}

// MARK: - Desk

public extension CommandID {

    enum Desk: UInt8, Sendable {

        case heightInfo  = 0x01

    }

}
