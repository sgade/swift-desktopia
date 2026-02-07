//
//  SerialPort+Command.swift
//  DesktopiaProX
//
//  Created by Sören Gade on 01.01.23.
//

import Foundation
import SwiftSerial

// MARK: Write

extension SerialPort {

    /// Sends the command to the serial port.
    ///
    /// - Parameter command: The command to send.
    /// - Returns: Number of bytes written.
    func write(command: Command) throws -> Int {
        var buffer = command.buildFrame()
        return try writeBytes(from: &buffer, size: buffer.count)
    }

}

// MARK: Read

extension SerialPort {

    /// Returns an ``AsyncStream<Command>`` for the commands received on the serial port.
    func readCommands() throws -> AsyncStream<Command> {
        let stream = try asyncBytes()

        return AsyncStream { continuation in
            let readingTask = Task(name: "Serial: Reading bytes") {
                var buffer: [UInt8] = []

                for await byte in stream {
                    guard !Task.isCancelled else {
                        break
                    }
                    buffer.append(byte)

                    guard byte == .commandEndByte else {
                        continue
                    }

                    do {
                        let command = try Command(from: buffer)

                        continuation.yield(command)
                    } catch {
                        // error ignored
                    }
                    buffer.removeAll()
                }
            }

            continuation.onTermination = { _ in
                readingTask.cancel()
            }
        }
    }

}
