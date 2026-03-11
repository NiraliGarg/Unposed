import SwiftUI

// App-wide color palette
struct AppColors {
    // Primary soft pink palette
    static let backgroundLight = Color(red: 0.98, green: 0.94, blue: 0.95)
    static let backgroundMid = Color(red: 0.96, green: 0.90, blue: 0.92)
    static let backgroundDark = Color(red: 0.94, green: 0.88, blue: 0.90)
    
    // Accent colors
    static let accent = Color(red: 0.85, green: 0.40, blue: 0.45)
    static let accentLight = Color(red: 0.95, green: 0.70, blue: 0.72)
    
    // Text colors
    static let textPrimary = Color(red: 0.25, green: 0.20, blue: 0.22)
    static let textSecondary = Color(red: 0.50, green: 0.45, blue: 0.47)
    
    // Gradients
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundLight, backgroundMid, backgroundDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accent.opacity(0.85)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
