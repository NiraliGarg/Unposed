import Foundation

// Session Mood
// every session picks a personality that shapes timing, cue density, and vibe
enum SessionMood: CaseIterable {
    case sneaky      // quick, silent, catches you off guard
    case chaotic     // lots of fakes, unpredictable timing
    case calm        // long pauses, lulls you into relaxation
    case playful     // teasing countdowns, broken promises
    case ghostly     // almost nothing happens... then snap

    var silentWeight: Double {
        switch self {
        case .sneaky: return 0.45; case .chaotic: return 0.10
        case .calm: return 0.35;   case .playful: return 0.15
        case .ghostly: return 0.60
        }
    }

    var fakeHeavyWeight: Double {
        switch self {
        case .sneaky: return 0.10; case .chaotic: return 0.50
        case .calm: return 0.15;   case .playful: return 0.35
        case .ghostly: return 0.05
        }
    }

    var countdownWeight: Double {
        switch self {
        case .sneaky: return 0.15; case .chaotic: return 0.20
        case .calm: return 0.25;   case .playful: return 0.40
        case .ghostly: return 0.10
        }
    }

    var delayRange: ClosedRange<Double> {
        switch self {
        case .sneaky: return 0.3...1.2; case .chaotic: return 0.5...2.0
        case .calm: return 1.5...4.0;   case .playful: return 0.8...2.5
        case .ghostly: return 2.0...5.0
        }
    }

    var fakeCueRange: ClosedRange<Int> {
        switch self {
        case .sneaky: return 0...1; case .chaotic: return 2...5
        case .calm: return 0...2;   case .playful: return 1...4
        case .ghostly: return 0...1
        }
    }
}

// Misdirection Types
// primary flavor for a frame — the engine blends secondary beats on top
enum MisdirectionType: CaseIterable {
    case silentSurprise
    case lyingCountdown
    case fakeBarrage
    case delayedNothing
    case instantAmbush
    case longCon
    case countdownAbandoned
    case reverseExpectation
}

// Misdirection Result
struct MisdirectionResult {
    let shouldCapture: Bool
    let delay: Double
}
