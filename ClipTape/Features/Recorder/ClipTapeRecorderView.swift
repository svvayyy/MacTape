import SwiftUI

struct ClipTapeRecorderView: View {
    @Environment(ClipTapeAppModel.self) private var appModel
    @State private var isCancelConfirmationPresented = false

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, ClipTapeSpacing.large)
                .padding(.vertical, ClipTapeSpacing.medium)

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
            .padding(ClipTapeSpacing.large)
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
        .onDisappear {
            isCancelConfirmationPresented = false
        }
        .onChange(of: appModel.recordingState) { _, recordingState in
            if !recordingState.hasActiveSession {
                isCancelConfirmationPresented = false
            }
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: ClipTapeSpacing.small) {
                ClipTapeLogo()

                Text("Clip*Tape*")
                    .clipTapeText(.title)
            }

            Spacer()

            HStack(spacing: ClipTapeSpacing.small) {
                ClipTapeStatusPill(
                    title: appModel.statusTitle,
                    color: statusColor,
                    pulses: appModel.recordingState.isRecording
                )

                Button {
                    quitClipTape()
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(ClipTapeColor.textSecondary)
                        .frame(width: 24, height: 24)
                        .background(.quaternary.opacity(0.7), in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(isSessionTransitioning)
                .help(appModel.hasActiveRecordingSession ? "Finish and quit ClipTape" : "Quit ClipTape")
                .accessibilityLabel("Quit ClipTape")
            }
        }
    }

    private var setupContent: some View {
        VStack(spacing: ClipTapeSpacing.large) {
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
        VStack(spacing: ClipTapeSpacing.large) {
            VStack(alignment: .leading, spacing: ClipTapeSpacing.small) {
                Text("CAPTURE")
                    .clipTapeText(.section)

                ClipTapeSurface {
                    VStack(spacing: ClipTapeSpacing.medium) {
                        ClipTapeTargetPicker()

                        Divider()

                        ClipTapeResolutionPicker()
                    }
                }
            }

            VStack(alignment: .leading, spacing: ClipTapeSpacing.small) {
                Text("AUDIO")
                    .clipTapeText(.section)

                ClipTapeSurface {
                    VStack(spacing: ClipTapeSpacing.medium) {
                        ClipTapeSourceToggle(
                            title: "System audio",
                            subtitle: "Sound from your Mac",
                            systemImageName: "speaker.wave.2.fill",
                            isEnabled: appModel.isSystemAudioEnabled
                        ) {
                            appModel.isSystemAudioEnabled.toggle()
                        }

                        Divider()

                        ClipTapeSourceToggle(
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

            VStack(alignment: .leading, spacing: ClipTapeSpacing.small) {
                Text("SAVE TO")
                    .clipTapeText(.section)

                Button {
                    appModel.chooseSaveDirectory()
                } label: {
                    ClipTapeSurface {
                        HStack(spacing: ClipTapeSpacing.medium) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 14, weight: .medium))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(ClipTapeColor.textSecondary)
                                .frame(width: 20)

                            Text(appModel.saveDirectoryLabel)
                                .clipTapeText(.body)
                                .foregroundStyle(ClipTapeColor.textPrimary)
                                .lineLimit(1)

                            Spacer()

                            Text("Choose")
                                .clipTapeText(.detail)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Save folder")
                .accessibilityValue(appModel.saveDirectory?.path ?? "No folder selected")
            }

            HStack(spacing: ClipTapeSpacing.small) {
                Button {
                    Task {
                        await appModel.startRecording()
                    }
                } label: {
                    HStack(spacing: ClipTapeSpacing.small) {
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
                .buttonStyle(ClipTapeRecordingButtonStyle(role: .record))
                .disabled(!appModel.canStartRecording)

                Button {
                    Task {
                        await appModel.takeScreenshot()
                    }
                } label: {
                    HStack(spacing: ClipTapeSpacing.small) {
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
                .buttonStyle(ClipTapeSecondaryButtonStyle())
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
                .clipTapeText(.detail)
                .lineLimit(1)
            }
        }
    }

    private var recordingContent: some View {
        VStack(spacing: ClipTapeSpacing.xLarge) {
            if let message = appModel.recordingErrorMessage {
                recordingSessionError(message)
            }

            VStack(spacing: ClipTapeSpacing.medium) {
                ZStack {
                    Circle()
                        .fill(ClipTapeColor.recording.opacity(0.12))
                        .frame(width: 72, height: 72)

                    if appModel.recordingState.isPaused {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(ClipTapeColor.recording)
                    } else {
                        ClipTapeLogo(width: 36)
                    }
                }
                .accessibilityHidden(true)

                Text(appModel.durationText)
                    .clipTapeText(.timer)
                    .contentTransition(.numericText())
                    .accessibilityLabel("Recording duration \(appModel.durationText)")

                Text(appModel.recordingTargetTitle)
                    .clipTapeText(.detail)
                    .lineLimit(1)

                if appModel.recordingState.isPaused {
                    Text("Paused")
                        .clipTapeText(.section)
                        .foregroundStyle(ClipTapeColor.recording)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ClipTapeSpacing.large)

            Group {
                if isCancelConfirmationPresented {
                    cancelRecordingConfirmation
                } else {
                    recordingControls
                }
            }
            .animation(ClipTapeMotion.snappy, value: isCancelConfirmationPresented)
        }
    }

    private var recordingControls: some View {
        VStack(spacing: ClipTapeSpacing.xLarge) {
            HStack(spacing: ClipTapeSpacing.small) {
                Button {
                    Task {
                        await appModel.togglePause()
                    }
                } label: {
                    HStack(spacing: ClipTapeSpacing.small) {
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
                .buttonStyle(ClipTapeSecondaryButtonStyle())
                .disabled(isRecordingTransitioning)

                Button {
                    Task {
                        await appModel.stopRecording()
                    }
                } label: {
                    HStack(spacing: ClipTapeSpacing.small) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white)
                            .frame(width: 10, height: 10)

                        Text("Stop")
                    }
                }
                .buttonStyle(ClipTapeRecordingButtonStyle(role: .stop))
                .disabled(isRecordingTransitioning)
                .keyboardShortcut(.escape, modifiers: [])
            }

            Button("Cancel Recording", role: .destructive) {
                isCancelConfirmationPresented = true
            }
            .buttonStyle(.plain)
            .clipTapeText(.detail)
            .foregroundStyle(ClipTapeColor.recording)
            .disabled(isRecordingTransitioning)
        }
    }

    private var cancelRecordingConfirmation: some View {
        ClipTapeSurface {
            VStack(alignment: .leading, spacing: ClipTapeSpacing.medium) {
                HStack(alignment: .top, spacing: ClipTapeSpacing.medium) {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(ClipTapeColor.recording)

                    VStack(alignment: .leading, spacing: ClipTapeSpacing.xSmall) {
                        Text("Discard this recording?")
                            .clipTapeText(.body)

                        Text("ClipTape will delete every recorded segment.")
                            .clipTapeText(.detail)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: ClipTapeSpacing.small) {
                    Button("Keep Recording") {
                        isCancelConfirmationPresented = false
                    }
                    .buttonStyle(ClipTapeSecondaryButtonStyle())
                    .keyboardShortcut(.cancelAction)

                    Button("Discard", role: .destructive) {
                        Task {
                            await appModel.cancelRecording()
                        }
                    }
                    .buttonStyle(ClipTapeRecordingButtonStyle(role: .stop))
                }
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    private var isRecordingTransitioning: Bool {
        appModel.recordingState == .pausing
            || appModel.recordingState == .resuming
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

    private func quitClipTape() {
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
        VStack(spacing: ClipTapeSpacing.large) {
            ProgressView()
                .controlSize(.large)

            VStack(spacing: ClipTapeSpacing.small) {
                Text("Finishing your recording")
                    .clipTapeText(.body)

                Text("ClipTape is writing the MP4 safely.")
                    .clipTapeText(.detail)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ClipTapeSpacing.xxLarge)
    }

    private var permissionOrLoadingView: some View {
        VStack(spacing: ClipTapeSpacing.large) {
            Image(systemName: permissionSymbolName)
                .font(.system(size: 30, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(ClipTapeColor.textSecondary)

            VStack(spacing: ClipTapeSpacing.small) {
                Text(permissionTitle)
                    .clipTapeText(.body)

                Text(permissionDetail)
                    .clipTapeText(.detail)
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
                    .clipTapeText(.detail)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ClipTapeSpacing.xLarge)
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
            "ClipTape is preparing your capture choices."
        } else if appModel.screenPermissionGranted {
            "ClipTape still has screen access. Try refreshing the available screens and windows."
        } else {
            "ClipTape only sees a screen or window while you choose to record it."
        }
    }

    private func errorView(_ message: String) -> some View {
        HStack(alignment: .top, spacing: ClipTapeSpacing.medium) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ClipTapeColor.warning)

            VStack(alignment: .leading, spacing: ClipTapeSpacing.xSmall) {
                Text("ClipTape could not continue")
                    .clipTapeText(.body)

                Text(message)
                    .clipTapeText(.detail)
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
        .padding(ClipTapeSpacing.medium)
        .background(ClipTapeColor.warning.opacity(0.09), in: .rect(cornerRadius: ClipTapeRadius.medium))
    }

    private func recordingSessionError(_ message: String) -> some View {
        HStack(alignment: .top, spacing: ClipTapeSpacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ClipTapeColor.warning)

            Text(message)
                .clipTapeText(.detail)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(ClipTapeSpacing.medium)
        .background(
            ClipTapeColor.warning.opacity(0.09),
            in: .rect(cornerRadius: ClipTapeRadius.medium)
        )
    }

    private var statusColor: Color {
        switch appModel.recordingState {
        case .idle:
            appModel.screenPermissionGranted ? ClipTapeColor.success : ClipTapeColor.warning
        case .preparing, .pausing, .paused, .resuming, .stopping:
            ClipTapeColor.warning
        case .recording:
            ClipTapeColor.recording
        case .failed:
            ClipTapeColor.warning
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
