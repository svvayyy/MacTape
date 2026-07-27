enum RecordingState: Equatable {
    case idle
    case preparing
    case recording
    case stopping
    case failed(String)

    var isBusy: Bool {
        switch self {
        case .preparing, .recording, .stopping:
            true
        case .idle, .failed:
            false
        }
    }

    var isRecording: Bool {
        self == .recording
    }
}
