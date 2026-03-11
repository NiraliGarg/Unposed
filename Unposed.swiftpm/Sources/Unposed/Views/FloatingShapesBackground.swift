import SwiftUI

// animated background shapes
struct FloatingShapesBackground: View {
    @State private var elements: [EmotionalElement] = []
    @State private var isAnimating = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(elements) { element in
                    EmotionalElementView(element: element, isAnimating: isAnimating)
                }
            }
            .onAppear {
                createElements(in: geometry.size)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isAnimating = true
                }
            }
        }
    }
    
    private func createElements(in size: CGSize) {
        var newElements: [EmotionalElement] = []
        
        // hearts
        for _ in 0..<5 {
            newElements.append(EmotionalElement(
                type: .heartOutline,
                x: CGFloat.random(in: size.width * 0.1...size.width * 0.9),
                y: CGFloat.random(in: size.height * 0.1...size.height * 0.9),
                size: CGFloat.random(in: 20...45),
                opacity: Double.random(in: 0.06...0.15),
                duration: Double.random(in: 6...10),
                delay: Double.random(in: 0...3)
            ))
        }
        
        // smile curves
        for _ in 0..<4 {
            newElements.append(EmotionalElement(
                type: .smileCurve,
                x: CGFloat.random(in: size.width * 0.15...size.width * 0.85),
                y: CGFloat.random(in: size.height * 0.2...size.height * 0.8),
                size: CGFloat.random(in: 30...60),
                opacity: Double.random(in: 0.05...0.12),
                duration: Double.random(in: 7...12),
                delay: Double.random(in: 0...4)
            ))
        }
        
        // brush strokes
        for _ in 0..<4 {
            newElements.append(EmotionalElement(
                type: .brushStroke,
                x: CGFloat.random(in: size.width * 0.05...size.width * 0.95),
                y: CGFloat.random(in: size.height * 0.1...size.height * 0.9),
                size: CGFloat.random(in: 40...80),
                opacity: Double.random(in: 0.04...0.10),
                duration: Double.random(in: 8...14),
                delay: Double.random(in: 0...5)
            ))
        }
        
        // motion trails
        for _ in 0..<3 {
            newElements.append(EmotionalElement(
                type: .motionTrail,
                x: CGFloat.random(in: size.width * 0.1...size.width * 0.9),
                y: CGFloat.random(in: size.height * 0.15...size.height * 0.85),
                size: CGFloat.random(in: 50...90),
                opacity: Double.random(in: 0.03...0.08),
                duration: Double.random(in: 10...16),
                delay: Double.random(in: 0...6)
            ))
        }
        
        // fingertip circles
        for _ in 0..<3 {
            newElements.append(EmotionalElement(
                type: .fingertip,
                x: CGFloat.random(in: size.width * 0.2...size.width * 0.8),
                y: CGFloat.random(in: size.height * 0.2...size.height * 0.8),
                size: CGFloat.random(in: 15...30),
                opacity: Double.random(in: 0.08...0.18),
                duration: Double.random(in: 5...9),
                delay: Double.random(in: 0...4)
            ))
        }
        
        elements = newElements
    }
}

// Emotional Element Model

struct EmotionalElement: Identifiable {
    let id = UUID()
    let type: EmotionalElementType
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let duration: Double
    let delay: Double
}

enum EmotionalElementType {
    case heartOutline
    case smileCurve
    case brushStroke
    case motionTrail
    case fingertip
}

// Emotional Element View

struct EmotionalElementView: View {
    let element: EmotionalElement
    let isAnimating: Bool
    
    @State private var offsetY: CGFloat = 0
    @State private var offsetX: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var elementOpacity: Double = 0
    @State private var rotation: Double = 0
    
    private var elementColor: Color {
        let colors: [Color] = [
            Color(red: 0.92, green: 0.68, blue: 0.70), // Blush pink
            Color(red: 0.96, green: 0.78, blue: 0.72), // Warm peach
            Color(red: 0.90, green: 0.62, blue: 0.65), // Light rose
            Color(red: 0.94, green: 0.72, blue: 0.68), // Soft coral
            Color(red: 0.88, green: 0.65, blue: 0.70)  // Dusty rose
        ]
        return colors[abs(element.id.hashValue) % colors.count]
    }
    
