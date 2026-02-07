# 🖥️ swift-desktopia

Control your [Desktopia Pro X](https://www.ergotopia.de/ergonomie-shop/hoehenverstellbarer-schreibtisch/desktopia-pro-elektrisch-memoryschalter) from Swift.

## 🚀 Getting Started

Add `swift-desktopia` as a dependency to your `Package.swift`:

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        // other dependencies
        .package(url: "https://github.com/sgade/swift-desktopia", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(name: "<command-line-tool>", dependencies: [
            // other dependencies
            .product(name: "DesktopiaProX", package: "swift-desktopia"),
        ]),
        // other targets
    ]
)
```

## 🎯 Connecting to the desk

Connect your device to the desk controller via the USB connection, and then find the device name for that connection.
Since it is a serial connection, you will need to find the corresponding device on your file system.

On macOS, these devices are usually called something like `/dev/cu.usbserial-X`, where `X` is a number.

With that device name, you can create a connection to the desk:

```swift
import DesktopiaProX

let desk = Desk(port: "/dev/cu.usbserial-123", keepAlive: true)
try await desk.connect()
```

The connection to the desk is in both ways, so you can send commands and the desk can send commands on its own. 

## 🤓 Reading commands from the desk

You can get a stream of commands to read:

```swift
Task {
    let stream = try await desk.readCommands()

    for await command in stream {
        // interpret command...
    }
}
```

## ✨ Sending commands to the desk

To send commands to the desk, all you need to do is:

```swift
try await desk.send(command: .showStatus)
```

## 📜 The Desktopia Pro X protocol

The protocol has been [reverse engineered](https://www.sgade.de/blog/2023-07-13-desktopia-prox-smartcontrol/) from the [official app (beta)](https://www.ergotopia.de/desktopia-app).
Contributions and corrections are welcome.

# License

See [LICENSE](./LICENSE).
