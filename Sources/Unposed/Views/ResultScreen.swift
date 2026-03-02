import SwiftUI
struct ResultScreen: View {
    @EnvironmentObject var settings: BoothSettings
    @EnvironmentObject var captureSession: CaptureSession
    let onCustomize: () -> Void
    let onRetake: () -> Void
    
    @State private var stripOffset: CGFloat = 500
    @State private var showStrip = false
    @State private var showButtons = false
    @State private var isAnimatingFrames = false
    @State private var currentAnimatingFrame = 0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                FloatingShapesBackground()
                    .opacity(0.4)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Text("Your Strip")
                            .font(.system(size: 38, weight: .light, design: .serif))
                            .foregroundColor(AppColors.textPrimary)
                            .opacity(showStrip ? 1 : 0)
                            .padding(.top, 20)
                        
                        Spacer(minLength: 4)
                        
                        // strip preview, scaled to fit
                        PhotoStripView(
                            frames: captureSession.capturedFrames,
                            orientation: settings.orientation,
                            isAnimating: isAnimatingFrames,
                            currentAnimatingFrame: currentAnimatingFrame
                        )
                        // Rasterize at full resolution before scaling for crisp text rendering
                        .drawingGroup(opaque: false)
                        .scaleEffect(stripScale(for: geo.size))
                        // reserve layout space equal to the scaled height
                        // (scaleEffect alone doesn't shrink the layout frame)
                        .frame(height: scaledStripHeight(for: geo.size))
                        .offset(y: stripOffset)
                        .opacity(showStrip ? 1 : 0)
                        
                        Spacer(minLength: 4)
                        