    var body: some View {
        Group {
            switch element.type {
            case .heartOutline:
                HeartShape()
                    .stroke(elementColor.opacity(elementOpacity), lineWidth: 1.5)
                    .frame(width: element.size, height: element.size)
                
            case .smileCurve:
                SmileCurve()
                    .stroke(elementColor.opacity(elementOpacity), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: element.size, height: element.size * 0.4)
                
            case .brushStroke:
                BrushStroke()
                    .fill(elementColor.opacity(elementOpacity * 0.6))
                    .frame(width: element.size * 1.5, height: element.size * 0.3)
                    .blur(radius: 4)
                
            case .motionTrail:
                MotionTrail()
                    .stroke(
                        LinearGradient(
                            colors: [elementColor.opacity(0), elementColor.opacity(elementOpacity), elementColor.opacity(0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .frame(width: element.size, height: element.size * 0.2)
                    .blur(radius: 2)
                
            case .fingertip:
                Circle()
                    .stroke(elementColor.opacity(elementOpacity), lineWidth: 1)
                    .frame(width: element.size, height: element.size)
                    .overlay(
                        Circle()
                            .fill(elementColor.opacity(elementOpacity * 0.3))
                            .frame(width: element.size * 0.6, height: element.size * 0.6)
                    )
            }
        }
        .position(x: element.x, y: element.y)
        .offset(x: offsetX, y: offsetY)
        .scaleEffect(scale)
        .rotationEffect(Angle(degrees: rotation))
        .onAppear {
            if isAnimating {
                startBreathingAnimation()
            }
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                startBreathingAnimation()
            }
        }
    }
    
    private func startBreathingAnimation() {
        withAnimation(.easeIn(duration: 2).delay(element.delay)) {
            elementOpacity = element.opacity
        }
        
        // vertical drift
        withAnimation(
            .easeInOut(duration: element.duration)
            .repeatForever(autoreverses: true)
            .delay(element.delay)
        ) {
            offsetY = CGFloat.random(in: -20...20)
        }
        
        // horizontal sway
        withAnimation(
            .easeInOut(duration: element.duration * 1.3)
            .repeatForever(autoreverses: true)
            .delay(element.delay + 0.5)
        ) {
            offsetX = CGFloat.random(in: -10...10)
        }
        
        // scale breathing
        withAnimation(
            .easeInOut(duration: element.duration * 0.6)
            .repeatForever(autoreverses: true)
            .delay(element.delay)
        ) {
            scale = CGFloat.random(in: 0.92...1.08)
        }
        
        // slow rotation
        withAnimation(
            .easeInOut(duration: element.duration * 2)
            .repeatForever(autoreverses: true)
            .delay(element.delay)
        ) {
            rotation = Double.random(in: -8...8)
        }
        
        // opacity pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + element.delay + 3) {
            withAnimation(
                .easeInOut(duration: element.duration * 0.8)
                .repeatForever(autoreverses: true)
            ) {
                elementOpacity = element.opacity * Double.random(in: 0.6...1.0)
            }
        }
    }
}

// Custom Shapes

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.25))
        
        // Left curve
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.9),
            control1: CGPoint(x: width * 0.0, y: height * 0.0),
            control2: CGPoint(x: width * 0.0, y: height * 0.6)
        )
        
        // Right curve
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.25))
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height * 0.9),
            control1: CGPoint(x: width * 1.0, y: height * 0.0),
            control2: CGPoint(x: width * 1.0, y: height * 0.6)
        )
        
        return path
    }
}

struct SmileCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: rect.height * 0.3))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.3),
            control: CGPoint(x: rect.width * 0.5, y: rect.height)
        )
        
        return path
    }
}

struct BrushStroke: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: rect.height * 0.5))
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.5),
            control1: CGPoint(x: rect.width * 0.3, y: rect.height * 0.1),
            control2: CGPoint(x: rect.width * 0.7, y: rect.height * 0.9)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.7))
        path.addCurve(
            to: CGPoint(x: 0, y: rect.height * 0.7),
            control1: CGPoint(x: rect.width * 0.6, y: rect.height),
            control2: CGPoint(x: rect.width * 0.4, y: rect.height * 0.2)
        )
        path.closeSubpath()
        
        return path
    }
}

struct MotionTrail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: rect.height * 0.5))
        path.addCurve(
            to: CGPoint(x: rect.width, y: rect.height * 0.5),
            control1: CGPoint(x: rect.width * 0.25, y: rect.height * 0.2),
            control2: CGPoint(x: rect.width * 0.75, y: rect.height * 0.8)
        )
        
        return path
    }
}
