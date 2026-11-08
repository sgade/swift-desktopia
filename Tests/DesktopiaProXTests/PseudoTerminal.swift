//
//  PseudoTerminal.swift
//  DesktopiaProX
//

import Foundation

#if os(Linux)
// The Swift overlay for the C library on Linux does not export these functions.
@_silgen_name("posix_openpt") private func posix_openpt(_ flags: Int32) -> Int32
@_silgen_name("grantpt") private func grantpt(_ descriptor: Int32) -> Int32
@_silgen_name("unlockpt") private func unlockpt(_ descriptor: Int32) -> Int32
@_silgen_name("ptsname_r") private func ptsname_r(
    _ descriptor: Int32,
    _ buffer: UnsafeMutablePointer<CChar>,
    _ size: Int
) -> Int32
#endif

/// A pseudo terminal that acts as the desk.
///
/// The test uses the controller side as the desk. `Desk` opens `devicePath`.
/// Closing the controller side has the same effect as a device that is disconnected.
final class PseudoTerminal {

    enum Failure: Error {
        case unableToCreate
        case unableToSend
        case timedOut
    }

    let devicePath: String

    private var controller: Int32?

    init() throws {
        let controller = posix_openpt(O_RDWR | O_NOCTTY)
        guard controller >= 0 else {
            throw Failure.unableToCreate
        }

        var name = [CChar](repeating: 0, count: 128)
        guard grantpt(controller) == 0,
              unlockpt(controller) == 0,
              ptsname_r(controller, &name, name.count) == 0
        else {
            close(controller)
            throw Failure.unableToCreate
        }

        devicePath = String(decoding: name.prefix { $0 != 0 }.map(UInt8.init(bitPattern:)), as: UTF8.self)
        self.controller = controller
    }

    deinit {
        disconnect()
    }

    /// Sends bytes from the desk to the opened port.
    func send(_ bytes: [UInt8]) throws {
        guard let controller, write(controller, bytes, bytes.count) == bytes.count else {
            throw Failure.unableToSend
        }
    }

    /// Waits for the given number of bytes that the opened port sent to the desk.
    func receive(count: Int, timeoutInMilliseconds: Int32 = 5000) throws -> [UInt8] {
        guard let controller else {
            throw Failure.timedOut
        }

        var received: [UInt8] = []
        while received.count < count {
            var descriptor = pollfd(fd: controller, events: Int16(POLLIN), revents: 0)
            guard poll(&descriptor, 1, timeoutInMilliseconds) > 0 else {
                throw Failure.timedOut
            }

            var chunk = [UInt8](repeating: 0, count: count - received.count)
            let bytesRead = read(controller, &chunk, chunk.count)
            guard bytesRead > 0 else {
                throw Failure.timedOut
            }
            received.append(contentsOf: chunk[..<bytesRead])
        }
        return received
    }

    /// Closes the controller side.
    func disconnect() {
        guard let controller else {
            return
        }
        close(controller)
        self.controller = nil
    }

}
