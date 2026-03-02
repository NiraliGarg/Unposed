import SwiftUI

struct CustomizableStripPreview: View {
    let frames: [CapturedFrame]
    let orientation: StripOrientation
    let backgroundType: BackgroundType
    let solidColor: SolidBackgroundColor
    let pattern: PatternBackground
    let selectedAccent: AccentOverlay?
    let personalMessage: String
    let showDate: Bool
    let captureDate: Date
    let signature: String
    let isUsingCustomColor: Bool
    let customColor: Color
    var customPatternImage: UIImage? = nil
    
    private var isBackgroundDark: Bool {
        if backgroundType == .solid {
            if isUsingCustomColor {
                return customColor.isDark
            }
            return solidColor.isDark
        }
        // Pattern 5 is dark (navy blue), so text should be white
        if backgroundType == .pattern && pattern == .pattern5 {
            return true
        }
        return false
    }
    
    private var effectiveBackgroundColor: Color {
        if backgroundType == .solid && isUsingCustomColor {
            return customColor
        }
        return solidColor.color
    }
    
    @ViewBuilder
    private var stripBackground: some View {
        switch backgroundType {
        case .solid:
            RoundedRectangle(cornerRadius: 8)
                .fill(effectiveBackgroundColor)
                .shadow(color: Color.black.opacity(0.12), radius: 15, x: 0, y: 8)
        case .pattern:
            if let custom = customPatternImage {
                Image(uiImage: custom)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Color.black.opacity(0.12), radius: 15, x: 0, y: 8)
            } else if let patternImage = pattern.image {
                Image(uiImage: patternImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Color.black.opacity(0.12), radius: 15, x: 0, y: 8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(pattern.baseColor))
                    .shadow(color: Color.black.opacity(0.12), radius: 15, x: 0, y: 8)
            }
        }
    }
    
    private var textColor: Color {
        isBackgroundDark ? .white.opacity(0.7) : Color(white: 0.3)
    }
    
    private var timestampColor: Color {
        isBackgroundDark ? .white.opacity(0.85) : Color(white: 0.15)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy • h:mm a"
        return formatter.string(from: captureDate).uppercased()
    }
    
    private func accentColor(for accent: AccentOverlay) -> Color {
        isBackgroundDark ? accent.lightColor : accent.color
    }
    
    // Layout Calculations
    
    // always 2 columns
    private var gridColumns: Int {
        2  // Grid always uses 2 columns for 4, 6, or 8 frames
    }
    
    private var gridRows: Int {
        (frames.count + gridColumns - 1) / gridColumns
    }
    
    // Vertical layout constants — proportionally matched to PhotoStripView (200/320 = 0.625 scale)
    private let verticalStripWidth: CGFloat = 200
    private let verticalPhotoWidth: CGFloat = 183  // 292 * 0.625 ≈ 183
    private let verticalPhotoHeight: CGFloat = 137  // 219 * 0.625 ≈ 137 (maintains 0.75 aspect)
    private let verticalHorizontalPadding: CGFloat = 9  // 14 * 0.625 ≈ 9
    private let verticalTopPadding: CGFloat = 13  // 20 * 0.625 ≈ 13
    private let verticalPhotoSpacing: CGFloat = 8  // 12 * 0.625 ≈ 8
    private let verticalBottomPadding: CGFloat = 38  // 60 * 0.625 ≈ 38 — matches PhotoStripView
    
    // Grid layout constants
    private let gridPhotoSize: CGFloat = 110
    private let gridSpacing: CGFloat = 8
    private let gridPadding: CGFloat = 14
    private let gridBottomPadding: CGFloat = 38  // 60 * 0.625 ≈ 38 — matches PhotoStripView
    
    // Polaroid layout constants
    private let polaroidPhotoSize: CGFloat = 200
    private let polaroidSidePadding: CGFloat = 13
    private let polaroidTopPadding: CGFloat = 13
    private let polaroidBottomPadding: CGFloat = 50
    
    private var stripWidth: CGFloat {
        switch orientation {
        case .vertical:
            return verticalStripWidth
        case .square:
            let totalWidth = (gridPhotoSize * CGFloat(gridColumns)) + (gridSpacing * CGFloat(gridColumns - 1)) + (gridPadding * 2)
            return max(totalWidth, 180)
        case .polaroid:
            return polaroidPhotoSize + (polaroidSidePadding * 2)
        }
    }
    
    // base height without details
    private var baseStripHeight: CGFloat {
        switch orientation {
        case .vertical:
            let photosHeight = verticalPhotoHeight * CGFloat(frames.count) + verticalPhotoSpacing * CGFloat(frames.count - 1)
            return verticalTopPadding + photosHeight + verticalBottomPadding
        case .square:
            let photosHeight = (gridPhotoSize * CGFloat(gridRows)) + (gridSpacing * CGFloat(gridRows - 1))
            return gridPadding + photosHeight + gridBottomPadding
        case .polaroid:
            return polaroidTopPadding + polaroidPhotoSize + polaroidBottomPadding
        }
    }
    
    // total height including details
    private var fixedStripHeight: CGFloat {
        return baseStripHeight + detailsHeight
    }
    
    private var detailsHeight: CGFloat {
        var height: CGFloat = 0
        if !personalMessage.isEmpty { height += 16 }
        if !signature.isEmpty { height += 18 }
        if height > 0 { height += 8 }
        return height
    }
    
    var body: some View {
        switch orientation {
        case .vertical:
            verticalLayout
        case .square:
            gridLayout
        case .polaroid:
            polaroidLayout
        }
    }
    
    // Vertical Layout
    
    private var verticalLayout: some View {
        ZStack(alignment: .top) {
            // Main content — anchored at top, grows downward when details added
            VStack(spacing: 0) {
                VStack(spacing: verticalPhotoSpacing) {
                    ForEach(frames, id: \.id) { frame in
                        Image(uiImage: frame.image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: verticalPhotoWidth, height: verticalPhotoHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                .padding(.horizontal, verticalHorizontalPadding)
                .padding(.top, verticalTopPadding)
                
                Spacer(minLength: 5)
                
                detailsView
                brandingView
            }
            
            // Accent overlay
            if let accent = selectedAccent {
                AccentOverlayView(
                    accent: accent,
                    accentColor: accentColor(for: accent),
                    frameCount: frames.count,
                    orientation: .vertical,
                    containerSize: CGSize(width: stripWidth, height: fixedStripHeight)
                )
            }
            
            // Timestamp overlay
            if showDate {
                timestampOverlay
            }
        }
        .frame(width: verticalStripWidth, height: fixedStripHeight, alignment: .top)
        .background(stripBackground)
        .clipped()
    }
    
    // Grid Layout
    
    private var gridLayout: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                gridPhotosView
                    .padding(.horizontal, gridPadding)
                    .padding(.top, gridPadding)
                
                Spacer(minLength: 5)
                
                detailsView
                brandingView
            }
            
            if let accent = selectedAccent {
                AccentOverlayView(
                    accent: accent,
                    accentColor: accentColor(for: accent),
                    frameCount: frames.count,
                    orientation: .square,
                    containerSize: CGSize(width: stripWidth, height: fixedStripHeight)
                )
            }
            
            // Timestamp as absolute overlay on right inner edge
            if showDate {
                timestampOverlay
            }
        }
        // Frame anchored at top — height grows downward when details added
        .frame(width: stripWidth, height: fixedStripHeight, alignment: .top)
        .background(stripBackground)
        .clipped()
    }
    
    // polaroid layout — single photo with thick bottom margin
    private var polaroidLayout: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                if let frame = frames.first {
                    Image(uiImage: frame.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: polaroidPhotoSize, height: polaroidPhotoSize)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(.top, polaroidTopPadding)
                        .padding(.horizontal, polaroidSidePadding)
                }
                
                Spacer(minLength: 5)
                
                detailsView
                brandingView
            }
            
            if let accent = selectedAccent {
                AccentOverlayView(
                    accent: accent,
                    accentColor: accentColor(for: accent),
                    frameCount: 1,
                    orientation: .polaroid,
                    containerSize: CGSize(width: stripWidth, height: fixedStripHeight)
                )
            }
            
            if showDate {
                timestampOverlay
            }
        }
        .frame(width: stripWidth, height: fixedStripHeight, alignment: .top)
        .background(stripBackground)
        .clipped()
    }
    
    @ViewBuilder
    private var gridPhotosView: some View {
        let columns = Array(repeating: GridItem(.fixed(gridPhotoSize), spacing: gridSpacing), count: gridColumns)
        
        LazyVGrid(columns: columns, spacing: gridSpacing) {
            ForEach(frames, id: \.id) { frame in
                Image(uiImage: frame.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: gridPhotoSize, height: gridPhotoSize)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }
    
    // Shared Components
    
    private var detailsView: some View {
        VStack(spacing: 4) {
            if !personalMessage.isEmpty {
                Text(personalMessage)
                    .font(.system(size: 9, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(textColor.opacity(0.8))
            }
            
            if !signature.isEmpty {
                Text(signature)
                    .font(.custom("Snell Roundhand", size: 12))
                    .foregroundColor(textColor.opacity(0.6))
            }
        }
        .padding(.bottom, detailsHeight > 0 ? 4 : 0)
    }
    
    private var brandingView: some View {
        Image("Unposed for Strip")
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: stripWidth * 0.6, height: 10)
            .foregroundColor(brandingColor)
            .padding(.bottom, 9)
    }
    
    // white for black/dark bg, black for everything else
    private var brandingColor: Color {
        // White text only for black solid color
        if backgroundType == .solid {
            if isUsingCustomColor {
                // Only pure black or very dark custom colors get white
                return customColor.isBlack ? Color.white : Color.black
            }
            // Only the deepBlack preset gets white
            return solidColor == .deepBlack ? Color.white : Color.black
        }
        // For patterns: only Pattern 5 (dark navy) gets white text
        if backgroundType == .pattern && pattern == .pattern5 {
            return Color.white
        }
        // All other patterns and backgrounds get black
        return Color.black
    }
    
    private var timestampOverlay: some View {
        GeometryReader { geo in
            Text(formattedDate)
                .font(.system(size: 5.5, weight: .semibold, design: .monospaced))
                .tracking(0.8)
                .foregroundColor(brandingColor)
                .rotationEffect(.degrees(-90))
                .fixedSize()
                .position(
                    x: geo.size.width - 5,  // Centered in right margin between photos and strip edge
                    y: geo.size.height / 2   // Vertically centered
                )
        }
        .allowsHitTesting(false)
    }
}
