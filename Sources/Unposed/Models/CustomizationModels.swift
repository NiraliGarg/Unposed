import SwiftUI
import UIKit

// Customization Section Tabs

enum CustomizationSection: CaseIterable {
    case background, stickers, details
    
    var title: String {
        switch self {
        case .background: return "Background"
        case .stickers: return "Accents"
        case .details: return "Details"
        }
    }
    
    var icon: String {
        switch self {
        case .background: return "paintpalette"
        case .stickers: return "sparkles"
        case .details: return "pencil.line"
        }
    }
}

// Background Type

enum BackgroundType: String, CaseIterable {
    case solid = "Solid"
    case pattern = "Pattern"
}

// Solid Background Colors

enum SolidBackgroundColor: CaseIterable {
    case pureWhite, warmCream, softBeige, lightSand, deepBlack
    case coralRed, gajriPink, navyBlue, forestGreen, burntOrange
    case blushPink, powderBlue, lavender, mintGreen, softYellow
    
    var color: Color {
        Color(uiColor)
    }
    
    var uiColor: UIColor {
        switch self {
        case .pureWhite: return UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
        case .warmCream: return UIColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1)
        case .softBeige: return UIColor(red: 0.96, green: 0.93, blue: 0.88, alpha: 1)
        case .lightSand: return UIColor(red: 0.94, green: 0.90, blue: 0.82, alpha: 1)
        case .deepBlack: return UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1)
        case .coralRed: return UIColor(red: 0.94, green: 0.42, blue: 0.42, alpha: 1)
        case .gajriPink: return UIColor(red: 0.89, green: 0.35, blue: 0.52, alpha: 1)
        case .navyBlue: return UIColor(red: 0.18, green: 0.25, blue: 0.42, alpha: 1)
        case .forestGreen: return UIColor(red: 0.20, green: 0.40, blue: 0.32, alpha: 1)
        case .burntOrange: return UIColor(red: 0.80, green: 0.33, blue: 0.20, alpha: 1)
        case .blushPink: return UIColor(red: 0.98, green: 0.85, blue: 0.87, alpha: 1)
        case .powderBlue: return UIColor(red: 0.82, green: 0.90, blue: 0.96, alpha: 1)
        case .lavender: return UIColor(red: 0.88, green: 0.82, blue: 0.95, alpha: 1)
        case .mintGreen: return UIColor(red: 0.82, green: 0.95, blue: 0.88, alpha: 1)
        case .softYellow: return UIColor(red: 0.99, green: 0.96, blue: 0.78, alpha: 1)
        }
    }
    
    var isDark: Bool {
        switch self {
        case .deepBlack, .navyBlue, .forestGreen, .burntOrange: return true
        default: return false
        }
    }
    
    // Subset for the picker UI
    static var curated: [SolidBackgroundColor] {
        [.pureWhite, .deepBlack, .coralRed, .navyBlue, .blushPink, .lavender, .warmCream, .forestGreen]
    }
}

// Pattern Background

enum PatternBackground: String, CaseIterable {
    case pattern1 = "Pattern 1"
    case pattern2 = "Pattern 2"
    case pattern3 = "Pattern 3"
    case pattern4 = "Pattern 4"
    case pattern5 = "Pattern 5"
    
    var name: String { rawValue }
    
    var image: UIImage? {
        return UIImage(named: rawValue)
    }
    
    var preview: Color {
        switch self {
        case .pattern1: return Color(red: 0.96, green: 0.85, blue: 0.88)   // Soft pink
        case .pattern2: return Color(red: 0.92, green: 0.88, blue: 0.95)   // Lavender
        case .pattern3: return Color(red: 0.95, green: 0.92, blue: 0.85)   // Warm cream
        case .pattern4: return Color(red: 0.88, green: 0.94, blue: 0.92)   // Mint
        case .pattern5: return Color(red: 0.96, green: 0.90, blue: 0.85)   // Peach
        }
    }
    
    // Fallback color if pattern image fails to load
    var baseColor: UIColor {
        switch self {
        case .pattern1: return UIColor(red: 0.96, green: 0.85, blue: 0.88, alpha: 1)
        case .pattern2: return UIColor(red: 0.92, green: 0.88, blue: 0.95, alpha: 1)
        case .pattern3: return UIColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1)
        case .pattern4: return UIColor(red: 0.88, green: 0.94, blue: 0.92, alpha: 1)
        case .pattern5: return UIColor(red: 0.96, green: 0.90, blue: 0.85, alpha: 1)
        }
    }
}
