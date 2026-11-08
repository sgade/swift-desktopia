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
                var reader = FrameReader()

                for await byte in stream {
                    guard !Task.isCancelled else {
                        break
                    }

                    for frame in reader.append(byte) {
                        do {
                            let command = try Command(from: frame)

                            continuation.yield(command)
                        } catch {
                            // error ignored
                        }
                    }
                }
            }

            continuation.onTermination = { _ in
                readingTask.cancel()
            }
        }
    }

}
