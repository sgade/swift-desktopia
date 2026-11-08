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

}
