import SwiftUI

struct InlineColorPicker: View {
    @Binding var selectedColor: Color
    
    @State private var sliderPosition: Double = 0.5
    @State private var hasInitialized = false
    
    // Fixed saturation and brightness for vibrant, photo-friendly colors
    private let saturation: Double = 0.65
    private let brightness: Double = 0.92
    
    var body: some View {
        VStack(spacing: 20) {
            // Single spectrum slider - playful and effortless
            GeometryReader { geometry in
                let thumbSize: CGFloat = 36
                let trackHeight: CGFloat = 44
                
                ZStack(alignment: .leading) {
                    // Smooth rainbow spectrum track
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(
                            LinearGradient(
                                colors: spectrumColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: trackHeight)
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                    
                    // Soft glow behind thumb
                    Circle()
                        .fill(selectedColor.opacity(0.4))
                        .frame(width: thumbSize + 16, height: thumbSize + 16)
                        .blur(radius: 8)
                        .offset(x: sliderPosition * (geometry.size.width - thumbSize) - 8)
                    
                    // Thumb
                    Circle()
                        .fill(selectedColor)
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
                        .offset(x: sliderPosition * (geometry.size.width - thumbSize))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let newPosition = max(0, min(1, value.location.x / geometry.size.width))
                                    sliderPosition = newPosition
                                    updateColor()
                                }
                        )
                }
                .frame(height: trackHeight)
            }
            .frame(height: 44)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 12)
        .onAppear {
            if !hasInitialized {
                extractPosition(from: selectedColor)
                hasInitialized = true
            }
        }
    }
    
    // Smooth spectrum colors for the track
    private var spectrumColors: [Color] {
        stride(from: 0.0, through: 1.0, by: 0.05).map { hue in
            Color(hue: hue, saturation: saturation, brightness: brightness)
        }
    }
    
    private func updateColor() {
        selectedColor = Color(hue: sliderPosition, saturation: saturation, brightness: brightness)
    }
    
    private func extractPosition(from color: Color) {
        let uiColor = UIColor(color)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        sliderPosition = Double(h)
    }
}
