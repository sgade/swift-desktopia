//
//  DeskTests.swift
//  DesktopiaProX
//

import DesktopiaProX
import Foundation
import Testing

struct DeskTests {

    // 638, 894 and 1150 mm have the low byte 0x7E, which is also the end byte of a frame.
    @Test(arguments: [723, 638, 894, 1150])
    func readsTheHeight(millimeters: Int) async throws {
        let terminal = try PseudoTerminal()
        let desk = Desk(port: terminal.devicePath, keepAlive: false)
        try await desk.connect()
        let commands = try await desk.readCommands()

        try terminal.send(heightFrame(millimeters: millimeters))
        _ = await firstElement(of: commands)

        let height = await desk.height
        #expect(height?.converted(to: .millimeters).value == Double(millimeters))
        try await desk.disconnect()
    }

    @Test func ignoresAHeightWithAWrongChecksum() async throws {
        let terminal = try PseudoTerminal()
        let desk = Desk(port: terminal.devicePath, keepAlive: false)
        try await desk.connect()
        let commands = try await desk.readCommands()

        var corrupted = heightFrame(millimeters: 900)
        corrupted[7] &+= 1
        try terminal.send(corrupted + heightFrame(millimeters: 723))
        let command = await firstElement(of: commands)

        let expected = heightFrame(millimeters: 723)
        #expect(command?.data == Array(expected[3 ..< expected.count - 1]))
        try await desk.disconnect()
    }

    // MARK: Sending

    @Test func writesACommandTwoTimes() async throws {
        let terminal = try PseudoTerminal()
        let desk = Desk(port: terminal.devicePath, keepAlive: false)
        try await desk.connect()

        let sending = Task {
            try await desk.send(command: .moveUp)
        }
        let first = try terminal.receive(count: 6, timeoutInMilliseconds: 1000)
        let start = ContinuousClock.now
        let second = try terminal.receive(count: 6, timeoutInMilliseconds: 1000)
        let gap = start.duration(to: .now)
        try await sending.value

        #expect(first == Command.moveUp.buildFrame())
        #expect(second == Command.moveUp.buildFrame())
        #expect(gap >= .milliseconds(15))
        try await desk.disconnect()
    }

    @Test func writesAHeartbeatOneTime() async throws {
        let terminal = try PseudoTerminal()
        let desk = Desk(port: terminal.devicePath, keepAlive: false)
        try await desk.connect()

        try await desk.send(command: .heartbeat)

        #expect(try terminal.receive(count: 10) == Command.heartbeat.buildFrame())
        #expect(throws: PseudoTerminal.Failure.timedOut) {
            try terminal.receive(count: 1, timeoutInMilliseconds: 100)
        }
        try await desk.disconnect()
    }

    // MARK: Lost device

    @Test func commandStreamEndsWhenTheDeviceIsLost() async throws {
        let terminal = try PseudoTerminal()
        let desk = Desk(port: terminal.devicePath, keepAlive: false)
        try await desk.connect()
        let commands = try await desk.readCommands()

        terminal.disconnect()

        #expect(await ends(commands))
        try await desk.disconnect()
    }

    @Test func sendingThrowsWhenTheDeviceIsLost() async throws {
        let terminal = try PseudoTerminal()
        let desk = Desk(port: terminal.devicePath, keepAlive: false)
        try await desk.connect()

        terminal.disconnect()

        await #expect(throws: (any Error).self) {
            try await desk.send(command: .moveUp)
        }
        try await desk.disconnect()
    }

}
