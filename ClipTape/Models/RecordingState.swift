enum RecordingState: Equatable {
    case idle
    case preparing
    case recording
    case pausing
    case paused
    case resuming
    case stopping
    case failed(String)

    var isBusy: Bool {
        switch self {
        case .preparing, .recording, .pausing, .resuming, .stopping:
            true
        case .idle, .paused, .failed:
            false
        }
    }

    var isRecording: Bool {
        self == .recording
    }

    var isPaused: Bool {
        self == .paused
    }

    var hasActiveSession: Bool {
        switch self {
        case .recording, .pausing, .paused, .resuming, .stopping:
            true
        case .idle, .preparing, .failed:
            false
        }
    }
}
