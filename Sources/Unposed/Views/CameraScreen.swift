import SwiftUI

struct CameraScreen: View {
    @EnvironmentObject var settings: BoothSettings
    @EnvironmentObject var captureSession: CaptureSession
    @EnvironmentObject var propStore: PropStore
    
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var misdirectionEngine: MisdirectionEngine
    @StateObject private var propTracker = PropTracker()
    
    let onCaptureComplete: () -> Void
    let onBack: () -> Void
    
    @State private var isCapturing = false
    @State private var showFlash = false
    @State private var apertureOpenAmount: CGFloat = 0.8
    @State private var apertureRotation: Double = 0
    @State private var flipRotation: Double = 0
    @State private var isFlipping = false
    @State private var showPropPicker = true
    
    init(onCaptureComplete: @escaping () -> Void, onBack: @escaping () -> Void) {
        self.onCaptureComplete = onCaptureComplete
        self.onBack = onBack
        _misdirectionEngine = StateObject(wrappedValue: MisdirectionEngine(settings: BoothSettings()))
    }
    
    var body: some View {
        ZStack {
            if cameraManager.isCameraReady {
                GeometryReader { geo in
                    ZStack {
                        CameraPreviewView(cameraManager: cameraManager)
                            .ignoresSafeArea()
                        
                        // real-time prop overlay
                        if let prop = propStore.selectedProp,
                           let landmarks = propTracker.faceLandmarks,
                           propTracker.isFaceDetected || propTracker.isHandDetected {
                            PropOverlayView(prop: prop, landmarks: landmarks)
                                .allowsHitTesting(false)
                                .transition(.opacity)
                        }
                    }
                    .onAppear {
                        propTracker.viewSize = geo.size
                    }
                    .onChange(of: geo.size) { _, newSize in
                        propTracker.viewSize = newSize
                    }
                }
                .ignoresSafeArea()
                .rotation3DEffect(
                    .degrees(flipRotation),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.5
                )
                .opacity(isFlipping ? 0.7 : 1)
            } else {
                Color.black.ignoresSafeArea()
                
                if !cameraManager.isAuthorized {
                    CameraPermissionView()
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            
            // fake flash overlay
            if showFlash || misdirectionEngine.showFakeFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            if misdirectionEngine.showEmojiOverlay {
                Text(misdirectionEngine.currentEmoji)
                    .font(.system(size: 80))
                    .shadow(color: .black.opacity(0.4), radius: 8)
                    .transition(.scale.combined(with: .opacity))
                    .allowsHitTesting(false)
            }
            
            VStack {
                HStack {
                    Button(action: flipCamera) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.4)))
                    }
                    
                    Spacer()
                    
                    if !isCapturing {
                        Button(action: {
                            HapticManager.shared.buttonTap()
                            onBack()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Circle().fill(Color.black.opacity(0.4)))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // countdown display
                if misdirectionEngine.showCountdownNumber {
                    Text("\(misdirectionEngine.countdownValue)")
                        .font(.system(size: 120, weight: .thin))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 10)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    CapturePreview(
                        frames: captureSession.capturedFrames,
                        totalFrames: settings.frameCount,
                        orientation: settings.orientation
                    )
                    .padding(.trailing, 16)
                }
                .offset(y: -80)
                
                VStack(spacing: 16) {
                    if !isCapturing {
                        Button(action: startCaptureSequence) {
                            VStack(spacing: 8) {
                                ShutterButton(
                                    openAmount: apertureOpenAmount,
                                    rotation: apertureRotation
                                )
                                .frame(width: 80, height: 80)
                                
                                Text("Begin Strip")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .disabled(!cameraManager.isCameraReady)
                    } else {
                        // capturing state
                        VStack(spacing: 8) {
                            ShutterButton(
                                openAmount: apertureOpenAmount,
                                rotation: apertureRotation
                            )
                            .frame(width: 80, height: 80)
                            
                            Text(captureSession.state.description)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.bottom, showPropPicker && !isCapturing ? 140 : 50)
            }
            
            if showPropPicker && !isCapturing {
                VStack {
                    Spacer()
                    PropPickerView(propStore: propStore)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .ignoresSafeArea(.container, edges: .bottom)
            }
        }
        .onAppear {
            // wire prop tracker to camera manager
            cameraManager.propTracker = propTracker
            cameraManager.startSession()
            misdirectionEngine.settings = settings
            startIdleAnimation()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    private func startIdleAnimation() {
        // gentle breathing animation for aperture
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            apertureOpenAmount = 0.85
        }
    }
    
    private func flipCamera() {
        HapticManager.shared.buttonTap()
        
        // Animate flip
        isFlipping = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            flipRotation = 90
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            cameraManager.switchCamera()
            
            withAnimation(.easeInOut(duration: 0.3)) {
                flipRotation = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFlipping = false
            }
        }
    }
    
    private func startCaptureSequence() {
        HapticManager.shared.buttonTap()
        
        // close aperture animation
        withAnimation(.easeIn(duration: 0.2)) {
            apertureOpenAmount = 0.1
            apertureRotation += 30
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // ensure previous frames are cleared
            captureSession.reset()

            isCapturing = true
            captureSession.state = .preparing
            
            Task {
                await captureAllFrames()
            }
        }
    }
    
    private func captureAllFrames() async {
        // start a fresh misdirection session
        misdirectionEngine.startNewSession()
        
        for frameIndex in 0..<settings.frameCount {
            captureSession.state = .capturing
            
            let misdirectionType = misdirectionEngine.selectMisdirection()
            let _ = await misdirectionEngine.executeMisdirection(type: misdirectionType)
            
            // animate shutter close
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.1)) {
                    apertureOpenAmount = 0.05
                    apertureRotation += 15
                }
            }
            
            // actually capture the photo
            await captureFrame()
            
            // variable confirmation haptic
            HapticManager.shared.variableCaptureConfirmation()
            
            await misdirectionEngine.postCaptureDecoy()
            
            // flash + shutter open animation
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.1)) {
                    showFlash = true
                }
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    showFlash = false
                    apertureOpenAmount = 0.7
                }
            }
            
