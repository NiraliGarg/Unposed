import SwiftUI

struct BoothSetupScreen: View {
    @EnvironmentObject var settings: BoothSettings
    let onEnterBooth: () -> Void
    let onBack: () -> Void
    
    @State private var showContent = false
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let isCompact = geo.size.width < 600
            
            ZStack {
                // soft pink background
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                // Subtle floating shapes
                FloatingShapesBackground()
                    .opacity(0.5)
                
                // back button
                VStack {
                    HStack {
                        Button(action: {
                            HapticManager.shared.buttonTap()
                            onBack()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                                .padding(12)
                        }
                        .padding(.leading, 20)
                        .padding(.top, isLandscape ? 16 : 24)
                        .opacity(showContent ? 1 : 0)
                        Spacer()
                    }
                    Spacer()
                }
                
                VStack(spacing: 0) {
                    // header
                    Text("Set Up Your Booth")
                        .font(.system(size: isCompact ? 32 : 42, weight: .light, design: .serif))
                        .foregroundColor(AppColors.textPrimary)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .padding(.top, isLandscape ? 28 : (isCompact ? 36 : 56))
                    
                    Spacer(minLength: isLandscape ? 8 : 10)
                    
                    // Orientation selector
                    OptionSection(title: "Strip Layout") {
                        HStack(spacing: isCompact ? 10 : 20) {
                            ForEach(StripOrientation.allCases, id: \.self) { orientation in
                                OrientationButton(
                                    orientation: orientation,
                                    isSelected: settings.orientation == orientation,
                                    isCompact: isCompact
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        settings.orientation = orientation
                                    }
                                    HapticManager.shared.buttonTap()
                                }
                            }
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 40)
                    
                    Spacer(minLength: isLandscape ? 6 : 10)
                    
                    // Frame count selector
                    OptionSection(title: "Number of Frames") {
                        HStack(spacing: isCompact ? 10 : 20) {
                            ForEach(BoothSettings.allowedFrameCounts(for: settings.orientation), id: \.self) { count in
                                FrameCountButton(
                                    count: count,
                                    isSelected: settings.frameCount == count,
                                    orientation: settings.orientation,
                                    isCompact: isCompact
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        settings.frameCount = count
                                    }
                                    HapticManager.shared.buttonTap()
                                }
                            }
                        }
                        .id(settings.orientation)
                        .animation(.spring(response: 0.3), value: settings.orientation)
                    }
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    
                    Spacer(minLength: isLandscape ? 12 : 20)
                    
                    // enter booth button
                    Button(action: {
                        HapticManager.shared.buttonTap()
                        onEnterBooth()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 17))
                            Text("Enter Booth")
                                .font(.system(size: 19, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            Capsule()
                                .fill(AppColors.accentGradient)
                                .shadow(color: AppColors.accent.opacity(0.30), radius: 20, x: 0, y: 10)
                                .shadow(color: AppColors.accent.opacity(0.10), radius: 6, x: 0, y: 3)
                        )
                    }
                    .frame(maxWidth: 380)
                    .padding(.horizontal, 8)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.95)
                    
                    Spacer(minLength: isLandscape ? 24 : 56)
                }
                .frame(maxWidth: 650)
                .padding(.horizontal, isCompact ? 20 : 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

struct OptionSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text(title)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .tracking(2)
                .textCase(.uppercase)
            
            content
        }
    }
}

struct FrameCountButton: View {
    let count: Int
    let isSelected: Bool
    let orientation: StripOrientation
    var isCompact: Bool = false
    let action: () -> Void
    
