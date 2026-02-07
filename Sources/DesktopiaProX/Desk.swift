//
//  Desk.swift
//  DesktopiaProX
//
//  Created by Sören Gade on 02.02.26.
//

import Foundation
import SwiftSerial

/// A connection instance to a Desktopia Pro X desk.
///
/// # Identifying the correct serial port
///
/// To find the correct serial port, and to verify that the connection is to a Desktopia Pro X controller,
/// you can check the vendor id to be `1A86`.
public actor Desk {

    /// The last known height of the desk.
    ///
    /// This value may be `nil` if the height has never been reported by the desk.
    public private(set) var height: Measurement<UnitLength>?

    private let serial: SerialPort

    private let keepAlive: Bool

    private let heartbeatInterval: TimeInterval = 5

    private var heartbeatTask: Task<Void, any Error>?

    /// Creates a new desk instance.
    ///
    /// - Parameters:
    ///   - port: The path to the serial port.
    ///   - keepAlive: Whether a regular heartbeat command should be sent to the desk, keeping the connection alive.
    ///     This also keeps the desk controller's display alive.
    public init(
        port: String,
        keepAlive: Bool
    ) {
        serial = SerialPort(path: port)
        self.keepAlive = keepAlive
    }

    deinit {
        heartbeatTask?.cancel()
    }

}

// MARK: Managing the physical connection to the desk

public extension Desk {

    func connect() throws {
        try serial.openPort()
        try serial.setSettings(
            baudRateSetting: .symmetrical(.baud9600),
            minimumBytesToRead: 1
        )

        if keepAlive {
            heartbeatTask = Task(name: "Desk heartbeat") {
                repeat {
                    try send(command: .heartbeat)
                    try await Task.sleep(for: .seconds(heartbeatInterval))
                } while !Task.isCancelled
            }
        }
    }

    func disconnect() async throws {
        heartbeatTask?.cancel()
        _ = try await heartbeatTask?.value

        serial.closePort()
    }

}

// MARK: Sending commands

public extension Desk {

    func send(command: Command) throws {
        _ = try serial.write(command: command)
    }

}

// MARK: Receiving commands

public extension Desk {

    func readCommands() throws -> AsyncStream<Command> {
        let stream = try serial.readCommands()

        return AsyncStream { contination in
            Task(name: "Desk: Reading commands") {
                for await command in stream {
                    guard !Task.isCancelled else {
                        break
                    }

                    parse(event: command)
                    contination.yield(command)
                }
                contination.finish()
            }
        }
    }

}

// MARK: Interpreting commands

private extension Desk {

    func parse(event: Command) {
        switch event.id {
        case let .desk(commandId):
            parse(
                deskEvent: commandId,
                data: event.data
            )

        case .app:
            break
        }
    }

    func parse(
        deskEvent: CommandID.Desk,
        data: [UInt8]
    ) {
        switch deskEvent {
        case .heightInfo:
            guard let height = parseHeightData(data) else {
                return
            }
            self.height = height
        }
    }

}

// MARK: Reading desk height

private extension Desk {

    func parseHeightData(_ data: [UInt8]) -> Measurement<UnitLength>? {
        guard let overflowCounter = data[safe: 1],
              let counter = data[safe: 2]
        else {
            return nil
        }

        let mmHeight: Int = Int(overflowCounter) * 256 + Int(counter)
        return Measurement(
            value: Double(mmHeight),
            unit: .millimeters
        )
    }

}
