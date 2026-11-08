//
//  TestSupport.swift
//  DesktopiaProX
//

/// Returns a height frame in the format that a real desk sends.
func heightFrame(millimeters: Int) -> [UInt8] {
    frame(function: 0x01, data: [UInt8(millimeters / 256), UInt8(millimeters % 256), 0x07])
}

/// Returns a frame from the desk with a correct length and checksum.
func frame(function: UInt8, data: [UInt8]) -> [UInt8] {
    let length = UInt8(data.count)
    let checksum = data.reduce(function &+ length, &+)
    return [0xF2, 0xF2, function, length] + data + [checksum, 0x7E]
}

/// Returns the result of the operation, or `nil` if it takes longer than the time limit.
///
/// A defect must make the test fail, and not make it wait without end.
func withTimeLimit<Result: Sendable>(
    _ operation: @escaping @Sendable () async -> Result
) async -> Result? {
    await withTaskGroup(of: Result?.self) { group in
        group.addTask {
            await operation()
        }
        group.addTask {
            try? await Task.sleep(for: .seconds(5))
            return nil
        }

        let result = await group.next() ?? nil
        group.cancelAll()
        return result
    }
}

func firstElement<Element: Sendable>(of stream: AsyncStream<Element>) async -> Element? {
    await withTimeLimit {
        await stream.first { _ in true }
    } ?? nil
}

/// Returns `true` if the stream ends before the time limit.
func ends<Element: Sendable>(_ stream: AsyncStream<Element>) async -> Bool {
    let result: Void? = await withTimeLimit {
        for await _ in stream {}
    }
    return result != nil
}
