//
//  Command.swift
//  DesktopiaProX
//
//  Created by Sören Gade on 01.01.23.
//

import Foundation

public struct Command: Sendable {

    public let id: CommandID

    public let data: [UInt8]

    public var source: CommandSource {
        switch id {
        case .app:
            .app

        case .desk:
            .desk
        }
    }

    public init(
        id: CommandID,
        data: [UInt8]
    ) {
        self.id = id
        self.data = data
    }

}

// MARK: - Command frame bytes

extension Command {

    public init(from bytes: [UInt8]) throws(DesktopiaProXError) {
        guard let headerByte = bytes[safe: 0],
              headerByte == bytes[safe: 1],
              let source = CommandSource(rawValue: headerByte),
              bytes.last == .commandEndByte,
              let idByte = bytes[safe: 2]
        else {
            throw DesktopiaProXError.invalidCommandFormat
        }

        id = try { () throws(DesktopiaProXError) in
            switch source {
            case .app:
                guard let id = CommandID.App(rawValue: idByte) else {
                    throw DesktopiaProXError.unknownCommandID(source, idByte)
                }
                return .app(id)

            case .desk:
                guard let id = CommandID.Desk(rawValue: idByte) else {
                    throw DesktopiaProXError.unknownCommandID(source, idByte)
                }
                return .desk(id)
            }
        }()

        self.data = Array(bytes[3 ..< bytes.count - 1])
    }

    public func buildFrame() -> [UInt8] {
        var buffer: [UInt8] = [
            // packet header
            source.rawValue,
            source.rawValue,
            // command id
            id.rawValue
        ]
        buffer.append(contentsOf: data)
        // packet end
        buffer.append(.commandEndByte)
        return buffer
    }

}

// MARK: - Predefined commands

public extension Command {

    static var heartbeat: Command {
        Command(
            id: .app(.heartbeat),
            data: [
                0x04,
                0x00,
                0x00,
                0x00,
                0x06,
                // checksum
                CommandID.App.heartbeat.rawValue + 0x04 + 0x00 + 0x00 + 0x00 + 0x06
            ]
        )
    }

}

// MARK: Show status

public extension Command {

    static var showStatus: Command {
        Command(
            id: .app(.showStatus),
            data: [
                CommandID.App.showStatus.rawValue,
                0x00,
                CommandID.App.showStatus.rawValue
            ]
        )
    }

}

// MARK: Move

public extension Command {

    private enum MoveDirection {

        case up
        case down

    }

    static var moveUp: Command {
        move(.up)
    }

    static var moveDown: Command {
        move(.down)
    }

    private static func move(_ direction: MoveDirection) -> Command {
        let id: CommandID.App = switch direction {
        case .up:
            .moveUp
        case .down:
            .moveDown
        }

        return Command(
            id: .app(id),
            data: [
                0x00,
                id.rawValue + 0x00 // checksum
            ]
        )
    }

}


// MARK: Move to memory position

public extension Command {

    static var moveToMemoryPosition1: Command {
        moveToMemoryPosition(position: .moveToMemory1)
    }

    static var moveToMemoryPosition2: Command {
        moveToMemoryPosition(position: .moveToMemory2)
    }

    static var moveToMemoryPosition3: Command {
        moveToMemoryPosition(position: .moveToMemory3)
    }

    private static func moveToMemoryPosition(position: CommandID.App) -> Command {
        Command(
            id: .app(position),
            data: [
                0x00,
                position.rawValue
            ]
        )
    }

}

// MARK: Save to memory position

public extension Command {

    static var saveToMemoryPosition1: Command {
        saveToMemoryPosition(position: .saveToMemory1)
    }

    static var saveToMemoryPosition2: Command {
        saveToMemoryPosition(position: .saveToMemory2)
    }

    private static func saveToMemoryPosition(position: CommandID.App) -> Command {
        Command(
            id: .app(position),
            data: [
                position.rawValue,
                0x00,
                position.rawValue
            ]
        )
    }

}

// MARK: Stand reminder

public extension Command {

    static func standReminder(
        vibrate: Bool,
        light: Bool,
        move: Bool
    ) -> Command {
        // Note: there is a "move" parameter which we do not know the checksums for. We assume that the checksum is:
        // C = 174 + vibrate + light + move
        // if a bool is set, it is equal to value 1
        Command(
            id: .app(.standReminder),
            data: [
                vibrate.byte,
                light.byte,
                move.byte,
                174 + vibrate.byte + light.byte + move.byte
            ]
        )
    }

}
