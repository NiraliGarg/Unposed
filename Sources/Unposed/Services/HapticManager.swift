import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private init() {
        prepareAll()
    }
    
    func prepareAll() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        softGenerator.prepare()
        rigidGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    // Real Capture Feedback
    
    // never the same intensity or timing
    func variableCaptureConfirmation() {
        let style = Int.random(in: 0...5)
        switch style {
        case 0:
            // barely there
            softGenerator.impactOccurred(intensity: Double.random(in: 0.08...0.15))
        case 1:
            // subtle
            softGenerator.impactOccurred(intensity: Double.random(in: 0.25...0.40))
        case 2:
            // slightly delayed
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.06...0.12)) {
                self.softGenerator.impactOccurred(intensity: Double.random(in: 0.30...0.45))
            }
        case 3:
            // double micro-tap
            softGenerator.impactOccurred(intensity: 0.20)
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.04...0.08)) {
                self.lightGenerator.impactOccurred(intensity: 0.15)
            }
        case 4:
            // nothing at all
            break
        default:
            // Standard subtle
            softGenerator.impactOccurred(intensity: 0.35)
        }
    }
    
    // Fake/Misleading Haptics
    
    func fakeShutter() {
        let intensity = Double.random(in: 0.2...0.5)
        lightGenerator.impactOccurred(intensity: intensity)
    }
    
    func doubleShutterBurst() {
        let intensity1 = Double.random(in: 0.25...0.45)
        let intensity2 = Double.random(in: 0.20...0.40)
        let gap = Double.random(in: 0.04...0.09)
        lightGenerator.impactOccurred(intensity: intensity1)
        DispatchQueue.main.asyncAfter(deadline: .now() + gap) {
            self.lightGenerator.impactOccurred(intensity: intensity2)
        }
    }
    
    // pure misdirection haptic
    func meaninglessHaptic() {
        let style = Int.random(in: 0...4)
        switch style {
        case 0:
            softGenerator.impactOccurred(intensity: Double.random(in: 0.1...0.25))
        case 1:
            lightGenerator.impactOccurred(intensity: Double.random(in: 0.15...0.35))
        case 2:
            softGenerator.impactOccurred(intensity: 0.15)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.softGenerator.impactOccurred(intensity: 0.15)
            }
        case 3:
            rigidGenerator.impactOccurred(intensity: Double.random(in: 0.1...0.25))
        default:
            break
        }
    }
    
    // feels like buildup but leads nowhere
    func buildupHaptic() {
        softGenerator.impactOccurred(intensity: 0.2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            self.lightGenerator.impactOccurred(intensity: 0.25)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.lightGenerator.impactOccurred(intensity: 0.3)
        }
    }
    
    func countdownTick() {
        let behavior = Int.random(in: 0...4)
        switch behavior {
        case 0:
            lightGenerator.impactOccurred(intensity: 0.4)
        case 1:
            lightGenerator.impactOccurred(intensity: 0.15)
        case 2:
            softGenerator.impactOccurred(intensity: 0.25)
        default:
            break
        }
    }
    
    // UI Feedback (Non-Capture Related)
    
    func buttonTap() {
        lightGenerator.impactOccurred(intensity: 0.5)
    }
    
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    func stripReveal() {
        heavyGenerator.impactOccurred(intensity: 0.8)
    }
    
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }
}
