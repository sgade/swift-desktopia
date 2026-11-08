//
//  FrameReaderTests.swift
//  DesktopiaProX
//

@testable import DesktopiaProX
import Testing

struct FrameReaderTests {

    /// A frame from a real desk, at 719 mm.
    private let capturedFrame: [UInt8] = [0xF2, 0xF2, 0x01, 0x03, 0x02, 0xCF, 0x07, 0xDC, 0x7E]

    private func read(_ bytes: [UInt8]) -> [[UInt8]] {
        var reader = FrameReader()
        return bytes.flatMap { reader.append($0) }
    }

    @Test func readsACapturedFrame() {
        #expect(read(capturedFrame) == [capturedFrame])
    }

    @Test func returnsTheFrameOnlyWithTheLastByte() {
        var reader = FrameReader()

        for byte in capturedFrame.dropLast() {
            #expect(reader.append(byte).isEmpty)
        }

        #expect(reader.append(0x7E) == [capturedFrame])
    }

    @Test func readsTwoFrames() {
        let second = heightFrame(millimeters: 1000)

        #expect(read(capturedFrame + second) == [capturedFrame, second])
    }

    @Test func discardsNoiseBeforeTheHeader() {
        #expect(read([0x00, 0x7E, 0xF2, 0x13] + capturedFrame) == [capturedFrame])
    }

    @Test func readsACompleteFrameAfterAnIncompleteFrame() {
        #expect(read([0xF2, 0xF2, 0x01, 0x03] + capturedFrame) == [capturedFrame])
    }

    @Test(arguments: [638, 894, 1150])
    func acceptsTheEndByteAsTheLowHeightByte(millimeters: Int) {
        let frame = heightFrame(millimeters: millimeters)

        #expect(frame[5] == 0x7E)
        #expect(read(frame) == [frame])
    }

    @Test func acceptsTheEndByteAsTheChecksum() {
        // 625 mm is 0x02 0x71, which gives the checksum 0x7E.
        let frame = heightFrame(millimeters: 625)

        #expect(frame[7] == 0x7E)
        #expect(read(frame) == [frame])
    }

    @Test func rejectsAWrongChecksum() {
        var corrupted = capturedFrame
        corrupted[7] &+= 1

        #expect(read(corrupted).isEmpty)
    }

    @Test func rejectsAWrongEndByte() {
        var corrupted = capturedFrame
        corrupted[8] = 0x00

        #expect(read(corrupted).isEmpty)
    }

    @Test func readsAValidFrameAfterACorruptedFrame() {
        var corrupted = capturedFrame
        corrupted[7] &+= 1

        #expect(read(corrupted + capturedFrame) == [capturedFrame])
    }

    @Test func readsAnUnknownFunctionWithTheEndByteInItsData() {
        let unknown = frame(function: 0xA5, data: [0x0D, 0x7E, 0x20])

        #expect(read(unknown) == [unknown])
    }

    @Test func recoversFromALengthThatIsTooLarge() {
        #expect(read([0xF2, 0xF2, 0x01, 0xFF] + capturedFrame) == [capturedFrame])
    }

    @Test func acceptsTheHeaderBytesInTheData() {
        let frameWithHeaderBytes = frame(function: 0xA5, data: [0xF2, 0xF2, 0x01])

        #expect(read(frameWithHeaderBytes) == [frameWithHeaderBytes])
    }

    @Test func ignoresFramesFromTheApp() {
        #expect(read(Command.moveUp.buildFrame()).isEmpty)
    }

}
