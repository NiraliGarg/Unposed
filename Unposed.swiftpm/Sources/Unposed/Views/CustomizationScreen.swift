import SwiftUI
import Photos
import PhotosUI

struct CustomizationScreen: View {
    @EnvironmentObject var settings: BoothSettings
    @EnvironmentObject var captureSession: CaptureSession
    
    let onBack: () -> Void
    let onStartOver: () -> Void
    
    @State private var selectedBackgroundType: BackgroundType = .solid
    @State private var selectedSolidColor: SolidBackgroundColor = .pureWhite
    @State private var selectedPattern: PatternBackground = .pattern1
    @State private var customColor: Color = .white
    @State private var isUsingCustomColor: Bool = false
    @State private var showingColorPicker: Bool = false
    @State private var customPatternImages: [UIImage] = []
    @State private var selectedCustomPatternIndex: Int? = nil
    @State private var isUsingCustomPattern: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    @State private var selectedAccent: AccentOverlay? = nil
    
    @State private var personalMessage: String = ""
    @State private var showDate: Bool = false
    @State private var signature: String = ""
    
    @State private var showContent = false
    @State private var isSaving = false
    @State private var activeSection: CustomizationSection = .background
    
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    
    private let captureDate = Date()
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            FloatingShapesBackground()
                .opacity(0.3)
            
