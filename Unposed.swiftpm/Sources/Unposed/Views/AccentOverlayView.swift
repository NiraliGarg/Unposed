import SwiftUI

// Accent Position (used by export renderer)

struct AccentPosition {
    let x: CGFloat
    let y: CGFloat
    let rotation: CGFloat
    let scale: CGFloat
    let opacity: Float
    let size: CGFloat
    let symbol: String
}

// Accent Overlay Types

enum AccentOverlay: CaseIterable {
    case hearts
    case stars
    case dots
    case flowers
    case cosmic
    case stamps
    
    var name: String {
        switch self {
        case .hearts: return "Hearts"
        case .stars: return "Stars"
        case .dots: return "Dots"
        case .flowers: return "Flowers"
        case .cosmic: return "Cosmic"
        case .stamps: return "Stamps"
        }
    }
    
    var symbols: [String] {
        switch self {
        case .hearts: return ["♡", "❤︎", "♥︎", "❥", "💕", "❣︎", "♥"]
        case .stars: return ["✧", "★", "☆", "✦", "⋆", "✵", "❋"]  
        case .dots: return ["•", "●", "○", "◦", "◉", "⬤", "◍"]
        case .flowers: return ["❀", "✿", "❁", "✾", "⚘", "❃", "✼"]
        case .cosmic: return ["☽", "✧", "★", "⋆", "✦", "☾", "✯"]
        case .stamps: return ["✿", "♡", "★", "◆", "▲", "●", "♦"]
        }
    }
    
    // color for each type
    var color: Color {
        switch self {
        case .hearts: return Color(red: 0.90, green: 0.45, blue: 0.55) // Soft rose pink
        case .stars: return Color(red: 0.88, green: 0.78, blue: 0.50)  // Warm golden
        case .dots: return Color(red: 0.70, green: 0.78, blue: 0.75)   // Soft sage
        case .flowers: return Color(red: 0.96, green: 0.45, blue: 0.38) // Rose coral
        case .cosmic: return Color(red: 0.55, green: 0.50, blue: 0.75) // Midnight lavender
        case .stamps: return Color(red: 0.82, green: 0.55, blue: 0.50) // Warm terracotta
        }
    }
    
    // Lighter tint for dark backgrounds
    var lightColor: Color {
        switch self {
        case .hearts: return Color(red: 0.95, green: 0.70, blue: 0.75) // Soft blush
        case .stars: return Color(red: 0.96, green: 0.90, blue: 0.72)  // Light gold
        case .dots: return Color(red: 0.85, green: 0.90, blue: 0.88)   // Pale sage
        case .flowers: return Color(red: 0.95, green: 0.82, blue: 0.85) // Light coral
        case .cosmic: return Color(red: 0.80, green: 0.75, blue: 0.92) // Soft lavender
        case .stamps: return Color(red: 0.92, green: 0.78, blue: 0.75) // Light terracotta
        }
    }
    
    @ViewBuilder
    var previewView: some View {
        let sizes: [CGFloat] = [16, 14, 18, 15, 17]
        let xOffsets: [CGFloat] = [-14, 16, -10, 18, 0]
        let yOffsets: [CGFloat] = [-16, -12, 14, 10, -4]
        let rotations: [Double] = [-12, 10, -6, 15, -8]
        
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Text(symbols[i])
                    .font(.system(size: sizes[i]))
                    .foregroundColor(color)
                    .offset(x: xOffsets[i], y: yOffsets[i])
                    .rotationEffect(.degrees(rotations[i]))
            }
        }
    }
    
    func getPositions(in rect: CGRect, avoiding photoRects: [CGRect]) -> [AccentPosition] {
        var positions: [AccentPosition] = []
        
        // Seeded random for consistent placement
        srand48(42)
        
        // Define safe zones (corners, edges, between frames)
        let safeZones: [(CGFloat, CGFloat)] = generateSafeZones(in: rect, avoiding: photoRects)
        
        // Place 8-12 accents for good coverage, more for taller strips
        let baseCount = 8
        let extraForHeight = Int((rect.height / 200)) // Add more for taller strips
        let count = min(baseCount + extraForHeight, safeZones.count)
        
        for i in 0..<count {
            let zone = safeZones[i]
            let symbol = symbols[i % symbols.count]
            
            positions.append(AccentPosition(
                x: zone.0 + CGFloat(drand48() * 8 - 4),
                y: zone.1 + CGFloat(drand48() * 8 - 4),
                rotation: CGFloat(drand48() * 0.5 - 0.25),
                scale: CGFloat(2.0 + drand48() * 0.5),   // Consistent 2×–2.5× scale
                opacity: Float(0.88 + drand48() * 0.12), // Strong visibility (88-100%)
                size: CGFloat(32 + drand48() * 10),      // Consistent size (32-42pt)
                symbol: symbol
            ))
        }
        
        return positions
    }
    
    private func generateSafeZones(in rect: CGRect, avoiding photoRects: [CGRect]) -> [(CGFloat, CGFloat)] {
        var zones: [(CGFloat, CGFloat)] = []
        
        // corners
        zones.append((rect.minX + 35, rect.minY + 28))
        zones.append((rect.maxX - 35, rect.minY + 28))
        zones.append((rect.minX + 35, rect.maxY - 55))
        zones.append((rect.maxX - 35, rect.maxY - 55))
        
        // Between frames - strategic edge placement
        for i in 0..<(photoRects.count - 1) {
            let gap = photoRects[i + 1].minY - photoRects[i].maxY
            let midY = photoRects[i].maxY + gap / 2
            // Alternate left and right for variety
            if i % 2 == 0 {
                zones.append((rect.minX + 25, midY))
            } else {
                zones.append((rect.maxX - 25, midY))
            }
        }
        
        // Additional mid-edge accents for taller strips
        for i in 0..<photoRects.count {
            let photo = photoRects[i]
            // Add accents on sides of photos
            if i % 2 == 0 {
                zones.append((rect.maxX - 20, photo.midY))
            } else {
                zones.append((rect.minX + 20, photo.midY))
            }
        }
        
        // Mid-edge accents for balance
        if let firstPhoto = photoRects.first {
            zones.append((rect.maxX - 22, firstPhoto.midY))
        }
        if let lastPhoto = photoRects.last {
            zones.append((rect.minX + 22, lastPhoto.midY))
        }
        
        return zones
    }
}

