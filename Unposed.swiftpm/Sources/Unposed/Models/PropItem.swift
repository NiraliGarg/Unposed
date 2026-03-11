import SwiftUI
import UIKit

// Prop Anchor

enum PropAnchor: String, CaseIterable, Codable {
    case forehead
    case eyes
    case nose
    case chin
    case hand
    
    var displayName: String {
        switch self {
        case .forehead: return "Top of Head"
        case .eyes: return "Eyes"
        case .nose: return "Nose"
        case .chin: return "Chin"
        case .hand: return "Hand"
        }
    }
    
    var icon: String {
        switch self {
        case .forehead: return "arrow.up.circle"
        case .eyes: return "eyes"
        case .nose: return "nose"
        case .chin: return "arrow.down.circle"
        case .hand: return "hand.raised"
        }
    }
}

// Prop Category

enum PropCategory: String, CaseIterable, Codable {
    case glasses
    case hats
    case fun
    case custom
    
    var displayName: String {
        switch self {
        case .glasses: return "Glasses"
        case .hats: return "Hats"
        case .fun: return "Fun"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .glasses: return "eyeglasses"
        case .hats: return "crown"
        case .fun: return "sparkles"
        case .custom: return "plus.circle"
        }
    }
}

// Mask Eye Holes

// Normalized eye hole positions (0-1) within a mask image, used for precise alignment
struct MaskEyeHoles: Equatable {
    let leftEye: CGPoint
    let rightEye: CGPoint
    
    var interEyeDistance: CGFloat {
        hypot(rightEye.x - leftEye.x, rightEye.y - leftEye.y)
    }
    
    var center: CGPoint {
        CGPoint(
            x: (leftEye.x + rightEye.x) / 2,
            y: (leftEye.y + rightEye.y) / 2
        )
    }
}

// Prop Item

struct PropItem: Identifiable, Equatable {
    let id: String
    let name: String
    let category: PropCategory
    let anchor: PropAnchor
    let image: UIImage
    
    var offsetY: CGFloat = 0           // vertical offset relative to anchor (negative = up)
    var scaleMultiplier: CGFloat = 1.0 // scale relative to face width
    var isCustom: Bool = false
    var maskEyeHoles: MaskEyeHoles? = nil // set for mask-type props that need eye alignment
    
    var usesEyeAlignment: Bool {
        maskEyeHoles != nil
    }
    
    var leftEyeHoleNormalized: CGPoint {
        maskEyeHoles?.leftEye ?? CGPoint(x: 0.35, y: 0.5)
    }
    
    var rightEyeHoleNormalized: CGPoint {
        maskEyeHoles?.rightEye ?? CGPoint(x: 0.65, y: 0.5)
    }
    
    static func == (lhs: PropItem, rhs: PropItem) -> Bool {
        lhs.id == rhs.id
    }
}

// Face Landmark Data

// Processed face position data from Vision, converted to view coordinates
struct FaceLandmarkData {
    let boundingBox: CGRect
    let leftEye: CGPoint
    let rightEye: CGPoint
    let nose: CGPoint
    let faceWidth: CGFloat
    let faceAngle: CGFloat           // roll angle in radians
    let handPinchPosition: CGPoint?
    
    var interEyeDistance: CGFloat {
        hypot(rightEye.x - leftEye.x, rightEye.y - leftEye.y)
    }
    
    var eyeCenter: CGPoint {
        CGPoint(
            x: (leftEye.x + rightEye.x) / 2,
            y: (leftEye.y + rightEye.y) / 2
        )
    }
    
    // 60% from eye center toward the bounding box top edge
    var forehead: CGPoint {
        let bboxTop = boundingBox.minY
        let foreheadY = eyeCenter.y + (bboxTop - eyeCenter.y) * 0.60
        return CGPoint(x: eyeCenter.x, y: foreheadY)
    }
    
    var chin: CGPoint {
        let bboxBottom = boundingBox.maxY
        let chinY = nose.y + (bboxBottom - nose.y) * 0.6
        return CGPoint(x: nose.x, y: chinY)
    }
    
    func position(for anchor: PropAnchor) -> CGPoint {
        switch anchor {
        case .forehead: return forehead
        case .eyes: return eyeCenter
        case .nose: return nose
        case .chin: return chin
        case .hand: return handPinchPosition ?? nose
        }
    }
    
    func propSize(scale: CGFloat) -> CGFloat {
        return faceWidth * scale
    }
}