            if frameIndex < settings.frameCount - 1 {
                try? await Task.sleep(nanoseconds: UInt64(settings.pauseBetweenFrames * 1_000_000_000))
            }
        }
        
        // complete
        await MainActor.run {
            captureSession.state = .complete
            isCapturing = false
            
            // Reset aperture
            withAnimation(.spring(response: 0.5)) {
                apertureOpenAmount = 0.8
            }
            
            HapticManager.shared.success()
            onCaptureComplete()
        }
    }
    
    private func captureFrame() async {
        await withCheckedContinuation { continuation in
            cameraManager.capturePhoto { [propTracker, propStore] image in
                if var capturedImage = image {
                    // composite prop onto captured image if one is selected
                    if let prop = propStore.selectedProp,
                       let landmarks = propTracker.faceLandmarks {
                        capturedImage = PropTracker.compositePropsOnto(
                            image: capturedImage,
                            prop: prop,
                            faceLandmarks: landmarks,
                            previewSize: propTracker.viewSize
                        )
                    }
                    Task { @MainActor in
                        captureSession.addFrame(capturedImage)
                    }
                }
                continuation.resume()
            }
        }
    }
}

// Prop Overlay View

// positions a prop image over the detected face landmarks
struct PropOverlayView: View {
    let prop: PropItem
    let landmarks: FaceLandmarkData
    
    var body: some View {
        if prop.usesEyeAlignment {
            // eye-aligned rendering for masks with eye cutouts
            eyeAlignedMaskView
        } else {
            // standard prop rendering
            standardPropView
        }
    }
    
    // Standard Prop View
    
    private var standardPropView: some View {
        let position = landmarks.position(for: prop.anchor)
        let size = landmarks.propSize(scale: prop.scaleMultiplier)
        let aspectRatio = prop.image.size.width / max(prop.image.size.height, 1)
        let height = size / aspectRatio
        
        // offsetY is a fraction of faceWidth, not absolute points
        let relativeOffset = prop.offsetY * landmarks.faceWidth
        
        return Image(uiImage: prop.image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: height)
            .rotationEffect(.radians(prop.anchor == .hand ? 0 : landmarks.faceAngle))
            .position(
                x: position.x,
                y: position.y + relativeOffset
            )
            .animation(.interactiveSpring(response: 0.08, dampingFraction: 0.7), value: position.x)
            .animation(.interactiveSpring(response: 0.08, dampingFraction: 0.7), value: position.y)
    }
    
