import SwiftUI

// Color Extension for Darkness Detection

extension Color {
    // determines if the color is dark (for contrast calculations)
    var isDark: Bool {
        // Convert to UIColor to access components
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate relative luminance
        let luminance = 0.299 * red + 0.587 * green + 0.114 * blue
        return luminance < 0.5
    }
    
    // determines if the color is black or very close to black
    var isBlack: Bool {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Check if all components are very low (close to black)
        return red < 0.1 && green < 0.1 && blue < 0.1
    }
}