                        VStack(spacing: 10) {
                            Button(action: {
                                HapticManager.shared.buttonTap()
                                onCustomize()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "paintpalette.fill")
                                    Text("Customize Strip")
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    Capsule()
                                        .fill(AppColors.accentGradient)
                                        .shadow(color: AppColors.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                                )
                            }
                            
                            HStack(spacing: 14) {
                                Button(action: {
                                    HapticManager.shared.buttonTap()
                                    onRetake()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("Retake")
                                    }
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.7))
                                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                                    )
                                }
                                
                                Button(action: saveStrip) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.down")
                                        Text("Save")
                                    }
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.7))
                                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: 460)
                        .padding(.horizontal, 40)
                        .opacity(showButtons ? 1 : 0)
                        .offset(y: showButtons ? 0 : 20)
                        
                        Spacer().frame(height: 12)
                    }
                    // minHeight = screen height so portrait fills the screen
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
            }
        }
        .onAppear {
            animateStripReveal()
        }
    }
    
    // intrinsic height of the strip before scaling
    private func intrinsicStripHeight() -> CGFloat {
        if settings.orientation == .vertical {
            let photoHeight: CGFloat = (320 - 28) * 0.75
            return 20 + (photoHeight * CGFloat(captureSession.capturedFrames.count))
                + (12 * CGFloat(max(0, captureSession.capturedFrames.count - 1))) + 60
        } else if settings.orientation == .polaroid {
            return 20 + 320 + 80
        } else {
            let columns = 2
            let rows = (captureSession.capturedFrames.count + columns - 1) / columns
            let photoSize = (420 - 40) / CGFloat(columns) - 6
            return 20 + (photoSize * CGFloat(rows)) + (12 * CGFloat(max(0, rows - 1))) + 60
        }
    }
    
    // intrinsic width of the strip before scaling
    private func intrinsicStripWidth() -> CGFloat {
        if settings.orientation == .vertical || settings.orientation == .polaroid {
            return 360
        }
        return 420
    }
    
    // scale so the strip fits within the available area
    private func stripScale(for size: CGSize) -> CGFloat {
        // reserve space for header, buttons, and breathing room
        let reservedVertical: CGFloat = 210
        let availableHeight = max(size.height - reservedVertical, 100)
        let availableWidth = min(size.width - 80, 500) // side padding
        
        let iH = intrinsicStripHeight()
        let iW = intrinsicStripWidth()
        
        // Scale to fit height, then clamp so it also fits width
        let scaleByHeight = (availableHeight * 0.92) / max(iH, 1)
        let scaleByWidth = availableWidth / max(iW, 1)
        let scale = min(scaleByHeight, scaleByWidth)
        
        let maxScale: CGFloat = settings.orientation == .square ? 2.2 : 1.8
        return min(max(scale, 0.5), maxScale)
    }
    
    // layout height to reserve for the strip after scaling
    private func scaledStripHeight(for size: CGSize) -> CGFloat {
        return intrinsicStripHeight() * stripScale(for: size)
    }
    
    private func animateStripReveal() {
        HapticManager.shared.stripReveal()
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
            showStrip = true
            stripOffset = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            startFrameAnimations()
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(1.5)) {
            showButtons = true
        }
    }
    
    private func startFrameAnimations() {
        isAnimatingFrames = true
        
        for i in 0..<captureSession.capturedFrames.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentAnimatingFrame = i
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(captureSession.capturedFrames.count) * 0.4 + 0.5) {
            isAnimatingFrames = false
        }
    }
    
    private func saveStrip() {
        HapticManager.shared.buttonTap()
        
        guard let stripImage = createStripImage() else { return }
        
        UIImageWriteToSavedPhotosAlbum(stripImage, nil, nil, nil)
        HapticManager.shared.success()
    }
    
    private func createStripImage() -> UIImage? {
        let frames = captureSession.capturedFrames
        guard !frames.isEmpty else { return nil }
        
        if settings.orientation == .vertical {
            return createVerticalStripImage(frames: frames)
        } else if settings.orientation == .polaroid {
            return createPolaroidStripImage(frames: frames)
        } else {
            return createGridStripImage(frames: frames)
        }
    }
    
    private func createVerticalStripImage(frames: [CapturedFrame]) -> UIImage? {
        // photobooth strip dimensions
        let photoWidth: CGFloat = 400
        let photoHeight: CGFloat = 300 // 4:3 aspect ratio
        let photoSpacing: CGFloat = 16
        let horizontalPadding: CGFloat = 24
        let topPadding: CGFloat = 28
        let bottomPadding: CGFloat = 48 // Space for branding
        let cornerRadius: CGFloat = 12
        
        // Calculate total strip size
        let stripWidth = photoWidth + (horizontalPadding * 2)
        let photosHeight = (photoHeight * CGFloat(frames.count)) + (photoSpacing * CGFloat(frames.count - 1))
        let stripHeight = topPadding + photosHeight + bottomPadding
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: stripWidth, height: stripHeight))
        
        return renderer.image { context in
            // Soft off-white background
            UIColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1).setFill()
            
            // Draw rounded container
            let containerPath = UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: CGSize(width: stripWidth, height: stripHeight)),
                cornerRadius: 20
            )
            containerPath.fill()
            
            // Draw each photo frame
            for (index, frame) in frames.enumerated() {
                let yPosition = topPadding + (CGFloat(index) * (photoHeight + photoSpacing))
                let photoRect = CGRect(
                    x: horizontalPadding,
                    y: yPosition,
                    width: photoWidth,
                    height: photoHeight
                )
                
                drawPhotoInRect(frame.image, rect: photoRect, cornerRadius: cornerRadius, context: context)
            }
            
            // Draw branding
            drawBranding(in: CGRect(x: 0, y: stripHeight - bottomPadding + 10, width: stripWidth, height: 30))
        }
    }
    
    private func createGridStripImage(frames: [CapturedFrame]) -> UIImage? {
        // grid: always 2 columns, compute rows from count
        let columns = 2
        let rows = (frames.count + columns - 1) / columns
        
        let photoSize: CGFloat = 280
        let photoSpacing: CGFloat = 16
        let containerPadding: CGFloat = 28
        let bottomPadding: CGFloat = 48
        let cornerRadius: CGFloat = 12
        
        // Calculate grid size
        let gridWidth = (photoSize * CGFloat(columns)) + (photoSpacing * CGFloat(columns - 1)) + (containerPadding * 2)
        let photosHeight = (photoSize * CGFloat(rows)) + (photoSpacing * CGFloat(rows - 1))
        let gridHeight = containerPadding + photosHeight + bottomPadding
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: gridWidth, height: gridHeight))
        
        return renderer.image { context in
            // Soft off-white background
            UIColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1).setFill()
            
            // Draw rounded container
            let containerPath = UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: CGSize(width: gridWidth, height: gridHeight)),
                cornerRadius: 20
            )
            containerPath.fill()
            
            // Draw each photo in grid
            for row in 0..<rows {
                for col in 0..<columns {
                    let index = row * columns + col
                    guard index < frames.count else { continue }
                    
                    let xPosition = containerPadding + (CGFloat(col) * (photoSize + photoSpacing))
                    let yPosition = containerPadding + (CGFloat(row) * (photoSize + photoSpacing))
                    let photoRect = CGRect(x: xPosition, y: yPosition, width: photoSize, height: photoSize)
                    
                    drawPhotoInRect(frames[index].image, rect: photoRect, cornerRadius: cornerRadius, context: context)
                }
            }
            
            // Draw branding
            drawBranding(in: CGRect(x: 0, y: gridHeight - bottomPadding + 10, width: gridWidth, height: 30))
        }
    }
    
    private func createPolaroidStripImage(frames: [CapturedFrame]) -> UIImage? {
        guard let frame = frames.first else { return nil }
        
        let photoSize: CGFloat = 400
        let sidePadding: CGFloat = 28
        let topPadding: CGFloat = 28
        let bottomPadding: CGFloat = 100
        let cornerRadius: CGFloat = 12
        
        let stripWidth = photoSize + (sidePadding * 2)
        let stripHeight = topPadding + photoSize + bottomPadding
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: stripWidth, height: stripHeight))
        
        return renderer.image { context in
            UIColor(red: 0.98, green: 0.97, blue: 0.95, alpha: 1).setFill()
            
            let containerPath = UIBezierPath(
                roundedRect: CGRect(origin: .zero, size: CGSize(width: stripWidth, height: stripHeight)),
                cornerRadius: 20
            )
            containerPath.fill()
            
            let photoRect = CGRect(x: sidePadding, y: topPadding, width: photoSize, height: photoSize)
            drawPhotoInRect(frame.image, rect: photoRect, cornerRadius: cornerRadius, context: context)
            
            drawBranding(in: CGRect(x: 0, y: stripHeight - bottomPadding + 20, width: stripWidth, height: 30))
        }
    }
    
    private func drawPhotoInRect(_ image: UIImage, rect: CGRect, cornerRadius: CGFloat, context: UIGraphicsImageRendererContext) {
        let normalizedImage = image.normalizedOrientation()
        
        // Create rounded clipping path
        let photoPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        context.cgContext.saveGState()
        photoPath.addClip()
        
        // Calculate aspect-fill drawing rect
        let imageAspect = normalizedImage.size.width / normalizedImage.size.height
        let frameAspect = rect.width / rect.height
        
        var drawRect = rect
        if imageAspect > frameAspect {
            let newWidth = rect.height * imageAspect
            drawRect = CGRect(
                x: rect.origin.x - (newWidth - rect.width) / 2,
                y: rect.origin.y,
                width: newWidth,
                height: rect.height
            )
        } else {
            let newHeight = rect.width / imageAspect
            drawRect = CGRect(
                x: rect.origin.x,
                y: rect.origin.y - (newHeight - rect.height) / 2,
                width: rect.width,
                height: newHeight
            )
        }
        
        normalizedImage.draw(in: drawRect)
        context.cgContext.restoreGState()
    }
    
    private func drawBranding(in rect: CGRect) {
        guard let logoImage = UIImage(named: "Unposed for Strip") else { return }
        
        // stretch the logo to 60% of the branding rect width, capped at original height
        let logoAspect = logoImage.size.width / logoImage.size.height
        let logoWidth: CGFloat = rect.width * 0.6
        let logoHeight: CGFloat = min(logoWidth / logoAspect, rect.height)
        let logoX = rect.origin.x + (rect.width - logoWidth) / 2
        let logoY = rect.origin.y + (rect.height - logoHeight) / 2
        let logoRect = CGRect(x: logoX, y: logoY, width: logoWidth, height: logoHeight)
        
        logoImage.draw(in: logoRect)
    }
}

#Preview {
    ResultScreen(onCustomize: {}, onRetake: {})
        .environmentObject(BoothSettings())
        .environmentObject(CaptureSession())
}
