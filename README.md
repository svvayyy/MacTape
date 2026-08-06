# ClipTape

ClipTape is a free, native, open-source screen recorder for macOS with system audio, optional microphone capture, and local MP4 output.

Press record. Do the thing. Press stop. Get the file.

Website: <https://svvayyy.github.io/ClipTape/> (source in [`docs/`](docs))

Guides:

- [How to record your Mac screen with system audio](https://svvayyy.github.io/ClipTape/record-mac-screen-with-system-audio.html)
- [Open-source macOS screen recorders compared](https://svvayyy.github.io/ClipTape/open-source-macos-screen-recorders.html)

## Install

[![Download on the Mac App Store](docs/assets/mac-app-store-badge.svg)](https://apps.apple.com/us/app/cliptape-screen-recorder/id6795628398)

ClipTape is free and requires macOS 15 or newer.

Prefer a direct download? The signed and Apple-notarized [ClipTape 0.1.0 beta 2 disk image](https://github.com/svvayyy/ClipTape/releases/download/v0.1.0-beta.2/ClipTape-0.1.0.dmg) remains available as an alternative. Open the disk image, drag ClipTape into Applications, then launch it from there. The direct-download beta does not update through the App Store.

## Product

ClipTape records a display or window with optional system audio and microphone input. It also captures screenshots. Recordings stay on the Mac and finish as ordinary MP4 files.

ClipTape has no account, cloud service, editor, AI, analytics, telemetry, or hidden network activity.

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

ClipTape requires macOS 15 or newer because it uses modern ScreenCaptureKit recording and microphone capture APIs.

## Current status

ClipTape 1.0 is available free on the Mac App Store. The current release includes:

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
4. Open `ClipTape.xcodeproj`.
5. Build and run the ClipTape scheme.

ClipTape asks for Screen Recording permission when capture access is needed. Microphone permission is requested only when microphone recording is enabled.

## Privacy

See [PRIVACY.md](PRIVACY.md). The short version is simple: recordings stay on the Mac.

## License

ClipTape is available under the MIT License.
