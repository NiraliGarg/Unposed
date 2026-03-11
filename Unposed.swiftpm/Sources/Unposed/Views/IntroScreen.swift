import SwiftUI

struct IntroScreen: View {
    let onStart: () -> Void
    
    @State private var showContent = false
    @State private var showButton = false
    @State private var buttonScale: CGFloat = 1.0
    
    // Ambient gradient shift
    @State private var gradientPhase: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            
            ZStack {
                // soft pink gradient background with ambient shift
                ambientBackground
                
                // floating animated shapes
                FloatingShapesBackground()
                
                // content
                VStack(spacing: isLandscape ? 36 : 56) {
                    Spacer()
                    
                    // title and tagline
                    VStack(spacing: 22) {
                        Image("Unposed")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, -20)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Real moments, not poses.")
                            .font(.system(size: 18, weight: .regular))
                            .tracking(2.5)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    
                    Spacer()
                    
                    // enter photobooth button
                    Button(action: {
                        HapticManager.shared.buttonTap()
                        withAnimation(.spring(response: 0.3)) {
                            buttonScale = 0.95
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            onStart()
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 17))
                            Text("Pull The Curtain")
                                .font(.system(size: 19, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: 380)
                        .frame(height: 58)
                        .background(
                            Capsule()
                                .fill(AppColors.accentGradient)
                                .shadow(color: AppColors.accent.opacity(0.30), radius: 20, x: 0, y: 10)
                                .shadow(color: AppColors.accent.opacity(0.10), radius: 6, x: 0, y: 3)
                        )
                    }
                    .scaleEffect(buttonScale)
                    .opacity(showButton ? 1 : 0)
                    .offset(y: showButton ? 0 : 20)
                    .padding(.horizontal, 8)
                    
                    Spacer()
                        .frame(height: isLandscape ? 40 : 80)
                }
                .frame(maxWidth: 540)
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            animateEntrance()
            startAmbientGradient()
        }
    }
    
    // Ambient Background
    
    private var ambientBackground: some View {
        ZStack {
            // base gradient
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            // slow-moving radial glow
            RadialGradient(
                colors: [
                    AppColors.accentLight.opacity(0.12),
                    Color.clear
                ],
                center: UnitPoint(
                    x: 0.3 + 0.4 * sin(gradientPhase),
                    y: 0.3 + 0.4 * cos(gradientPhase * 0.7)
                ),
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            .blendMode(.normal)
        }
    }
    
    // Animations
    
    private func animateEntrance() {
        withAnimation(.easeOut(duration: 0.7).delay(0.3)) {
            showContent = true
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.7)) {
            showButton = true
        }
        
        // Subtle button pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                buttonScale = 1.04
            }
        }
    }
    
    private func startAmbientGradient() {
        withAnimation(.easeInOut(duration: 12).repeatForever(autoreverses: true)) {
            gradientPhase = .pi * 2
        }
    }
}

#Preview {
    IntroScreen(onStart: {})
}