            VStack(spacing: 0) {
                headerView
                
                // iPad split layout: controls left, strip preview right
                GeometryReader { splitGeo in
                    splitLayout(
                        totalWidth: splitGeo.size.width,
                        totalHeight: splitGeo.size.height
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
        .overlay(
            // Success feedback overlay
            Group {
                if showSaveSuccess {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                        Text("Saved to Photos!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.8))
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3), value: showSaveSuccess)
        )
        .alert("Unable to Save", isPresented: $showSaveError) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }
    
    // strip natural dimensions per orientation (must match CustomizableStripPreview's layout)
    private func stripNaturalSize() -> (width: CGFloat, height: CGFloat) {
        let maxDetailsHeight: CGFloat = 42
        switch settings.orientation {
        case .vertical:
            let frameCount = max(captureSession.capturedFrames.count, 3)
            let photosHeight: CGFloat = 137 * CGFloat(frameCount) + 8 * CGFloat(frameCount - 1)
            return (200, 13 + photosHeight + 38 + maxDetailsHeight)
        case .square:
            let cols = 2
            let rows = (max(captureSession.capturedFrames.count, 4) + cols - 1) / cols
            let photosHeight: CGFloat = 110 * CGFloat(rows) + 8 * CGFloat(rows - 1)
            return ((110 * CGFloat(cols)) + 8 + (14 * 2), 14 + photosHeight + 10 + 14 + 16 + maxDetailsHeight)
        case .polaroid:
            return (200 + (13 * 2), 13 + 200 + 50 + maxDetailsHeight)
        }
    }
    
    // Split Layout Helper
    @ViewBuilder
    private func splitLayout(totalWidth: CGFloat, totalHeight: CGFloat) -> some View {
        let isCompact = totalWidth < 600
        
        if isCompact {
            compactLayout(totalWidth: totalWidth, totalHeight: totalHeight)
        } else {
            wideSplitLayout(totalWidth: totalWidth, totalHeight: totalHeight)
        }
    }
    
    // iPhone / narrow portrait: strip preview on top, controls below in a single scroll
    @ViewBuilder
    private func compactLayout(totalWidth: CGFloat, totalHeight: CGFloat) -> some View {
        let naturalWidth: CGFloat = stripNaturalSize().width
        let naturalHeight: CGFloat = stripNaturalSize().height
        
        // fit strip preview into roughly 40% of screen height
        let previewMaxHeight: CGFloat = totalHeight * 0.38
        let previewScale: CGFloat = min(
            (totalWidth - 40) / naturalWidth,
            previewMaxHeight / naturalHeight
        )
        let scaledWidth = naturalWidth * previewScale
        let scaledHeight = naturalHeight * previewScale
        
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // strip preview centered at the top
                CustomizableStripPreview(
                    frames: captureSession.capturedFrames,
                    orientation: settings.orientation,
                    backgroundType: selectedBackgroundType,
                    solidColor: selectedSolidColor,
                    pattern: selectedPattern,
                    selectedAccent: selectedAccent,
                    personalMessage: personalMessage,
                    showDate: showDate,
                    captureDate: captureDate,
                    signature: signature,
                    isUsingCustomColor: isUsingCustomColor,
                    customColor: customColor,
                    customPatternImage: activeCustomPatternImage
                )
                .frame(width: naturalWidth, height: naturalHeight)
                .scaleEffect(previewScale, anchor: .center)
                .frame(width: scaledWidth, height: scaledHeight)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.3), value: selectedBackgroundType)
                .animation(.spring(response: 0.3), value: selectedSolidColor)
                .animation(.spring(response: 0.3), value: customColor)
                .animation(.spring(response: 0.3), value: isUsingCustomColor)
                
                // controls below
                VStack(alignment: .leading, spacing: 24) {
                    sectionTabs
                        .opacity(showContent ? 1 : 0)
                    
                    Group {
                        switch activeSection {
                        case .background:
                            backgroundSection
                        case .stickers:
                            stickersSection
                        case .details:
                            detailsSection
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: activeSection)
                    
                    Spacer().frame(height: 8)
                    
                    saveButtonsSection
                        .opacity(showContent ? 1 : 0)
                    
                    Spacer().frame(height: 30)
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
        }
    }
    
    // iPad / wide layout: strip preview on the left, controls on the right
    @ViewBuilder
    private func wideSplitLayout(totalWidth: CGFloat, totalHeight: CGFloat) -> some View {
        // horizontal margins
        let leadingPadding: CGFloat = 16
        let gapBetweenPanels: CGFloat = 8
        let trailingPadding: CGFloat = 40
        
        // usable width after subtracting margins
        let usableWidth: CGFloat = totalWidth - leadingPadding - gapBetweenPanels - trailingPadding
        
        // in portrait, give the strip less room so controls aren't cramped
        let isPortrait = totalWidth < totalHeight
        let stripFraction: CGFloat = isPortrait ? 0.42 : 0.50
        
        let stripPanelWidth: CGFloat = usableWidth * stripFraction
        let controlsPanelWidth: CGFloat = usableWidth * (1 - stripFraction)
        
        let naturalWidth: CGFloat = stripNaturalSize().width
        let naturalHeight: CGFloat = stripNaturalSize().height
        let aspectRatio: CGFloat = naturalWidth / naturalHeight
        
        // available space for the strip inside its panel
        let availableStripWidth: CGFloat = stripPanelWidth
        let availableStripHeight: CGFloat = totalHeight - 16  // minimal breathing room
        
        // scale to fit, preserving aspect ratio
        let scaledByWidth: CGFloat = availableStripWidth
        let scaledByHeight: CGFloat = availableStripHeight * aspectRatio
        let scaledWidth: CGFloat = min(scaledByWidth, scaledByHeight)
        let scaledHeight: CGFloat = scaledWidth / aspectRatio
        let scale: CGFloat = scaledWidth / naturalWidth
        
        HStack(alignment: .top, spacing: gapBetweenPanels) {
            // left panel: strip preview
            ZStack {
                CustomizableStripPreview(
                    frames: captureSession.capturedFrames,
                    orientation: settings.orientation,
                    backgroundType: selectedBackgroundType,
                    solidColor: selectedSolidColor,
                    pattern: selectedPattern,
                    selectedAccent: selectedAccent,
                    personalMessage: personalMessage,
                    showDate: showDate,
                    captureDate: captureDate,
                    signature: signature,
                    isUsingCustomColor: isUsingCustomColor,
                    customColor: customColor,
                    customPatternImage: activeCustomPatternImage
                )
                // lock to natural dimensions before scaling
                .frame(width: naturalWidth, height: naturalHeight, alignment: .center)
                // scale to fill available space
                .scaleEffect(scale, anchor: .center)
                // set layout frame to post-scale size
                .frame(width: scaledWidth, height: scaledHeight)
                .opacity(showContent ? 1 : 0)
                .animation(.spring(response: 0.3), value: selectedBackgroundType)
                .animation(.spring(response: 0.3), value: selectedSolidColor)
                .animation(.spring(response: 0.3), value: customColor)
                .animation(.spring(response: 0.3), value: isUsingCustomColor)
            }
            .frame(width: stripPanelWidth, height: totalHeight)
            .clipped()
            
            // right panel: controls
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    sectionTabs
                        .opacity(showContent ? 1 : 0)
                    
                    Group {
                        switch activeSection {
                        case .background:
                            backgroundSection
                        case .stickers:
                            stickersSection
                        case .details:
                            detailsSection
                        }
                    }
                    .opacity(showContent ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: activeSection)
                    
                    Spacer().frame(height: 16)
                    
                    saveButtonsSection
                        .opacity(showContent ? 1 : 0)
                    
                    Spacer().frame(height: 40)
                }
                .padding(.top, 20)
                .padding(.leading, 8)
            }
            .frame(width: controlsPanelWidth)
        }
        .padding(.leading, leadingPadding)
        .padding(.trailing, trailingPadding)
        .frame(width: totalWidth, height: totalHeight)
    }
    
