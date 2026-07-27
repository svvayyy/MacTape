import SwiftUI

struct MacTapeRecorderView: View {
    @Environment(MacTapeAppModel.self) private var appModel

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, MacTapeSpacing.large)
                .padding(.vertical, MacTapeSpacing.medium)

            Divider()

            Group {
                switch appModel.recordingState {
                case .recording:
                    recordingContent
                case .stopping:
                    finishingContent
                default:
                    setupContent
                }
            }
            .padding(MacTapeSpacing.large)
        }
        .frame(width: 368)
        .background(.regularMaterial)
        .task {
            await appModel.prepare()
        }
    }

    private var header: some View {
        HStack {
            Text("MacTape")
                .macTapeText(.title)

            Spacer()

            MacTapeStatusPill(
                title: appModel.statusTitle,
                color: statusColor,
                pulses: appModel.recordingState.isRecording
            )
        }
    }

    private var setupContent: some View {
        VStack(spacing: MacTapeSpacing.large) {
            if case .failed(let message) = appModel.recordingState {
                errorView(message)
            }

            if appModel.captureTargets.isEmpty {
                permissionOrLoadingView
            } else {
                configurationView
            }
        }
    }

    private var configurationView: some View {
        VStack(spacing: MacTapeSpacing.large) {
            VStack(alignment: .leading, spacing: MacTapeSpacing.small) {
                Text("CAPTURE")
                    .macTapeText(.section)

                MacTapeSurface {
                    MacTapeTargetPicker()
                }
            }

            VStack(alignment: .leading, spacing: MacTapeSpacing.small) {
                Text("AUDIO")
                    .macTapeText(.section)

                MacTapeSurface {
                    VStack(spacing: MacTapeSpacing.medium) {
                        MacTapeSourceToggle(
                            title: "System audio",
                            subtitle: "Sound from your Mac",
                            symbolName: "speaker.wave.2.fill",
                            isEnabled: appModel.isSystemAudioEnabled
                        ) {
                            appModel.isSystemAudioEnabled.toggle()
                        }

                        Divider()

                        MacTapeSourceToggle(
                            title: "Microphone",
                            subtitle: "Your selected input",
                            symbolName: "mic.fill",
                            isEnabled: appModel.isMicrophoneEnabled
                        ) {
                            Task {
                                await appModel.setMicrophoneEnabled(!appModel.isMicrophoneEnabled)
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: MacTapeSpacing.small) {
                Text("SAVE TO")
                    .macTapeText(.section)

                Button {
                    appModel.chooseSaveDirectory()
                } label: {
                    MacTapeSurface {
                        HStack(spacing: MacTapeSpacing.medium) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 14, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(MacTapeColor.textSecondary)
                                .frame(width: 20)

                            Text(appModel.saveDirectory.lastPathComponent)
                                .macTapeText(.body)
                                .foregroundStyle(MacTapeColor.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text("Choose")
                                .macTapeText(.detail)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Save folder")
                .accessibilityValue(appModel.saveDirectory.path)
            }

            Button {
                Task {
                    await appModel.startRecording()
                }
            } label: {
                HStack(spacing: MacTapeSpacing.small) {
                    if appModel.recordingState == .preparing {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Circle()
                            .fill(.white)
                            .frame(width: 9, height: 9)
                    }

                    Text(appModel.recordingState == .preparing ? "Preparing" : "Record")
                }
            }
            .buttonStyle(MacTapeRecordingButtonStyle(role: .record))
            .disabled(!appModel.canStartRecording)

            if let lastRecordingURL = appModel.lastRecordingURL {
                Button("Reveal \(lastRecordingURL.lastPathComponent) in Finder") {
                    appModel.revealLastRecording()
                }
                .buttonStyle(.link)
                .macTapeText(.detail)
                .lineLimit(1)
            }
        }
    }

    private var recordingContent: some View {
        VStack(spacing: MacTapeSpacing.xLarge) {
            VStack(spacing: MacTapeSpacing.medium) {
                ZStack {
                    Circle()
                        .fill(MacTapeColor.recording.opacity(0.12))
                        .frame(width: 72, height: 72)

                    Circle()
                        .fill(MacTapeColor.recording)
                        .frame(width: 24, height: 24)
                }
                .accessibilityHidden(true)

                Text(appModel.durationText)
                    .macTapeText(.timer)
                    .contentTransition(.numericText())
                    .accessibilityLabel("Recording duration \(appModel.durationText)")

                Text(appModel.selectedTarget?.title ?? "Recording")
                    .macTapeText(.detail)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MacTapeSpacing.large)

            Button {
                Task {
                    await appModel.stopRecording()
                }
            } label: {
                HStack(spacing: MacTapeSpacing.small) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white)
                        .frame(width: 10, height: 10)

                    Text("Stop Recording")
                }
            }
            .buttonStyle(MacTapeRecordingButtonStyle(role: .stop))
            .keyboardShortcut(.escape, modifiers: [])
        }
    }

    private var finishingContent: some View {
        VStack(spacing: MacTapeSpacing.large) {
            ProgressView()
                .controlSize(.large)

            VStack(spacing: MacTapeSpacing.small) {
                Text("Finishing your recording")
                    .macTapeText(.body)

                Text("MacTape is writing the MP4 safely.")
                    .macTapeText(.detail)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MacTapeSpacing.xxLarge)
    }

    private var permissionOrLoadingView: some View {
        VStack(spacing: MacTapeSpacing.large) {
            Image(systemName: appModel.isRefreshingTargets ? "display" : "rectangle.inset.filled.and.person.filled")
                .font(.system(size: 30, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(MacTapeColor.textSecondary)

            VStack(spacing: MacTapeSpacing.small) {
                Text(appModel.isRefreshingTargets ? "Finding screens and windows" : "Screen access is needed")
                    .macTapeText(.body)

                Text(
                    appModel.isRefreshingTargets
                        ? "MacTape is preparing your capture choices."
                        : "MacTape only sees a screen or window while you choose to record it."
                )
                .macTapeText(.detail)
                .multilineTextAlignment(.center)
            }

            if appModel.isRefreshingTargets {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button(appModel.screenPermissionGranted ? "Try Again" : "Allow Screen Access") {
                    Task {
                        await appModel.refreshTargets(requestPermission: true)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Open System Settings") {
                    appModel.openPrivacySettings()
                }
                .buttonStyle(.link)
                .macTapeText(.detail)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MacTapeSpacing.xLarge)
    }

    private func errorView(_ message: String) -> some View {
        HStack(alignment: .top, spacing: MacTapeSpacing.medium) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(MacTapeColor.warning)

            VStack(alignment: .leading, spacing: MacTapeSpacing.xSmall) {
                Text("MacTape could not continue")
                    .macTapeText(.body)

                Text(message)
                    .macTapeText(.detail)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button {
                appModel.dismissError()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error")
        }
        .padding(MacTapeSpacing.medium)
        .background(MacTapeColor.warning.opacity(0.09), in: .rect(cornerRadius: MacTapeRadius.medium))
    }

    private var statusColor: Color {
        switch appModel.recordingState {
        case .idle:
            appModel.screenPermissionGranted ? MacTapeColor.success : MacTapeColor.warning
        case .preparing, .stopping:
            MacTapeColor.warning
        case .recording:
            MacTapeColor.recording
        case .failed:
            MacTapeColor.warning
        }
    }
}