    private var buttonSize: CGFloat { isCompact ? 100 : 150 }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: isCompact ? 10 : 16) {
                // show layout preview based on orientation
                if orientation == .vertical {
                    verticalPreview
                } else if orientation == .square {
                    gridPreview
                } else {
                    polaroidPreview
                }
                
                Text("\(count)")
                    .font(.system(size: isCompact ? 18 : 24, weight: .semibold))
                    .foregroundColor(isSelected ? AppColors.accent : AppColors.textSecondary)
            }
            .frame(width: buttonSize, height: buttonSize)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(isSelected ? AppColors.accent.opacity(0.12) : Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(isSelected ? AppColors.accent.opacity(0.4) : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(isSelected ? 0.06 : 0.03), radius: 10, x: 0, y: 5)
            )
        }
    }
    
    // Vertical strip preview
    private var verticalPreview: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.7))
            .frame(width: 30, height: 60)
            .overlay(
                VStack(spacing: 2.5) {
                    ForEach(0..<count, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(isSelected ? AppColors.accent : AppColors.textSecondary.opacity(0.4))
                            .frame(width: 22, height: count <= 3 ? 14 : 10)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? AppColors.accent.opacity(0.3) : AppColors.textSecondary.opacity(0.2), lineWidth: 1)
            )
    }
    
    // Grid preview
    private var gridPreview: some View {
        let columns = 2
        let rows = (count + 1) / 2
        
        // Scale block size and container proportionally
        let blockSize: CGFloat = count <= 4 ? 20 : (count <= 6 ? 16 : 14)
        let gap: CGFloat = 4
        let innerPadding: CGFloat = 6
        
        let containerWidth = CGFloat(columns) * blockSize + CGFloat(columns - 1) * gap + innerPadding * 2
        let containerHeight = CGFloat(rows) * blockSize + CGFloat(rows - 1) * gap + innerPadding * 2
        
        return RoundedRectangle(cornerRadius: 5)
            .fill(Color.white.opacity(0.7))
            .frame(width: containerWidth, height: containerHeight)
            .overlay(
                VStack(spacing: gap) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: gap) {
                            ForEach(0..<columns, id: \.self) { col in
                                let index = row * columns + col
                                if index < count {
                                    RoundedRectangle(cornerRadius: 2.5)
                                        .fill(isSelected ? AppColors.accent : AppColors.textSecondary.opacity(0.4))
                                        .frame(width: blockSize, height: blockSize)
                                } else {
                                    Color.clear
                                        .frame(width: blockSize, height: blockSize)
                                }
                            }
                        }
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(isSelected ? AppColors.accent.opacity(0.3) : AppColors.textSecondary.opacity(0.2), lineWidth: 1)
            )
    }
    
    // polaroid preview — single square image with thick bottom
    private var polaroidPreview: some View {
        let fillColor = isSelected ? AppColors.accent : AppColors.textSecondary.opacity(0.4)
        return RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.7))
            .frame(width: 44, height: 54)
            .overlay(
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(fillColor)
                        .frame(width: 34, height: 34)
                        .padding(.top, 5)
                    Spacer()
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? AppColors.accent.opacity(0.3) : AppColors.textSecondary.opacity(0.2), lineWidth: 1)
            )
    }
}

struct OrientationButton: View {
    let orientation: StripOrientation
    let isSelected: Bool
    var isCompact: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: isCompact ? 10 : 14) {
                // Visual preview of the layout
                layoutPreview
                
                Text(orientation.rawValue)
                    .font(.system(size: isCompact ? 13 : 16, weight: .medium))
                    .foregroundColor(isSelected ? AppColors.accent : AppColors.textSecondary)
            }
            .frame(width: isCompact ? 110 : 160, height: isCompact ? 110 : 150)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(isSelected ? AppColors.accent.opacity(0.12) : Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(isSelected ? AppColors.accent.opacity(0.4) : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(isSelected ? 0.06 : 0.03), radius: 10, x: 0, y: 5)
            )
        }
    }
    
    @ViewBuilder
    private var layoutPreview: some View {
        let fillColor = isSelected ? AppColors.accent : AppColors.textSecondary.opacity(0.4)
        
        if orientation == .vertical {
            // vertical strip preview — tall, narrow with stacked frames
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.8))
                .frame(width: 36, height: 64)
                .overlay(
                    VStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(fillColor)
                                .frame(width: 26, height: 14)
                        }
                    }
                    .padding(3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(fillColor.opacity(0.5), lineWidth: 1)
                )
        } else if orientation == .square {
            // grid preview — square with 2x2 grid
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.8))
                .frame(width: 64, height: 64)
                .overlay(
                    VStack(spacing: 3) {
                        HStack(spacing: 3) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(fillColor)
                                .frame(width: 22, height: 22)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(fillColor)
                                .frame(width: 22, height: 22)
                        }
                        HStack(spacing: 3) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(fillColor)
                                .frame(width: 22, height: 22)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(fillColor)
                                .frame(width: 22, height: 22)
                        }
                    }
                    .padding(4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(fillColor.opacity(0.5), lineWidth: 1)
                )
        } else {
            // polaroid preview — square image with thick bottom margin
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.8))
                .frame(width: 52, height: 64)
                .overlay(
                    VStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(fillColor)
                            .frame(width: 40, height: 40)
                            .padding(.top, 5)
                        Spacer()
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(fillColor.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

#Preview {
    BoothSetupScreen(onEnterBooth: {}, onBack: {})
        .environmentObject(BoothSettings())
}
