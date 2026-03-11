import SwiftUI

class BoothSettings: ObservableObject {
    @Published var frameCount: Int = 3 {
        didSet {
            let allowed = BoothSettings.allowedFrameCounts(for: orientation)
            if !allowed.contains(frameCount) {
                frameCount = allowed.first ?? frameCount
            }
        }
    }

    @Published var orientation: StripOrientation = .vertical {
        didSet {
            let allowed = BoothSettings.allowedFrameCounts(for: orientation)
            if !allowed.contains(frameCount) {
                frameCount = allowed.first ?? frameCount
            }
        }
    }
    
    var delayRange: ClosedRange<Double> { 1.0...2.5 }
    var pauseBetweenFrames: Double { 1.2 }

    static func allowedFrameCounts(for orientation: StripOrientation) -> [Int] {
        switch orientation {
        case .vertical: return [2, 3, 4]
        case .square: return [4, 6, 8]
        case .polaroid: return [1]
        }
    }
}

enum StripOrientation: String, CaseIterable {
    case polaroid = "Polaroid Pic"
    case vertical = "Vertical"
    case square = "Square Grid"
    
    var icon: String {
        switch self {
        case .vertical: return "rectangle.split.1x2"
        case .square: return "square.grid.2x2"
        case .polaroid: return "photo"
        }
    }
}