    // Header
    
    private var headerView: some View {
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
            
            Spacer()
            
            Text("Personalize")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
    
    // Section Tabs
    private var sectionTabs: some View {
        HStack(spacing: 0) {
            ForEach(CustomizationSection.allCases, id: \.self) { section in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        activeSection = section
                    }
                    HapticManager.shared.buttonTap()
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: section.icon)
                            .font(.system(size: 18))
                        Text(section.title)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(activeSection == section ? AppColors.accent : AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(activeSection == section ? AppColors.accent.opacity(0.1) : Color.clear)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // Background Section
    private var backgroundSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("TYPE")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(1)
                
                HStack(spacing: 10) {
                    ForEach(BackgroundType.allCases, id: \.self) { type in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedBackgroundType = type
                            }
                            HapticManager.shared.buttonTap()
                        }) {
                            Text(type.rawValue)
                                .font(.system(size: 13, weight: selectedBackgroundType == type ? .semibold : .regular))
                                .foregroundColor(selectedBackgroundType == type ? .white : AppColors.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(selectedBackgroundType == type ? AppColors.accent : Color.white.opacity(0.7))
                                )
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // Content based on type
            switch selectedBackgroundType {
            case .solid:
                solidColorPicker
            case .pattern:
                patternPicker
            }
        }
    }
    
    private var solidColorPicker: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 14) {
                Text("COLORS")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(1)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                    ForEach(SolidBackgroundColor.curated, id: \.self) { color in
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                selectedSolidColor = color
                                isUsingCustomColor = false
                            }
                            HapticManager.shared.buttonTap()
                        }) {
                            Circle()
                                .fill(color.color)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(selectedSolidColor == color && !isUsingCustomColor ? AppColors.accent : Color.clear, lineWidth: 3)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, 40)
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        // Custom color button / preview
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showingColorPicker.toggle()
                                if showingColorPicker {
                                    isUsingCustomColor = true
                                }
                            }
                            HapticManager.shared.buttonTap()
                        }) {
                            ZStack {
                                // Gradient ring to indicate "any color"
                                Circle()
                                    .fill(
                                        AngularGradient(
                                            colors: [.red, .orange, .yellow, .green, .blue, .purple, .red],
                                            center: .center
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                
                                // Inner circle showing current custom color or white
                                Circle()
                                    .fill(isUsingCustomColor ? customColor : Color.white)
                                    .frame(width: 40, height: 40)
                                
                                // Plus/minus icon
                                Image(systemName: showingColorPicker ? "minus" : "plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(isUsingCustomColor ? (customColor.isDark ? Color.white.opacity(0.6) : Color.black.opacity(0.6)) : AppColors.textSecondary)
                            }
                            .overlay(
                                Circle()
                                    .stroke(isUsingCustomColor ? AppColors.accent : Color.clear, lineWidth: 3)
                            )
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isUsingCustomColor ? "Custom Color" : "Tap to choose")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.textPrimary)
                            Text(showingColorPicker ? "Adjust below" : "Any color you want")
                                .font(.system(size: 11))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Spacer()
                    }
                    
                    if showingColorPicker {
                        InlineColorPicker(selectedColor: $customColor)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)),
                                removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                            ))
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: 500)
    }
    
    private var activeCustomPatternImage: UIImage? {
        guard isUsingCustomPattern, let index = selectedCustomPatternIndex,
              index < customPatternImages.count else { return nil }
        return customPatternImages[index]
    }
    
    private var patternPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PATTERN")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .tracking(1)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                // Built-in patterns
                ForEach(PatternBackground.allCases, id: \.self) { pattern in
                    Button(action: {
                        selectedPattern = pattern
                        isUsingCustomPattern = false
                        selectedCustomPatternIndex = nil
                        HapticManager.shared.buttonTap()
                    }) {
                        ZStack {
                            if let patternImage = pattern.image {
                                Image(uiImage: patternImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(pattern.preview)
                                    .frame(width: 50, height: 50)
                            }
                        }
                        .overlay(
                            Circle()
                                .stroke(!isUsingCustomPattern && selectedPattern == pattern ? AppColors.accent : Color.clear, lineWidth: 3)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                }
                
                // User-imported custom pattern images
                ForEach(Array(customPatternImages.enumerated()), id: \.offset) { index, image in
                    Button(action: {
                        selectedCustomPatternIndex = index
                        isUsingCustomPattern = true
                        selectedBackgroundType = .pattern
                        HapticManager.shared.buttonTap()
                    }) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(isUsingCustomPattern && selectedCustomPatternIndex == index ? AppColors.accent : Color.clear, lineWidth: 3)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                }
                
                // Add from gallery button — always at the end
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.7))
                            .frame(width: 50, height: 50)
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                .onChange(of: selectedPhotoItem) { newItem in
                    guard let newItem else { return }
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            customPatternImages.append(image)
                            selectedCustomPatternIndex = customPatternImages.count - 1
                            isUsingCustomPattern = true
                            selectedBackgroundType = .pattern
                            selectedPhotoItem = nil
                            HapticManager.shared.buttonTap()
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
    }
    
    // Stickers Section
    private var stickersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PRINT OVERLAYS")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .tracking(1)
                .padding(.horizontal, 24)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 14) {
                // None option
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedAccent = nil
                    }
                    HapticManager.shared.buttonTap()
                }) {
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 60, height: 60)
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .light))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedAccent == nil ? AppColors.accent : Color.clear, lineWidth: 2)
                        )
                        Text("None")
                            .font(.system(size: 10))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
                
                ForEach(AccentOverlay.allCases, id: \.self) { accent in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedAccent = accent
                        }
                        HapticManager.shared.buttonTap()
                    }) {
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 60, height: 60)
                                
                                // Preview of accent pattern
                                accent.previewView
                                    .frame(width: 50, height: 50)
                                    .clipped()
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedAccent == accent ? AppColors.accent : Color.clear, lineWidth: 2)
                            )
                            Text(accent.name)
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Personal message
            VStack(alignment: .leading, spacing: 10) {
                Text("MESSAGE")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(1)
                
                TextField("a quiet moment...", text: $personalMessage)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    )
                    .onChange(of: personalMessage) { _, newValue in
                        if newValue.count > 34 {
                            personalMessage = String(newValue.prefix(34))
                        }
                    }
                
                Text("\(personalMessage.count)/34")
                    .font(.system(size: 10))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 24)
            
            // Signature - immediately after message
            VStack(alignment: .leading, spacing: 10) {
                Text("INITIALS / SIGNATURE")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .tracking(1)
                
                TextField("your initials", text: $signature)
                    .font(.custom("Snell Roundhand", size: 20))
                    .foregroundColor(AppColors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
                    )
                    .onChange(of: signature) { _, newValue in
                        if newValue.count > 15 {
                            signature = String(newValue.prefix(15))
                        }
                    }
            }
            .padding(.horizontal, 24)
            
            // Date toggle - styled as timestamp option
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Timestamp")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Printed along the strip edge")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Custom toggle button so the off-state is clearly visible
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showDate.toggle()
                        }
                    } label: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(showDate ? AppColors.accent : Color.white.opacity(0.25))
                            .frame(width: 51, height: 31)
                            .overlay(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                                    .frame(width: 27, height: 27)
                                    .offset(x: showDate ? 10 : -10),
                                alignment: .center
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // Save Buttons
    private var saveButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: saveStripToPhotos) {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "square.and.arrow.down")
                    }
                    Text("Save to Photos")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    Capsule()
                        .fill(AppColors.accentGradient)
                        .shadow(color: AppColors.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                )
            }
            .disabled(isSaving)
            
            Button(action: {
                HapticManager.shared.buttonTap()
                onStartOver()
            }) {
                Text("Start Over")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, 6)
        }
        .padding(.horizontal, 30)
    }
    
    // Save Logic
    
    private func saveStripToPhotos() {
        isSaving = true
        HapticManager.shared.buttonTap()
        
        // Check current authorization status
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .authorized, .limited:
            // Permission granted, proceed to save
            performSave()
        case .notDetermined:
            // Request permission
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        performSave()
                    } else {
                        handleSaveError("Please allow access to Photos in Settings to save your photo strip.")
                    }
                }
            }
        case .denied, .restricted:
            // Permission denied
            handleSaveError("Photo library access is denied. Please enable it in Settings > Privacy > Photos.")
        @unknown default:
            handleSaveError("Unable to access Photos library.")
        }
    }
    
    @MainActor
    private func performSave() {
        guard let image = renderPreviewAsImage() else {
            handleSaveError("Failed to create your photo strip. Please try again.")
            return
        }
        
        // Save using PHPhotoLibrary for reliable saving
        PHPhotoLibrary.shared().performChanges {
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .photo, data: image.pngData() ?? Data(), options: nil)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                isSaving = false
                
                if success {
                    HapticManager.shared.success()
                    showSaveSuccess = true
                    
                    // Auto-hide success message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation {
                            showSaveSuccess = false
                        }
                    }
                } else {
                    let errorMessage = error?.localizedDescription ?? "Unknown error occurred"
                    handleSaveError("Failed to save: \(errorMessage)")
                }
            }
        }
    }
    
    private func handleSaveError(_ message: String) {
        isSaving = false
        saveErrorMessage = message
        showSaveError = true
        HapticManager.shared.error()
    }
    
    // renders the SwiftUI preview at export resolution
    
    @MainActor
    private func renderPreviewAsImage() -> UIImage? {
        let frames = captureSession.capturedFrames
        guard !frames.isEmpty else { return nil }
        
        let previewView = CustomizableStripPreview(
            frames: frames,
            orientation: settings.orientation,
            backgroundType: selectedBackgroundType,
            solidColor: selectedSolidColor,
            pattern: selectedPattern,
            selectedAccent: selectedAccent,
            personalMessage: personalMessage,
            showDate: showDate,
            captureDate: captureDate,
            signature: signature,
            isUsingCustomColor: isUsingCustomColor,
            customColor: customColor,
            customPatternImage: activeCustomPatternImage
        )
        
        let renderer = ImageRenderer(content: previewView)
        renderer.scale = 3.0
        
        return renderer.uiImage
    }
}

#Preview {
    CustomizationScreen(onBack: {}, onStartOver: {})
        .environmentObject(BoothSettings())
        .environmentObject(CaptureSession())
}