// Preview Accent Position

struct PreviewAccentPosition {
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    let symbolIndex: Int
}

// Accent Overlay View

struct AccentOverlayView: View {
    let accent: AccentOverlay
    let accentColor: Color
    let frameCount: Int
    let orientation: StripOrientation
    let containerSize: CGSize
    
    private var symbols: [String] {
        accent.symbols
    }
    
    private let baseScale: CGFloat = 2.0
    private let baseSize: CGFloat = 14
    
    // positions based on orientation and container size
    private var positions: [PreviewAccentPosition] {
        let w = containerSize.width
        let h = containerSize.height
        
        switch orientation {
        case .vertical:
            // Vertical strips: distribute along both edges
            var pos: [PreviewAccentPosition] = [
                // Corners
                PreviewAccentPosition(x: 14, y: 14, rotation: -10, scale: baseScale, symbolIndex: 0),
                PreviewAccentPosition(x: w - 14, y: 16, rotation: 12, scale: baseScale, symbolIndex: 1),
                PreviewAccentPosition(x: 16, y: h - 32, rotation: -8, scale: baseScale, symbolIndex: 2),
                PreviewAccentPosition(x: w - 16, y: h - 34, rotation: 15, scale: baseScale, symbolIndex: 3),
            ]
            
            // Add mid-height accents based on frame count (only if frameCount > 0)
            if frameCount > 0 {
                let spacing = h / CGFloat(frameCount + 1)
                for i in 1...frameCount {
                    let y = spacing * CGFloat(i)
                    if i % 2 == 0 {
                        pos.append(PreviewAccentPosition(x: 12, y: y, rotation: -5 + Double(i * 3), scale: baseScale * 0.95, symbolIndex: (4 + i) % 7))
                    } else {
                        pos.append(PreviewAccentPosition(x: w - 12, y: y, rotation: 8 - Double(i * 2), scale: baseScale * 0.95, symbolIndex: (4 + i) % 7))
                    }
                }
            }
            
            return pos
            
        case .polaroid:
            // polaroid: accents around the corners and bottom margin
            return [
                PreviewAccentPosition(x: 14, y: 14, rotation: -10, scale: baseScale, symbolIndex: 0),
                PreviewAccentPosition(x: w - 14, y: 14, rotation: 12, scale: baseScale, symbolIndex: 1),
                PreviewAccentPosition(x: 14, y: h - 20, rotation: -8, scale: baseScale, symbolIndex: 2),
                PreviewAccentPosition(x: w - 14, y: h - 20, rotation: 15, scale: baseScale, symbolIndex: 3),
                PreviewAccentPosition(x: w / 2, y: h - 14, rotation: 5, scale: baseScale * 0.9, symbolIndex: 4),
            ]
            
        case .square:
            // Grid layout: more positions for better coverage on larger grids
            var pos: [PreviewAccentPosition] = [
                // Four corners
                PreviewAccentPosition(x: 10, y: 12, rotation: -12, scale: baseScale, symbolIndex: 0),
                PreviewAccentPosition(x: w - 10, y: 12, rotation: 10, scale: baseScale, symbolIndex: 1),
                PreviewAccentPosition(x: 10, y: h - 28, rotation: -6, scale: baseScale, symbolIndex: 2),
                PreviewAccentPosition(x: w - 10, y: h - 30, rotation: 14, scale: baseScale, symbolIndex: 3),
                // Top center
                PreviewAccentPosition(x: w / 2, y: 10, rotation: 5, scale: baseScale * 0.9, symbolIndex: 4),
            ]
            
            // Add side accents for taller grids (6 or 8 frames)
            if frameCount >= 6 {
                let midY = h * 0.4
                pos.append(PreviewAccentPosition(x: 10, y: midY, rotation: -8, scale: baseScale * 0.9, symbolIndex: 5))
                pos.append(PreviewAccentPosition(x: w - 10, y: midY + 20, rotation: 10, scale: baseScale * 0.9, symbolIndex: 6))
            }
            
            if frameCount >= 8 {
                let upperMidY = h * 0.25
                let lowerMidY = h * 0.6
                pos.append(PreviewAccentPosition(x: 12, y: upperMidY, rotation: 6, scale: baseScale * 0.85, symbolIndex: 0))
                pos.append(PreviewAccentPosition(x: w - 12, y: lowerMidY, rotation: -7, scale: baseScale * 0.85, symbolIndex: 1))
            }
            
            return pos
        }
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<positions.count, id: \.self) { i in
                accentText(for: positions[i])
            }
        }
        .allowsHitTesting(false)
    }
    
    @ViewBuilder
    private func accentText(for pos: PreviewAccentPosition) -> some View {
        let symbol = symbols[pos.symbolIndex % symbols.count]
        Text(symbol)
            .font(.system(size: baseSize * pos.scale))
            .foregroundColor(accentColor.opacity(0.9))
            .rotationEffect(.degrees(pos.rotation))
            .position(x: pos.x, y: pos.y)
    }
}
