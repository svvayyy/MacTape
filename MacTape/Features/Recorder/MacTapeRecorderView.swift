import SwiftUI

struct MacTapeRecorderView: View {
    @Environment(MacTapeAppModel.self) private var appModel
    @State private var isCancelConfirmationPresented = false

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, MacTapeSpacing.large)
                .padding(.vertical, MacTapeSpacing.medium)

            Divider()

            Group {
                switch appModel.recordingState {
                case .recording, .pausing, .paused, .resuming:
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
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task {
                await appModel.applicationDidBecomeActive()
            }
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: MacTapeSpacing.small) {
                MacTapeLogo()

                Text("Mac*Tape*")
                    .macTapeText(.title)
            }

            Spacer()

            HStack(spacing: MacTapeSpacing.small) {
                MacTapeStatusPill(
                    title: appModel.statusTitle,
                    color: statusColor,
                    pulses: appModel.recordingState.isRecording
                )

                Button {
                    quitMacTape()
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MacTapeColor.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(.quaternary.opacity(0.7), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isSessionTransitioning)
                .help(appModel.hasActiveRecordingSession ? "Finish and quit MacTape" : "Quit MacTape")
                .accessibilityLabel("Quit MacTape")
            }
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
                    VStack(spacing: MacTapeSpacing.medium) {
                        MacTapeTargetPicker()

                        Divider()

                        MacTapeResolutionPicker()
                    }
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
                            systemImageName: "speaker.wave.2.fill",
                            isEnabled: appModel.isSystemAudioEnabled
                        ) {
                            appModel.isSystemAudioEnabled.toggle()
                        }

                        Divider()

                        MacTapeSourceToggle(
                            title: "Microphone",
                            subtitle: "Your selected input",
                            systemImageName: "mic.fill",
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

            HStack(spacing: MacTapeSpacing.small) {
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

                Button {
                    Task {
                        await appModel.takeScreenshot()
                    }
                } label: {
                    HStack(spacing: MacTapeSpacing.small) {
                        if appModel.isTakingScreenshot {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "camera.fill")
                                .symbolRenderingMode(.hierarchical)
                        }

                        Text(appModel.isTakingScreenshot ? "Saving" : "Shot")
                    }
                }
                .buttonStyle(MacTapeSecondaryButtonStyle())
                .frame(width: 112)
                .disabled(!appModel.canTakeScreenshot)
                .help("Take a screenshot")
                .accessibilityLabel("Take screenshot")
            }

            if let lastOutputURL = appModel.lastOutputURL {
                Button("Reveal \(lastOutputURL.lastPathComponent) in Finder") {
                    appModel.revealLastOutput()
                }
                .buttonStyle(.link)
                .macTapeText(.detail)
                .lineLimit(1)
            }
        }
    }

    private var recordingContent: some View {
        VStack(spacing: MacTapeSpacing.xLarge) {
            if let message = appModel.recordingErrorMessage {
                recordingSessionError(message)
            }

            VStack(spacing: MacTapeSpacing.medium) {
                ZStack {
                    Circle()
                        .fill(MacTapeColor.recording.opacity(0.12))
                        .frame(width: 72, height: 72)

                    if appModel.recordingState.isPaused {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(MacTapeColor.recording)
                    } else {
                        MacTapeLogo(width: 36)
                    }
                }
                .accessibilityHidden(true)

                Text(appModel.durationText)
                    .macTapeText(.timer)
                    .contentTransition(.numericText())
                    .accessibilityLabel("Recording duration \(appModel.durationText)")

                Text(appModel.recordingTargetTitle)
                    .macTapeText(.detail)
                    .lineLimit(1)

                if appModel.recordingState.isPaused {
                    Text("Paused")
                        .macTapeText(.section)
                        .foregroundStyle(MacTapeColor.recording)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MacTapeSpacing.large)

            HStack(spacing: MacTapeSpacing.small) {
                Button {
                    Task {
                        await appModel.togglePause()
                    }
                } label: {
                    HStack(spacing: MacTapeSpacing.small) {
                        if appModel.recordingState == .pausing
                            || appModel.recordingState == .resuming {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(
                                systemName: appModel.recordingState.isPaused
                                    ? "play.fill"
                                    : "pause.fill"
                            )
                        }

                        Text(pauseButtonTitle)
                    }
                }
                .buttonStyle(MacTapeSecondaryButtonStyle())
                .disabled(
                    appModel.recordingState == .pausing
                        || appModel.recordingState == .resuming
                )

                Button {
                    Task {
                        await appModel.stopRecording()
                    }
                } label: {
                    HStack(spacing: MacTapeSpacing.small) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white)
                            .frame(width: 10, height: 10)

                        Text("Stop")
                    }
                }
                .buttonStyle(MacTapeRecordingButtonStyle(role: .stop))
                .disabled(
                    appModel.recordingState == .pausing
                        || appModel.recordingState == .resuming
                )
                .keyboardShortcut(.escape, modifiers: [])
            }

            Button("Cancel Recording", role: .destructive) {
                isCancelConfirmationPresented = true
            }
            .buttonStyle(.plain)
            .macTapeText(.detail)
            .foregroundStyle(MacTapeColor.recording)
            .disabled(
                appModel.recordingState == .pausing
                    || appModel.recordingState == .resuming
            )
            .alert("Discard this recording?", isPresented: $isCancelConfirmationPresented) {
                Button("Keep Recording", role: .cancel) {}
                Button("Discard", role: .destructive) {
                    Task {
                        await appModel.cancelRecording()
                    }
                }
            } message: {
                Text("MacTape will delete every recorded segment.")
            }
        }
    }

    private var pauseButtonTitle: String {
        switch appModel.recordingState {
        case .pausing:
            "Pausing"
        case .paused:
            "Resume"
        case .resuming:
            "Resuming"
        default:
            "Pause"
        }
    }

    private func quitMacTape() {
        Task {
            if appModel.hasActiveRecordingSession {
                await appModel.stopRecording()
            }

            guard
                !appModel.hasActiveRecordingSession,
                !appModel.recordingState.isBusy
            else {
                return
            }

            NSApplication.shared.terminate(nil)
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
            Image(systemName: permissionSymbolName)
                .font(.system(size: 30, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(MacTapeColor.textSecondary)

            VStack(spacing: MacTapeSpacing.small) {
                Text(permissionTitle)
                    .macTapeText(.body)

                Text(permissionDetail)
                    .macTapeText(.detail)
                    .multilineTextAlignment(.center)
            }

            if appModel.isRefreshingTargets {
                ProgressView()
                    .controlSize(.small)
            } else {
                Button(appModel.screenPermissionGranted ? "Try Again" : "Allow Screen Access") {
                    Task {
                        await appModel.refreshTargets(
                            requestPermission: !appModel.screenPermissionGranted
                        )
                    }
                }
                .buttonStyle(.borderedProminent)

                if !appModel.screenPermissionGranted {
                    Button("Open System Settings") {
                        appModel.openPrivacySettings()
                    }
                    .buttonStyle(.link)
                    .macTapeText(.detail)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MacTapeSpacing.xLarge)
    }

    private var permissionSymbolName: String {
        if appModel.isRefreshingTargets || appModel.screenPermissionGranted {
            "display"
        } else {
            "rectangle.inset.filled.and.person.filled"
        }
    }

    private var permissionTitle: String {
        if appModel.isRefreshingTargets {
            "Finding screens and windows"
        } else if appModel.screenPermissionGranted {
            "Capture choices are unavailable"
        } else {
            "Screen access is needed"
        }
    }

    private var permissionDetail: String {
        if appModel.isRefreshingTargets {
            "MacTape is preparing your capture choices."
        } else if appModel.screenPermissionGranted {
            "MacTape still has screen access. Try refreshing the available screens and windows."
        } else {
            "MacTape only sees a screen or window while you choose to record it."
        }
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

    private func recordingSessionError(_ message: String) -> some View {
        HStack(alignment: .top, spacing: MacTapeSpacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(MacTapeColor.warning)

            Text(message)
                .macTapeText(.detail)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(MacTapeSpacing.medium)
        .background(
            MacTapeColor.warning.opacity(0.09),
            in: .rect(cornerRadius: MacTapeRadius.medium)
        )
    }

    private var statusColor: Color {
        switch appModel.recordingState {
        case .idle:
            appModel.screenPermissionGranted ? MacTapeColor.success : MacTapeColor.warning
        case .preparing, .pausing, .paused, .resuming, .stopping:
            MacTapeColor.warning
        case .recording:
            MacTapeColor.recording
        case .failed:
            MacTapeColor.warning
        }
    }

    private var isSessionTransitioning: Bool {
        switch appModel.recordingState {
        case .preparing, .pausing, .resuming, .stopping:
            true
        default:
            false
        }
    }
}
