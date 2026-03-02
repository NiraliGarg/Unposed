import SwiftUI
import UIKit

// Aperture shutter button

struct ShutterButton: View {
    let openAmount: CGFloat  // 0 = fully closed, 1 = fully open
    let rotation: Double
    
    private let ringColor = Color(white: 0.15)
    private let bladeColor = Color(white: 0.95)
    private let bladeStroke = Color(white: 0.75)
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(ringColor, lineWidth: 3)
            
            DSLRAperture(
                openAmount: openAmount,
                bladeColor: bladeColor,
                strokeColor: bladeStroke
            )
            .rotationEffect(Angle(degrees: rotation))
        }
    }
}

// Aperture iris

struct DSLRAperture: View {
    var openAmount: CGFloat
    let bladeColor: Color
    let strokeColor: Color
    private let bladeCount = 6
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let outerRadius = size / 2 - 4
            
            ZStack {
                // Draw each blade in order for proper overlapping
                ForEach(0..<bladeCount, id: \.self) { index in
                    DSLRBladePath(
                        index: index,
                        totalBlades: bladeCount,
                        openAmount: openAmount,
                        outerRadius: outerRadius,
                        center: center
                    )
                    .fill(bladeColor)
                    .overlay(
                        DSLRBladePath(
                            index: index,
                            totalBlades: bladeCount,
                            openAmount: openAmount,
                            outerRadius: outerRadius,
                            center: center
                        )
                        .stroke(strokeColor, lineWidth: 0.5)
                    )
                }
            }
        }
    }
}

// Blade path

struct DSLRBladePath: Shape {
    let index: Int
    let totalBlades: Int
    var openAmount: CGFloat
    let outerRadius: CGFloat
    let center: CGPoint
    
    var animatableData: CGFloat {
        get { openAmount }
        set { openAmount = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Calculate the aperture opening size
        let minInnerRadius = outerRadius * 0.05
        let maxInnerRadius = outerRadius * 0.92
        let innerRadius = minInnerRadius + (maxInnerRadius - minInnerRadius) * openAmount
        
        let anglePerBlade = 2.0 * CGFloat.pi / CGFloat(totalBlades)
        let bladeBaseAngle = anglePerBlade * CGFloat(index)
        
        // Each blade rotates as the aperture opens/closes
        let rotationAmount = (1.0 - openAmount) * anglePerBlade * 0.7
        let adjustedAngle = bladeBaseAngle + rotationAmount
        
        // Blade geometry - curved trapezoid shape
        let bladeArcSpan = anglePerBlade * 1.1 // Slight overlap for seamless look
        
        // Four corners of the blade
        let innerArcStart = adjustedAngle - anglePerBlade * 0.08
        let innerArcEnd = adjustedAngle + bladeArcSpan * 0.45
        let outerArcStart = adjustedAngle - anglePerBlade * 0.35
        let outerArcEnd = adjustedAngle + bladeArcSpan
        
        // Start from inner edge
        let startPoint = CGPoint(
            x: center.x + cos(innerArcStart) * innerRadius,
            y: center.y + sin(innerArcStart) * innerRadius
        )
        
        path.move(to: startPoint)
        
        // Line to outer edge start
        path.addLine(to: CGPoint(
            x: center.x + cos(outerArcStart) * outerRadius,
            y: center.y + sin(outerArcStart) * outerRadius
        ))
        
        // Arc along outer edge
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: Angle(radians: Double(outerArcStart)),
            endAngle: Angle(radians: Double(outerArcEnd)),
            clockwise: false
        )
        
        // Line to inner edge end
        path.addLine(to: CGPoint(
            x: center.x + cos(innerArcEnd) * innerRadius,
            y: center.y + sin(innerArcEnd) * innerRadius
        ))
        
        // Arc along inner edge (clockwise to complete the shape)
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: Angle(radians: Double(innerArcEnd)),
            endAngle: Angle(radians: Double(innerArcStart)),
            clockwise: true
        )
        
        path.closeSubpath()
        
        return path
    }
}

// Camera Permission View

struct CameraPermissionView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Camera Access Required")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
            
            Text("Please enable camera access in Settings to use Unposed.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .foregroundColor(.blue)
            .padding(.top, 10)
        }
    }
}

// Capture Preview Sidebar

struct CapturePreview: View {
    let frames: [CapturedFrame]
    let totalFrames: Int
    let orientation: StripOrientation
    
    private var gridConfig: (columns: Int, rows: Int) {
        switch totalFrames {
        case 2: return (2, 1)
        case 4: return (2, 2)
        case 6: return (2, 3)
        case 8: return (2, 4)
        default: return (2, 2)
        }
    }
    
    var body: some View {
        Group {
            if orientation == .vertical {
                verticalLayout
            } else if orientation == .polaroid {
                polaroidLayout
            } else {
                gridLayout
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.5))
        )
    }
    
    private var polaroidLayout: some View {
        frameView(for: 0, width: 60, height: 60)
    }
    
    private var verticalLayout: some View {
        VStack(spacing: 6) {
            ForEach(0..<totalFrames, id: \.self) { index in
                frameView(for: index, width: 50, height: 38)
            }
        }
    }
    
    private var gridLayout: some View {
        let columns = gridConfig.columns
        let rows = gridConfig.rows
        let frameSize: CGFloat = 36
        
        return VStack(spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        if index < totalFrames {
                            frameView(for: index, width: frameSize, height: frameSize)
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func frameView(for index: Int, width: CGFloat, height: CGFloat) -> some View {
        if index < frames.count {
            Image(uiImage: frames[index].image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .transition(.scale.combined(with: .opacity))
        } else {
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                .frame(width: width, height: height)
        }
    }
}
