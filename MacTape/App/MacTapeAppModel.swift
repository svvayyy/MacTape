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
        static let saveDirectoryBookmark = "saveDirectoryBookmark"
        static let outputResolution = "outputResolution"
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
    var outputResolution: CaptureResolution {
        didSet {
            preferences.set(outputResolution.rawValue, forKey: PreferenceKey.outputResolution)
        }
    }
    var saveDirectory: URL?
    var elapsedTime: TimeInterval = 0
    var lastOutputURL: URL?
    var isRefreshingTargets = false
    var isTakingScreenshot = false
    var screenPermissionGranted: Bool
    var recordingErrorMessage: String?

    private let preferences: UserDefaults
    private let screenAccessPreflight: () -> Bool
    private let screenAccessRequest: () -> Bool
    private let captureCatalogLoader: () async throws -> CaptureCatalog.Snapshot
    private let suggestedSaveDirectory: URL
    private var currentApplication: SCRunningApplication?
    private var recorder: CaptureRecorder?
    private var recordingSession: RecordingSessionFiles?
    private var hasPreparedCaptureTargets = false
    private var isWaitingForScreenAccessChange = false
    private var activeCaptureTarget: CaptureTarget?
    private var activeApplication: SCRunningApplication?
    private var activeSystemAudioEnabled = false
    private var activeMicrophoneEnabled = false
    private var activeResolution: CaptureResolution = .source
    private var recordingStartedAt: Date?
    private var elapsedTimeAtRecordingStart: TimeInterval = 0
    private var durationTask: Task<Void, Never>?
    private var saveDirectoryAccess: PersistentDirectoryAccess?

    init(
        preferences: UserDefaults = .standard,
        fileManager: FileManager = .default,
        screenAccessPreflight: @escaping () -> Bool = CGPreflightScreenCaptureAccess,
        screenAccessRequest: @escaping () -> Bool = CGRequestScreenCaptureAccess,
        captureCatalogLoader: @escaping () async throws -> CaptureCatalog.Snapshot = {
            try await CaptureCatalog.load()
        }
    ) {
        self.preferences = preferences
        self.screenAccessPreflight = screenAccessPreflight
        self.screenAccessRequest = screenAccessRequest
        self.captureCatalogLoader = captureCatalogLoader
        suggestedSaveDirectory = fileManager.urls(for: .moviesDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser
        screenPermissionGranted = screenAccessPreflight()

        if preferences.object(forKey: PreferenceKey.systemAudio) == nil {
            isSystemAudioEnabled = true
        } else {
            isSystemAudioEnabled = preferences.bool(forKey: PreferenceKey.systemAudio)
        }

        isMicrophoneEnabled = preferences.bool(forKey: PreferenceKey.microphone)
        outputResolution = preferences
            .string(forKey: PreferenceKey.outputResolution)
            .flatMap(CaptureResolution.init(rawValue:)) ?? .source

        if
            let bookmarkData = preferences.data(forKey: PreferenceKey.saveDirectoryBookmark),
            let access = try? PersistentDirectoryAccess(bookmarkData: bookmarkData)
        {
            saveDirectoryAccess = access
            saveDirectory = access.url
            preferences.set(
                access.bookmarkData,
                forKey: PreferenceKey.saveDirectoryBookmark
            )
        } else {
            saveDirectory = nil
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
        case .pausing:
            "Pausing"
        case .paused:
            "Paused"
        case .resuming:
            "Resuming"
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
        selectedTarget != nil && recordingState == .idle && !isTakingScreenshot
    }

    var canTakeScreenshot: Bool {
        selectedTarget != nil && recordingState == .idle && !isTakingScreenshot
    }

    var hasActiveRecordingSession: Bool {
        recordingSession != nil
    }

    var recordingTargetTitle: String {
        activeCaptureTarget?.title ?? selectedTarget?.title ?? "Recording"
    }

    var saveDirectoryLabel: String {
        saveDirectory?.lastPathComponent ?? "Choose Folder…"
    }

    func prepare() async {
        guard !hasPreparedCaptureTargets else {
            return
        }

        hasPreparedCaptureTargets = true
        await refreshTargets()
    }

    func refreshTargets(requestPermission: Bool = false) async {
        guard !recordingState.isBusy, !isRefreshingTargets else {
            return
        }

        let hadConfirmedAccess = screenPermissionGranted
        let preflightGranted = screenAccessPreflight()
        screenPermissionGranted = hadConfirmedAccess || preflightGranted

        if requestPermission && !screenPermissionGranted {
            isWaitingForScreenAccessChange = true
            screenPermissionGranted = screenAccessRequest() || screenAccessPreflight()
        }

        guard screenPermissionGranted else {
            captureTargets = []
            currentApplication = nil
            return
        }

        isRefreshingTargets = true

        defer {
            isRefreshingTargets = false
        }

        do {
            let snapshot = try await captureCatalogLoader()
            captureTargets = snapshot.targets
            currentApplication = snapshot.currentApplication
            screenPermissionGranted = true
            isWaitingForScreenAccessChange = false

            if selectedTarget == nil {
                selectedTargetID = captureTargets.first?.id
            }

            if case .failed = recordingState {
                recordingState = .idle
            }
        } catch {
            if hadConfirmedAccess && !requestPermission {
                return
            }

            captureTargets = []
            currentApplication = nil
            screenPermissionGranted = hadConfirmedAccess || preflightGranted
            recordingState = .failed(error.localizedDescription)
        }
    }

    func applicationDidBecomeActive() async {
        guard isWaitingForScreenAccessChange, screenAccessPreflight() else {
            return
        }

        screenPermissionGranted = true
        await refreshTargets()
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

    @discardableResult
    func chooseSaveDirectory() -> Bool {
        let panel = NSOpenPanel()
        panel.title = "Choose where MacTape saves recordings"
        panel.prompt = "Choose"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = saveDirectory ?? suggestedSaveDirectory

        guard panel.runModal() == .OK, let selectedURL = panel.url else {
            return false
        }

        do {
            let access = try PersistentDirectoryAccess(selectedURL: selectedURL)
            saveDirectoryAccess = access
            saveDirectory = access.url
            preferences.set(access.url.path, forKey: PreferenceKey.saveDirectory)
            preferences.set(
                access.bookmarkData,
                forKey: PreferenceKey.saveDirectoryBookmark
            )
            return true
        } catch {
            recordingState = .failed(
                "MacTape could not remember access to that folder. Choose another folder and try again."
            )
            return false
        }
    }

    func toggleRecording() async {
        if hasActiveRecordingSession {
            await stopRecording()
        } else {
            await startRecording()
        }
    }

    func startRecording() async {
        guard
            let selectedTarget,
            recordingState == .idle,
            let saveDirectory = requireSaveDirectory()
        else {
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
        recordingErrorMessage = nil
        var pendingSession: RecordingSessionFiles?
        activeCaptureTarget = selectedTarget
        activeApplication = currentApplication
        activeSystemAudioEnabled = isSystemAudioEnabled
        activeMicrophoneEnabled = isMicrophoneEnabled
        activeResolution = outputResolution

        do {
            try FileManager.default.createDirectory(
                at: saveDirectory,
                withIntermediateDirectories: true
            )

            var session = try RecordingSessionFiles.create(in: saveDirectory)
            pendingSession = session
            let outputURL = session.nextSegmentURL()
            let recorder = CaptureRecorder()
            recorder.onFailure = { [weak self] error in
                self?.handleCaptureFailure(error)
            }
            self.recorder = recorder

            try await recorder.start(
                target: selectedTarget,
                excluding: activeApplication,
                systemAudio: activeSystemAudioEnabled,
                microphone: activeMicrophoneEnabled,
                resolution: activeResolution,
                outputURL: outputURL
            )

            session.appendSegment(outputURL)
            recordingSession = session
            pendingSession = nil
            recordingState = .recording
            startDurationUpdates()
        } catch {
            recorder = nil
            pendingSession?.discard()
            recordingSession = nil
            clearActiveConfiguration()
            recordingState = .failed(error.localizedDescription)
        }
    }

    func togglePause() async {
        switch recordingState {
        case .recording:
            await pauseRecording()
        case .paused:
            await resumeRecording()
        default:
            return
        }
    }

    func pauseRecording() async {
        guard let recorder, recordingState == .recording else {
            return
        }

        recordingState = .pausing
        recordingErrorMessage = nil
        stopDurationUpdates()

        do {
            _ = try await recorder.stop()
            self.recorder = nil
            recordingState = .paused
        } catch {
            self.recorder = nil
            removeFailedSegment()
            recordingErrorMessage = error.localizedDescription
            recordingState = .paused
        }
    }

    func resumeRecording() async {
        guard
            let activeCaptureTarget,
            var session = recordingSession,
            recordingState == .paused
        else {
            return
        }

        recordingState = .resuming
        recordingErrorMessage = nil
        let outputURL = session.nextSegmentURL()
        let recorder = CaptureRecorder()
        recorder.onFailure = { [weak self] error in
            self?.handleCaptureFailure(error)
        }
        self.recorder = recorder

        do {
            try await recorder.start(
                target: activeCaptureTarget,
                excluding: activeApplication,
                systemAudio: activeSystemAudioEnabled,
                microphone: activeMicrophoneEnabled,
                resolution: activeResolution,
                outputURL: outputURL
            )

            session.appendSegment(outputURL)
            recordingSession = session
            recordingState = .recording
            startDurationUpdates()
        } catch {
            self.recorder = nil
            try? FileManager.default.removeItem(at: outputURL)
            recordingErrorMessage = error.localizedDescription
            recordingState = .paused
        }
    }

    func stopRecording() async {
        guard
            let session = recordingSession,
            recordingState == .recording || recordingState == .paused
        else {
            return
        }

        recordingState = .stopping
        recordingErrorMessage = nil

        if recorder != nil {
            stopDurationUpdates()
        }

        do {
            if let recorder {
                _ = try await recorder.stop()
            }

            self.recorder = nil
            let outputURL = try await RecordingSegmentFinalizer.finalize(session)
            recordingSession = nil
            clearActiveConfiguration()
            lastOutputURL = outputURL
            recordingState = .idle
            NSWorkspace.shared.activateFileViewerSelecting([outputURL])
        } catch {
            self.recorder = nil
            recordingErrorMessage = error.localizedDescription
            recordingState = .paused
        }
    }

    func cancelRecording() async {
        guard let session = recordingSession else {
            return
        }

        recordingState = .stopping
        recordingErrorMessage = nil

        if recorder != nil {
            stopDurationUpdates()
        }

        if let recorder {
            _ = try? await recorder.stop()
        }

        self.recorder = nil
        session.discard()
        recordingSession = nil
        clearActiveConfiguration()
        elapsedTime = 0
        recordingState = .idle
    }

    func takeScreenshot() async {
        guard
            let selectedTarget,
            canTakeScreenshot,
            let saveDirectory = requireSaveDirectory()
        else {
            return
        }

        isTakingScreenshot = true

        defer {
            isTakingScreenshot = false
        }

        do {
            try FileManager.default.createDirectory(
                at: saveDirectory,
                withIntermediateDirectories: true
            )
            let outputURL = ScreenshotFileNamer.availableURL(in: saveDirectory)
            try await CaptureScreenshot.save(
                target: selectedTarget,
                excluding: currentApplication,
                resolution: outputResolution,
                outputURL: outputURL
            )
            lastOutputURL = outputURL
            NSWorkspace.shared.activateFileViewerSelecting([outputURL])
        } catch {
            recordingState = .failed(error.localizedDescription)
        }
    }

    func dismissError() {
        if case .failed = recordingState {
            recordingState = .idle
        }
    }

    func revealLastOutput() {
        guard let lastOutputURL else {
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([lastOutputURL])
    }

    func openPrivacySettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        ) else {
            return
        }

        isWaitingForScreenAccessChange = true
        NSWorkspace.shared.open(url)
    }

    private func requireSaveDirectory() -> URL? {
        if let saveDirectory, saveDirectoryAccess != nil {
            return saveDirectory
        }

        guard chooseSaveDirectory() else {
            return nil
        }

        return saveDirectory
    }

    private func startDurationUpdates() {
        durationTask?.cancel()
        recordingStartedAt = Date()
        elapsedTimeAtRecordingStart = elapsedTime
        durationTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))

                guard let self, let recordingStartedAt = self.recordingStartedAt else {
                    return
                }

                self.elapsedTime = self.elapsedTimeAtRecordingStart
                    + Date().timeIntervalSince(recordingStartedAt)
            }
        }
    }

    private func stopDurationUpdates() {
        durationTask?.cancel()
        durationTask = nil

        if let recordingStartedAt {
            elapsedTime = elapsedTimeAtRecordingStart
                + Date().timeIntervalSince(recordingStartedAt)
        }

        recordingStartedAt = nil
    }

    private func handleCaptureFailure(_ error: Error) {
        stopDurationUpdates()
        recorder = nil
        removeFailedSegment()

        if recordingSession != nil {
            recordingErrorMessage = error.localizedDescription
            recordingState = .paused
        } else {
            recordingState = .failed(error.localizedDescription)
        }
    }

    private func removeFailedSegment() {
        guard var session = recordingSession else {
            return
        }

        session.removeLastSegment()
        recordingSession = session
    }

    private func clearActiveConfiguration() {
        activeCaptureTarget = nil
        activeApplication = nil
        activeSystemAudioEnabled = false
        activeMicrophoneEnabled = false
        activeResolution = .source
    }
}
