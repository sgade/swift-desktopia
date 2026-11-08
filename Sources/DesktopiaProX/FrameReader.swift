//
//  FrameReader.swift
//  DesktopiaProX
//

/// Splits the byte stream from the desk into frames.
///
/// A frame has the form `F2 F2 <function> <data length> <data...> <checksum> 7E`.
/// The data and the checksum can contain any byte, also the end byte. Thus, only the data length shows
/// the end of a frame.
struct FrameReader {

    /// The number of bytes in a frame in addition to the data: two header bytes, the function, the data length,
    /// the checksum and the end byte.
    private static let frameOverhead = 6

    /// Frames are short. A longer frame shows that the data length is not correct.
    private static let maximumFrameLength = 32

    private var buffer: [UInt8] = []

    /// Adds the byte to the stream.
    ///
    /// - Returns: The frames that this byte completes. Usually, this is no frame or one frame.
    mutating func append(_ byte: UInt8) -> [[UInt8]] {
        buffer.append(byte)

        var frames: [[UInt8]] = []
        while let frameLength = nextFrameLength() {
            guard frameLength <= Self.maximumFrameLength else {
                buffer.removeFirst()
                continue
            }
            guard buffer.count >= frameLength else {
                break
            }

            let frame = Array(buffer.prefix(frameLength))
            if Self.isValid(frame) {
                frames.append(frame)
                buffer.removeFirst(frameLength)
            } else {
                // The header was not a real header. A frame can start at any later byte.
                buffer.removeFirst()
            }
        }
        return frames
    }

    /// Discards the bytes before the next header.
    ///
    /// - Returns: The length of the frame at the start of the buffer, or `nil` if more bytes are necessary to know it.
    private mutating func nextFrameLength() -> Int? {
        let header = CommandSource.desk.rawValue

        while let first = buffer.first {
            guard first == header else {
                buffer.removeFirst()
                continue
            }
            guard buffer.count >= 2 else {
                return nil
            }
            guard buffer[1] == header else {
                buffer.removeFirst()
                continue
            }
            guard buffer.count >= 4 else {
                return nil
            }
            return Int(buffer[3]) + Self.frameOverhead
        }
        return nil
    }

    private static func isValid(_ frame: [UInt8]) -> Bool {
        guard frame.last == .commandEndByte else {
            return false
        }

        let checksum = frame[2 ..< frame.count - 2].reduce(0, &+)
        return checksum == frame[frame.count - 2]
    }

}
