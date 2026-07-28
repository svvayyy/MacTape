# MacTape

MacTape is a focused, open-source screen recorder for macOS.

Press record. Do the thing. Press stop. Get the file.

Website: <https://svvayyy.github.io/MacTape/> (source in [`docs/`](docs))

## Product

MacTape records a display or window with optional system audio and microphone input. It also captures screenshots. Recordings stay on the Mac and finish as ordinary MP4 files.

MacTape has no account, cloud service, editor, AI, analytics, telemetry, or hidden network activity.

## Features

- Record a display or individual window from the menu bar
- Capture system audio and optional microphone input
- Choose Original, 4K, 1440p, 1080p, or 720p output
- Pause and resume without including the paused gap
- Cancel a recording without leaving temporary files behind
- Capture local PNG screenshots at the selected resolution
- Choose a local save folder
- Produce ordinary H.264 MP4 files
- Work entirely on-device with no account or network service

MacTape requires macOS 15 or newer because it uses modern ScreenCaptureKit recording and microphone capture APIs.

## Current status

MacTape is preparing for its first public beta. The current build includes:

- Native SwiftUI menu bar operation
- Display and window discovery
- System audio recording
- Optional microphone recording
- Original, 4K, 1440p, 1080p, and 720p output options
- Pause and resume without including paused time
- Recording cancellation with temporary-file cleanup
- Local PNG screenshots
- H.264 MP4 output
- A configurable local save folder
- Clear idle, preparing, paused, recording, stopping, and error states

## Build

1. Install Xcode 26 or newer.
2. Install XcodeGen.
3. Run `xcodegen generate`.
4. Open `MacTape.xcodeproj`.
5. Build and run the MacTape scheme.

MacTape asks for Screen Recording permission when capture access is needed. Microphone permission is requested only when microphone recording is enabled.

## Privacy

See [PRIVACY.md](PRIVACY.md). The short version is simple: recordings stay on the Mac.

## License

MacTape is available under the MIT License.
