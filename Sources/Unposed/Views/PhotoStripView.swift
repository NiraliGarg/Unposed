import SwiftUI

// Photo Strip View (Result preview)

struct PhotoStripView: View {
    let frames: [CapturedFrame]
    let orientation: StripOrientation
    let isAnimating: Bool
    let currentAnimatingFrame: Int
    
    // soft off-white
    private let containerColor = Color(red: 0.98, green: 0.97, blue: 0.95)
    
    var body: some View {
        Group {
            if orientation == .vertical {
                VerticalStripLayout(
                    frames: frames,
                    isAnimating: isAnimating,
                    currentAnimatingFrame: currentAnimatingFrame,
                    containerColor: containerColor
                )
            } else if orientation == .polaroid {
                PolaroidStripLayout(
                    frames: frames,
                    isAnimating: isAnimating,
                    currentAnimatingFrame: currentAnimatingFrame,
                    containerColor: containerColor
                )
            } else {
                GridStripLayout(
                    frames: frames,
                    isAnimating: isAnimating,
                    currentAnimatingFrame: currentAnimatingFrame,
                    containerColor: containerColor
                )
            }
        }
    }
}

// Vertical Strip Layout
struct VerticalStripLayout: View {
    let frames: [CapturedFrame]
    let isAnimating: Bool
    let currentAnimatingFrame: Int
    let containerColor: Color
    
    private let stripWidth: CGFloat = 320
    private let horizontalPadding: CGFloat = 14
    private let topPadding: CGFloat = 20
    private let bottomPadding: CGFloat = 60
    private let photoSpacing: CGFloat = 12
    
    var body: some View {
        let photoWidth = stripWidth - (horizontalPadding * 2)
        let photoHeight = photoWidth * 0.75 // 4:3 aspect ratio
        let totalPhotosHeight = (photoHeight * CGFloat(frames.count)) + (photoSpacing * CGFloat(max(0, frames.count - 1)))
        let stripHeight = topPadding + totalPhotosHeight + bottomPadding
        
        VStack(spacing: 0) {
            VStack(spacing: photoSpacing) {
                ForEach(Array(frames.enumerated()), id: \.element.id) { index, frame in
                    photoFrame(frame: frame, index: index, width: photoWidth, height: photoHeight)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, topPadding)
            
            Spacer(minLength: 8)
            
            // branding logo at bottom
            Image("Unposed for Strip")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: stripWidth * 0.6, height: 16)
                .foregroundColor(Color(white: 0.4))
                .padding(.bottom, 14)
        }
        .frame(width: stripWidth, height: stripHeight)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(containerColor)
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)
        )
    }
    
    private func photoFrame(frame: CapturedFrame, index: Int, width: CGFloat, height: CGFloat) -> some View {
        Image(uiImage: frame.image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .scaleEffect(isAnimating && currentAnimatingFrame == index ? 1.02 : 1.0)
            .brightness(isAnimating && currentAnimatingFrame == index ? 0.03 : 0)
            .animation(.easeInOut(duration: 0.2), value: currentAnimatingFrame)
    }
}

// Grid Strip Layout
struct GridStripLayout: View {
    let frames: [CapturedFrame]
    let isAnimating: Bool
    let currentAnimatingFrame: Int
    let containerColor: Color
    
    private let containerPadding: CGFloat = 20
    private let photoSpacing: CGFloat = 12
    private let bottomPadding: CGFloat = 60
    
    private var gridConfig: (columns: Int, rows: Int) {
        let columns = 2
        let rows = (frames.count + columns - 1) / columns
        return (columns, rows)
    }
    
    var body: some View {
        let columns = gridConfig.columns
        let rows = gridConfig.rows
        
        // Calculate photo size for square grid
        let gridWidth: CGFloat = 420
        let photoSize = (gridWidth - (containerPadding * 2) - (photoSpacing * CGFloat(columns - 1))) / CGFloat(columns)
        let photosHeight = (photoSize * CGFloat(rows)) + (photoSpacing * CGFloat(rows - 1))
        let gridHeight = containerPadding + photosHeight + bottomPadding
        
        VStack(spacing: 0) {
            VStack(spacing: photoSpacing) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: photoSpacing) {
                        ForEach(0..<columns, id: \.self) { col in
                            let index = row * columns + col
                            if index < frames.count {
                                photoFrame(frame: frames[index], index: index, size: photoSize)
                            } else {
                                // Empty placeholder for incomplete grids
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.clear)
                                    .frame(width: photoSize, height: photoSize)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, containerPadding)
            .padding(.top, containerPadding)
            
            Spacer(minLength: 8)
            
            // branding logo at bottom
            Image("Unposed for Strip")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: gridWidth * 0.6, height: 16)
                .foregroundColor(Color(white: 0.4))
                .padding(.bottom, 14)
        }
        .frame(width: gridWidth, height: gridHeight)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(containerColor)
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)
        )
    }
    
    private func photoFrame(frame: CapturedFrame, index: Int, size: CGFloat) -> some View {
        Image(uiImage: frame.image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .scaleEffect(isAnimating && currentAnimatingFrame == index ? 1.02 : 1.0)
            .brightness(isAnimating && currentAnimatingFrame == index ? 0.03 : 0)
            .animation(.easeInOut(duration: 0.2), value: currentAnimatingFrame)
    }
}

// polaroid-style single photo layout
struct PolaroidStripLayout: View {
    let frames: [CapturedFrame]
    let isAnimating: Bool
    let currentAnimatingFrame: Int
    let containerColor: Color
    
    private let photoSize: CGFloat = 320
    private let sidePadding: CGFloat = 20
    private let topPadding: CGFloat = 20
    private let bottomPadding: CGFloat = 80
    
    var body: some View {
        let stripWidth = photoSize + (sidePadding * 2)
        let stripHeight = topPadding + photoSize + bottomPadding
        
        VStack(spacing: 0) {
            if let frame = frames.first {
                Image(uiImage: frame.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: photoSize, height: photoSize)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .scaleEffect(isAnimating && currentAnimatingFrame == 0 ? 1.02 : 1.0)
                    .brightness(isAnimating && currentAnimatingFrame == 0 ? 0.03 : 0)
                    .animation(.easeInOut(duration: 0.2), value: currentAnimatingFrame)
                    .padding(.top, topPadding)
                    .padding(.horizontal, sidePadding)
            }
            
            Spacer(minLength: 8)
            
            Image("Unposed for Strip")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: stripWidth * 0.6, height: 16)
                .foregroundColor(Color(white: 0.4))
                .padding(.bottom, 14)
        }
        .frame(width: stripWidth, height: stripHeight)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(containerColor)
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)
        )
    }
}
