import Foundation

// builds unique beat sequences per frame so every capture
// feels different — mixes countdowns, fakes, haptics, etc.

class MisdirectionEngine: ObservableObject {
    @Published var currentMisdirection: MisdirectionType?
    @Published var countdownValue: Int = 3
    @Published var showFakeFlash: Bool = false
    @Published var playFakeShutter: Bool = false
    @Published var showCountdownNumber: Bool = false
    @Published var showEmojiOverlay: Bool = false
    @Published var currentEmoji: String = ""

    var settings: BoothSettings

    private var mood: SessionMood = .playful
    private var frameIndex: Int = 0
    private var history: [MisdirectionType] = []
    private var recentSignatures: [String] = []
    private var sessionSeed: UInt64 = 0
    private var timingBias: Double = 0
    private var rhythmBias: Double = 0.5

    private let emojiPool = ["😜", "😶‍🌫️", "😈", "🫣", "👁️", "🤫", "😏", "🙈", "👻", "🫠"]

    // internal beat types for composing frame sequences
    private enum Beat: CustomStringConvertible {
        case countdown(from: Int, to: Int)
        case fakeFlash
        case fakeShutter
        case doubleBurst
        case haptic
        case emoji(String)
        case silence(Double)
        case buildupHaptic

        var description: String {
            switch self {
            case .countdown(let f, let t): return "cd\(f)-\(t)"
            case .fakeFlash: return "ff"
            case .fakeShutter: return "fs"
            case .doubleBurst: return "db"
            case .haptic: return "hp"
            case .emoji(let e): return "em\(e)"
            case .silence(let d): return "sl\(String(format: "%.1f", d))"
            case .buildupHaptic: return "bh"
            }
        }
    }

    init(settings: BoothSettings) {
        self.settings = settings
    }

    // Session