    // Eye-Aligned Mask View
    
    // renders the mask by aligning its eye holes with the detected eye centers.
    // 1. scale mask so eye hole distance matches detected inter-eye distance
    // 2. calculate mask center so both eye holes land on detected eyes after rotation
    // 3. apply face-roll rotation around the mask center
    private var eyeAlignedMaskView: some View {
        // detected eye positions
        let leftEye = landmarks.leftEye
        let rightEye = landmarks.rightEye
        let detectedInterEye = landmarks.interEyeDistance
        
        // head tilt from detected eyes
        let eyeAngle = atan2(rightEye.y - leftEye.y, rightEye.x - leftEye.x)
        
        // normalized eye hole positions in the mask image (origin top-left, 0–1)
        let leftHoleNorm = prop.leftEyeHoleNormalized
        let rightHoleNorm = prop.rightEyeHoleNormalized
        
        // distance between eye holes in normalized space
        let holeDistNormX = rightHoleNorm.x - leftHoleNorm.x
        let holeDistNormY = rightHoleNorm.y - leftHoleNorm.y
        let holeDistNorm = hypot(holeDistNormX, holeDistNormY)
        
        // --- step 1: scale ---
        // maskWidth = detectedInterEye / holeDistNorm
        let maskWidth = (detectedInterEye / max(holeDistNorm, 0.001)) * prop.scaleMultiplier
        let imageAspect = prop.image.size.width / max(prop.image.size.height, 1)
        let maskHeight = maskWidth / imageAspect
        
        // --- step 2: position ---
        // midpoint of eye holes in local (unrotated) mask coords
        let holeMidLocal = CGPoint(
            x: (leftHoleNorm.x + rightHoleNorm.x) / 2 * maskWidth,
            y: (leftHoleNorm.y + rightHoleNorm.y) / 2 * maskHeight
        )
        
        // vector from mask center to eye-hole midpoint (local, unrotated)
        let maskCenterLocal = CGPoint(x: maskWidth / 2, y: maskHeight / 2)
        let offsetLocal = CGPoint(
            x: holeMidLocal.x - maskCenterLocal.x,
            y: holeMidLocal.y - maskCenterLocal.y
        )
        
        // rotate offset by face angle
        let cosA = cos(eyeAngle)
        let sinA = sin(eyeAngle)
        let rotatedOffset = CGPoint(
            x: offsetLocal.x * cosA - offsetLocal.y * sinA,
            y: offsetLocal.x * sinA + offsetLocal.y * cosA
        )
        
        // real eye midpoint in view coordinates
        let eyeMidpoint = landmarks.eyeCenter
        
        // place mask center so the rotated eye-hole midpoint lands on the real eyes
        //   maskCenter = eyeMidpoint - rotatedOffset
        let maskCenter = CGPoint(
            x: eyeMidpoint.x - rotatedOffset.x,
            y: eyeMidpoint.y - rotatedOffset.y
        )
        
        return Image(uiImage: prop.image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: maskWidth, height: maskHeight)
            .rotationEffect(.radians(eyeAngle))
            .position(x: maskCenter.x, y: maskCenter.y)
            .animation(.interactiveSpring(response: 0.08, dampingFraction: 0.7), value: maskCenter.x)
            .animation(.interactiveSpring(response: 0.08, dampingFraction: 0.7), value: maskCenter.y)
            .animation(.interactiveSpring(response: 0.08, dampingFraction: 0.7), value: eyeAngle)
    }
}

#Preview {
    CameraScreen(onCaptureComplete: {}, onBack: {})
        .environmentObject(BoothSettings())
        .environmentObject(CaptureSession())
        .environmentObject(PropStore())
}
