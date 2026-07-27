# MacTape

MacTape is a focused screen recorder for macOS.

Press record. Do the thing. Press stop. Get the file.

## Product

MacTape records a display or window with optional system audio and microphone input. Recordings stay on the Mac and finish as ordinary MP4 files.

MacTape has no account, cloud service, editor, AI, analytics, telemetry, or hidden network activity.

## Current status

MacTape is an early open-source capture spike. The first milestone proves:

- Native SwiftUI menu bar operation
- Display and window discovery
- System audio recording
- Optional microphone recording
- H.264 MP4 output
- A configurable local save folder
- Clear idle, preparing, recording, stopping, and error states

The project currently requires macOS 15 or newer because it uses ScreenCaptureKit microphone capture and recording output APIs.

## Build

1. Install Xcode 26 or newer.
2. Install XcodeGen.
3. Run `xcodegen generate`.
4. Open `MacTape.xcodeproj`.
5. Build and run the MacTape scheme.

MacTape asks for Screen Recording permission when it first discovers capture sources. Microphone permission is requested only when microphone recording is enabled.

## Repository rules

The project rules live in [CODING_RULES.md](CODING_RULES.md). Product and interface decisions live in [CREED.md](CREED.md).

## Privacy

See [PRIVACY.md](PRIVACY.md). The short version is simple: recordings stay on the Mac.

## License

MacTape is available under the MIT License.