    func startNewSession() {
        sessionSeed = UInt64.random(in: 0...UInt64.max)
        let seedF = Double(sessionSeed % 10000) / 10000.0
        timingBias = (seedF * 0.8) - 0.4
        rhythmBias = Double((sessionSeed >> 32) % 100) / 100.0
        mood = SessionMood.allCases.randomElement() ?? .playful
        frameIndex = 0
        history.removeAll()
        recentSignatures.removeAll()

        // 25% chance to shift mood mid-session for evolving feel
        if Double.random(in: 0...1) < 0.25 {
            let delay = Double.random(in: 3...8)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.mood = SessionMood.allCases.randomElement() ?? .chaotic
            }
        }
    }

    // Selection — weighted with heavy anti-repeat, arc-aware

    func selectMisdirection() -> MisdirectionType {
        frameIndex += 1

        var weights: [MisdirectionType: Double] = [
            .silentSurprise:     mood.silentWeight * 100,
            .fakeBarrage:        mood.fakeHeavyWeight * 60,
            .lyingCountdown:     mood.countdownWeight * 50,
            .delayedNothing:     25,
            .instantAmbush:      mood == .sneaky ? 30 : 15,
            .longCon:            mood == .calm ? 35 : 15,
            .countdownAbandoned: mood == .playful ? 40 : 20,
            .reverseExpectation: 20
        ]

        // penalize recent types hard so no two frames feel alike
        if let last = history.last { weights[last] = (weights[last] ?? 0) * 0.05 }
        for recent in history.suffix(3) { weights[recent] = (weights[recent] ?? 0) * 0.3 }

        // session arc: early frames lean instant/silent, later lean complex
        if frameIndex == 1 {
            weights[.instantAmbush] = (weights[.instantAmbush] ?? 0) * 3
            weights[.silentSurprise] = (weights[.silentSurprise] ?? 0) * 2
        }
        if frameIndex > 3 {
            weights[.longCon] = (weights[.longCon] ?? 0) * 1.5
            weights[.reverseExpectation] = (weights[.reverseExpectation] ?? 0) * 2
        }

        let total = weights.values.reduce(0, +)
        var roll = Double.random(in: 0..<total)
        for (type, w) in weights {
            roll -= w
            if roll <= 0 { history.append(type); return type }
        }
        let fallback = MisdirectionType.allCases.randomElement() ?? .silentSurprise
        history.append(fallback)
        return fallback
    }

    // Execute — builds a unique beat sequence, then plays it

    func executeMisdirection(type: MisdirectionType) async -> MisdirectionResult {
        await MainActor.run { currentMisdirection = type }
        let beats = composeBeats(for: type)
        for beat in beats { await executeBeat(beat) }
        return MisdirectionResult(shouldCapture: true, delay: 0)
    }

    // Post-capture decoy — occasional fake after the real capture to confuse

    func postCaptureDecoy() async {
        let roll = Double.random(in: 0...1)
        if roll < 0.28 {
            try? await sleep(Double.random(in: 0.05...0.20))
            await executeBeat(.fakeFlash)
        } else if roll < 0.45 {
            try? await sleep(Double.random(in: 0.10...0.30))
            await executeBeat(.emoji(emojiPool.randomElement() ?? "😜"))
        } else if roll < 0.50 {
            try? await sleep(Double.random(in: 0.08...0.18))
            await executeBeat(.doubleBurst)
        }
    }

    func reset() {
        currentMisdirection = nil
        countdownValue = 3
        showFakeFlash = false
        playFakeShutter = false
        showCountdownNumber = false
        showEmojiOverlay = false
        currentEmoji = ""
    }

    // Beat Composition
    // picks a primary shape from the misdirection type, then layers in
    // secondary surprises so every frame feels layered and unique

    private func composeBeats(for type: MisdirectionType) -> [Beat] {
        var beats: [Beat]

        switch type {
        case .silentSurprise:     beats = composeSilentSurprise()
        case .lyingCountdown:     beats = composeLyingCountdown()
        case .fakeBarrage:        beats = composeFakeBarrage()
        case .delayedNothing:     beats = composeDelayedNothing()
        case .instantAmbush:      beats = composeInstantAmbush()
        case .longCon:            beats = composeLongCon()
        case .countdownAbandoned: beats = composeCountdownAbandoned()
        case .reverseExpectation: beats = composeReverseExpectation()
        }

        beats = injectSecondaryBeats(into: beats)

        // if this sequence matches a recent one, mutate it so it feels fresh
        let sig = beats.map { $0.description }.joined()
        if recentSignatures.contains(sig) { beats = mutateSequence(beats) }
        recentSignatures.append(sig)
        if recentSignatures.count > 4 { recentSignatures.removeFirst() }

        return beats
    }

    // Primary Compositions

    private func composeSilentSurprise() -> [Beat] {
        var beats: [Beat] = []
        if coin() && coin() { beats.append(.haptic) }
        beats.append(.silence(jitteredDelay(mood.delayRange)))
        if coin() && coin() { beats.append(.silence(Double.random(in: 0.05...0.20))) }
        if Double.random(in: 0...1) < 0.12 {
            beats.append(.emoji(emojiPool.randomElement() ?? "😶‍🌫️"))
            beats.append(.silence(0.2))
        }
        return beats
    }

    private func composeLyingCountdown() -> [Beat] {
        switch Int.random(in: 0...7) {
        case 0:
            // capture before countdown even starts
            return [.silence(Double.random(in: 0.1...0.4))]
        case 1:
            // flash one number then capture
            let n = Int.random(in: 2...5)
            return [.countdown(from: n, to: n), .silence(Double.random(in: 0.2...0.5))]
        case 2:
            // full countdown then long suspenseful pause
            let s = Int.random(in: 3...6)
            return [.countdown(from: s, to: 1), .silence(Double.random(in: 1.0...3.0))]
        case 3:
            // variable speed countdown, stops early
            let s = Int.random(in: 3...6)
            return [.countdown(from: s, to: Int.random(in: 1...2))]
        case 4:
            // negative countdown — goes past zero
            return [.countdown(from: 1, to: -2), .silence(Double.random(in: 0.15...0.35))]
        case 5:
            // two numbers then surprise capture
            let s = Int.random(in: 3...5)
            return [.countdown(from: s, to: s - 1), .silence(Double.random(in: 0.2...0.5))]
        case 6:
            // countdown finishes then fake cue barrage before real capture
            let s = Int.random(in: 3...5)
            return [.countdown(from: s, to: 1),
                    coin() ? .fakeShutter : .fakeFlash,
                    .silence(Double.random(in: 0.3...0.8)),
                    coin() ? .fakeFlash : .doubleBurst,
                    .silence(Double.random(in: 0.4...1.2))]
        default:
            // emoji mid-countdown
            return [.countdown(from: 3, to: 3),
                    .emoji(emojiPool.randomElement() ?? "😈"),
                    .silence(0.3),
                    .countdown(from: 1, to: 1),
                    .silence(Double.random(in: 0.3...0.6))]
        }
    }

    private func composeFakeBarrage() -> [Beat] {
        var beats: [Beat] = []
        let count = Int.random(in: mood.fakeCueRange)
        for _ in 0..<count {
            beats.append(randomFakeCue())
            beats.append(.silence(Double.random(in: 0.10...0.55) + microJitter()))
        }
        beats.append(.silence(jitteredDelay(0.4...2.0)))
        if Double.random(in: 0...1) < 0.18 {
            beats.append(.emoji(emojiPool.randomElement() ?? "😜"))
            beats.append(.silence(0.25))
        }
        if coin() && coin() {
            beats.append(.haptic)
            beats.append(.silence(Double.random(in: 0.08...0.25)))
        }
        return beats
    }

    private func composeDelayedNothing() -> [Beat] {
        var beats: [Beat] = []
        for _ in 0..<Int.random(in: 1...2) {
            beats.append(coin() ? .fakeFlash : .fakeShutter)
            beats.append(.silence(Double.random(in: 0.2...0.5)))
        }
        beats.append(.silence(jitteredDelay(1.5...4.0)))
        if Double.random(in: 0...1) < 0.15 {
            beats.append(.emoji(emojiPool.randomElement() ?? "🫣"))
            beats.append(.silence(0.4))
        }
        if coin() { beats.append(.haptic) }
        return beats
    }

    private func composeInstantAmbush() -> [Beat] {
        var beats: [Beat] = []
        if coin() && coin() { beats.append(.haptic) }
        if Double.random(in: 0...1) < 0.07 { beats.append(.doubleBurst) }
        beats.append(.silence(Double.random(in: 0.08...0.45)))
        return beats
    }

    private func composeLongCon() -> [Beat] {
        var beats: [Beat] = []
        let total = jitteredDelay(3.0...6.0)
        let teases = Int.random(in: 1...3)
        let interval = max(0.5, total) / Double(teases + 1)

        for i in 0..<teases {
            beats.append(.silence(max(0.3, interval + Double.random(in: -0.5...0.5) + microJitter())))
            switch Int.random(in: 0...3) {
            case 0: beats.append(.fakeFlash)
            case 1: beats.append(.fakeShutter)
            case 2: beats.append(.haptic)
            default:
                if i == teases - 1 {
                    let n = Int.random(in: 1...3)
                    beats.append(.countdown(from: n, to: n))
                } else {
                    beats.append(.emoji(emojiPool.randomElement() ?? "😏"))
                }
            }
        }
        beats.append(.silence(Double.random(in: 0.5...1.5)))
        return beats
    }

    private func composeCountdownAbandoned() -> [Beat] {
        let start = Int.random(in: 2...5)
        let stop = Int.random(in: 1...min(start, 3))
        var beats: [Beat] = [.countdown(from: start, to: stop)]

        switch Int.random(in: 0...4) {
        case 0: break
        case 1: beats.append(.silence(Double.random(in: 0.3...0.8)))
        case 2:
            beats.append(coin() ? .fakeFlash : .fakeShutter)
            beats.append(.silence(Double.random(in: 0.2...0.6)))
        case 3:
            beats.append(.emoji(emojiPool.randomElement() ?? "😈"))
            beats.append(.silence(0.35))
        default:
            beats.append(.silence(Double.random(in: 1.0...2.5)))
        }
        return beats
    }

    private func composeReverseExpectation() -> [Beat] {
        switch Int.random(in: 0...6) {
        case 0: return []
        case 1: return [.fakeShutter, .silence(0.2), .fakeFlash, .silence(0.15), .haptic]
        case 2: return [.countdown(from: 1, to: 3), .silence(Double.random(in: 0.2...0.4))]
        case 3: return [.silence(Double.random(in: 2.0...3.5)), .fakeFlash, .fakeShutter]
        case 4: return [.fakeFlash]
        case 5: return [.doubleBurst, .silence(Double.random(in: 0.8...1.5))]
        default:
            return [.emoji(emojiPool.randomElement() ?? "👻"),
                    .silence(0.5), .buildupHaptic,
                    .silence(Double.random(in: 1.5...3.0))]
        }
    }

    // Secondary Injection
    // layers extra beats into the sequence so each frame feels multi-dimensional

    private func injectSecondaryBeats(into beats: [Beat]) -> [Beat] {
        var result = beats

        // ~12%: surprise emoji splice
        if Double.random(in: 0...1) < 0.12 && !result.isEmpty {
            let pos = Int.random(in: 0..<result.count)
            result.insert(.emoji(emojiPool.randomElement() ?? "😶‍🌫️"), at: pos)
            result.insert(.silence(Double.random(in: 0.15...0.30)), at: min(pos + 1, result.count))
        }

        // ~15%: random fake cue injected mid-sequence
        if Double.random(in: 0...1) < 0.15 && result.count > 1 {
            let pos = Int.random(in: 1..<result.count)
            result.insert(randomFakeCue(), at: pos)
        }

        // late-session frames get extra tension buildup
        if frameIndex > 2 && Double.random(in: 0...1) < 0.20 {
            result.insert(.buildupHaptic, at: 0)
            result.insert(.silence(Double.random(in: 0.3...0.8)), at: 1)
        }

        return result
    }

    // Mutation — alters a repeated sequence so it feels different

    private func mutateSequence(_ beats: [Beat]) -> [Beat] {
        var m = beats
        if m.count > 2 {
            let i = Int.random(in: 0..<m.count)
            let j = Int.random(in: 0..<m.count)
            m.swapAt(i, j)
        }
        m.append(.silence(Double.random(in: 0.1...0.3)))
        if coin() { m.append(.haptic) }
        return m
    }

    // Beat Execution

    private func executeBeat(_ beat: Beat) async {
        switch beat {
        case .countdown(let from, let to):
            if from >= to { await runCountdown(from: from, to: to) }
            else { await runCountdown(from: from, to: to, reversed: true) }

        case .fakeFlash:
            await MainActor.run { showFakeFlash = true }
            try? await sleep(Double.random(in: 0.06...0.14))
            await MainActor.run { showFakeFlash = false }

        case .fakeShutter:
            await MainActor.run { playFakeShutter = true }
            HapticManager.shared.fakeShutter()
            try? await sleep(Double.random(in: 0.10...0.20))
            await MainActor.run { playFakeShutter = false }

        case .doubleBurst:
            await MainActor.run { playFakeShutter = true }
            HapticManager.shared.doubleShutterBurst()
            try? await sleep(Double.random(in: 0.06...0.10))
            await MainActor.run { playFakeShutter = false }
            try? await sleep(Double.random(in: 0.04...0.08))
            await MainActor.run { playFakeShutter = true }
            try? await sleep(Double.random(in: 0.06...0.10))
            await MainActor.run { playFakeShutter = false }

        case .haptic:
            HapticManager.shared.meaninglessHaptic()

        case .emoji(let symbol):
            await MainActor.run { currentEmoji = symbol; showEmojiOverlay = true }
            try? await sleep(Double.random(in: 0.35...0.80))
            await MainActor.run { showEmojiOverlay = false }

        case .silence(let duration):
            try? await sleep(max(0.05, duration))

        case .buildupHaptic:
            HapticManager.shared.buildupHaptic()
        }
    }

    // Countdown Runner
    // handles normal, chaotic, negative, and reversed countdowns

    private func runCountdown(from: Int, to: Int, reversed: Bool = false) async {
        let numbers: [Int]
        if reversed {
            numbers = Array(stride(from: from, through: to, by: 1))
        } else {
            numbers = buildChaoticSequence(from: from, to: to)
        }

        for number in numbers {
            await MainActor.run {
                countdownValue = number
                showCountdownNumber = true
            }
            if coin() { HapticManager.shared.countdownTick() }
            else if coin() { HapticManager.shared.meaninglessHaptic() }

            if Double.random(in: 0...1) < 0.25 {
                try? await sleep(Double.random(in: 0.05...0.20))
            }
            try? await sleep(jitteredTick())
        }
        await MainActor.run { showCountdownNumber = false }
    }

    // builds a countdown with possible stutters, freezes, and skips
    private func buildChaoticSequence(from start: Int, to stop: Int) -> [Int] {
        var seq: [Int] = []
        var current = start
        while current >= stop {
            seq.append(current)
            if Double.random(in: 0...1) < 0.15 { seq.append(current) }
            let jump = Double.random(in: 0...1)
            if jump < 0.12 && current > stop + 2 { current -= 2 }
            else if jump < 0.18 && current < start {
                current += 1; seq.append(current); current -= 2
            } else { current -= 1 }
        }
        return seq
    }

    // Timing Helpers

    private func jitteredDelay(_ range: ClosedRange<Double>) -> Double {
        max(0.2, Double.random(in: range) + timingBias + microJitter())
    }

    private func jitteredTick() -> Double {
        let base = 0.5 + (rhythmBias * 0.7)
        return max(0.2, base + Double.random(in: -0.25...0.35) + (timingBias * 0.3))
    }

    private func microJitter() -> Double { Double.random(in: -0.08...0.12) }
    private func coin() -> Bool { Bool.random() }

    private func sleep(_ seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    private func randomFakeCue() -> Beat {
        let r = Double.random(in: 0...1)
        if r < 0.20 { return .fakeFlash }
        else if r < 0.45 { return .fakeShutter }
        else if r < 0.55 { return .doubleBurst }
        else if r < 0.70 { return .haptic }
        else { return .emoji(emojiPool.randomElement() ?? "😜") }
    }
}
