import SwiftUI

class CaptureSession: ObservableObject {
    @Published var capturedFrames: [CapturedFrame] = []
    @Published var state: CaptureState = .idle
    @Published var currentFrameIndex: Int = 0
    
    func addFrame(_ image: UIImage) {
        let frame = CapturedFrame(
            image: image,
            timestamp: Date(),
            index: capturedFrames.count
        )
        capturedFrames.append(frame)
        currentFrameIndex = capturedFrames.count
    }
    
    func reset() {
        capturedFrames = []
        state = .idle
        currentFrameIndex = 0
    }
}

struct CapturedFrame: Identifiable {
    let id = UUID()
    let image: UIImage
    let timestamp: Date
    let index: Int
}

enum CaptureState {
    case idle, preparing, capturing, processing, complete
    
    var description: String {
        switch self {
        case .idle: return "Ready"
        case .preparing: return "Get ready..."
        case .capturing: return "Capturing"
        case .processing: return "Processing"
        case .complete: return "Done!"
        }
    }
}
