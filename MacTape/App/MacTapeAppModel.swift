import AppKit
import AVFoundation
import Observation
import ScreenCaptureKit

@Observable
@MainActor
final class MacTapeAppModel {
    private enum PreferenceKey {
        static let systemAudio = "systemAudio"
        static let microphone = "microphone"
        static let saveDirectory = "saveDirectory"
    }

    var recordingState: RecordingState = .idle
    var captureTargets: [CaptureTarget] = []
    var selectedTargetID: String?
    var isSystemAudioEnabled: Bool {
        didSet {
            preferences.set(isSystemAudioEnabled, forKey: PreferenceKey.systemAudio)
        }
    }
    var isMicrophoneEnabled: Bool {
        didSet {
            preferences.set(isMicrophoneEnabled, forKey: PreferenceKey.microphone)
        }
    }
    var saveDirectory: URL
    var elapsedTime: TimeInterval = 0
    var lastRecordingURL: URL?
    var isRefreshingTargets = false
    var screenPermissionGranted = CGPreflightScreenCaptureAccess()

    private let preferences: UserDefaults
    private var currentApplication: SCRunningApplication?
    private var recorder: CaptureRecorder?
    private var recordingStartedAt: Date?
    private var durationTask: Task<Void, Never>?

    init(
        preferences: UserDefaults = .standard,
        fileManager: FileManager = .default
    ) {
        self.preferences = preferences

        if preferences.object(forKey: PreferenceKey.systemAudio) == nil {
            isSystemAudioEnabled = true
        } else {
            isSystemAudioEnabled = preferences.bool(forKey: PreferenceKey.systemAudio)
        }

        isMicrophoneEnabled = preferences.bool(forKey: PreferenceKey.microphone)

        if let storedPath = preferences.string(forKey: PreferenceKey.saveDirectory) {
            saveDirectory = URL(fileURLWithPath: storedPath, isDirectory: true)
        } else {
            let movies = fileManager.urls(for: .moviesDirectory, in: .userDomainMask).first
                ?? fileManager.homeDirectoryForCurrentUser
            saveDirectory = movies.appendingPathComponent("MacTape", isDirectory: true)
        }
    }

    var selectedTarget: CaptureTarget? {
        captureTargets.first { $0.id == selectedTargetID }
    }

    var statusTitle: String {
        switch recordingState {
        case .idle:
            screenPermissionGranted ? "Ready" : "Setup needed"
        case .preparing:
            "Preparing"
        case .recording:
            "Recording"
        case .stopping:
            "Finishing"
        case .failed:
            "Needs attention"
        }
    }

    var durationText: String {
        RecordingDurationFormatter.string(for: elapsedTime)
    }

    var canStartRecording: Bool {
        selectedTarget != nil && recordingState == .idle
    }

    func prepare() async {
        await refreshTargets()
    }

    func refreshTargets(requestPermission: Bool = false) async {
        guard !recordingState.isBusy else {
            return
        }

        if requestPermission {
            screenPermissionGranted = CGRequestScreenCaptureAccess()
        } else {
            screenPermissionGranted = CGPreflightScreenCaptureAccess()
        }

        guard screenPermissionGranted else {
            captureTargets = []
            currentApplication = nil

            if case .failed = recordingState {
                recordingState = .idle
            }

            return
        }

        isRefreshingTargets = true

        defer {
            isRefreshingTargets = false
        }

        do {
            let snapshot = try await CaptureCatalog.load()
            captureTargets = snapshot.targets
            currentApplication = snapshot.currentApplication
            screenPermissionGranted = true

            if selectedTarget == nil {
                selectedTargetID = captureTargets.first?.id
            }

            if case .failed = recordingState {
                recordingState = .idle
            }
        } catch {
            captureTargets = []
            recordingState = .failed(error.localizedDescription)
        }
    }

    func setMicrophoneEnabled(_ enabled: Bool) async {
        guard enabled else {
            isMicrophoneEnabled = false
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            isMicrophoneEnabled = true
        case .notDetermined:
            isMicrophoneEnabled = await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            isMicrophoneEnabled = false
            recordingState = .failed("Allow microphone access in System Settings to include your microphone.")
        @unknown default:
            isMicrophoneEnabled = false
        }
    }

    func chooseSaveDirectory() {
        let panel = NSOpenPanel()
        panel.title = "Choose where MacTape saves recordings"
        panel.prompt = "Choose"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = saveDirectory

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            return
        }

        saveDirectory = selectedURL
        preferences.set(selectedURL.path, forKey: PreferenceKey.saveDirectory)
    }

    func toggleRecording() async {
        if recordingState.isRecording {
            await stopRecording()
        } else {
            await startRecording()
        }
    }

    func startRecording() async {
        guard let selectedTarget, recordingState == .idle else {
            return
        }

        if isMicrophoneEnabled {
            await setMicrophoneEnabled(true)

            guard isMicrophoneEnabled else {
                return
            }
        }

        recordingState = .preparing
        elapsedTime = 0

        do {
            try FileManager.default.createDirectory(
                at: saveDirectory,
                withIntermediateDirectories: true
            )

            let outputURL = RecordingFileNamer.availableURL(in: saveDirectory)
            let recorder = CaptureRecorder()
            recorder.onFailure = { [weak self] error in
                self?.handleCaptureFailure(error)
            }
            self.recorder = recorder

            try await recorder.start(
                target: selectedTarget,
                excluding: currentApplication,
                systemAudio: isSystemAudioEnabled,
                microphone: isMicrophoneEnabled,
                outputURL: outputURL
            )

            recordingState = .recording
            recordingStartedAt = Date()
            startDurationUpdates()
        } catch {
            recorder = nil
            recordingState = .failed(error.localizedDescription)
        }
    }

    func stopRecording() async {
        guard let recorder, recordingState == .recording else {
            return
        }

        recordingState = .stopping
        stopDurationUpdates()

        do {
            let outputURL = try await recorder.stop()
            self.recorder = nil
            lastRecordingURL = outputURL
            recordingState = .idle
            NSWorkspace.shared.activateFileViewerSelecting([outputURL])
        } catch {
            self.recorder = nil
            recordingState = .failed(error.localizedDescription)
        }
    }

    func dismissError() {
        if case .failed = recordingState {
            recordingState = .idle
        }
    }

    func revealLastRecording() {
        guard let lastRecordingURL else {
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([lastRecordingURL])
    }

    func openPrivacySettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        ) else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    private func startDurationUpdates() {
        durationTask?.cancel()
        durationTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))

                guard let self, let recordingStartedAt = self.recordingStartedAt else {
                    return
                }

                self.elapsedTime = Date().timeIntervalSince(recordingStartedAt)
            }
        }
    }

    private func stopDurationUpdates() {
        durationTask?.cancel()
        durationTask = nil

        if let recordingStartedAt {
            elapsedTime = Date().timeIntervalSince(recordingStartedAt)
        }

        recordingStartedAt = nil
    }

    private func handleCaptureFailure(_ error: Error) {
        stopDurationUpdates()
        recorder = nil
        recordingState = .failed(error.localizedDescription)
    }
}
