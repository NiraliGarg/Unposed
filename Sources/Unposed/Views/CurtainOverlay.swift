import SwiftUI

// two curtain panels that slide apart
struct CurtainOverlay: View {
    // when true, curtains are open (off-screen)
    let isOpen: Bool
    
    var body: some View {
        GeometryReader { geo in
            let halfWidth = geo.size.width / 2
            
            HStack(spacing: 0) {
                CurtainPanel(isLeftSide: true)
                    .frame(width: halfWidth, height: geo.size.height)
                    .offset(x: isOpen ? -halfWidth : 0)
                
                CurtainPanel(isLeftSide: false)
                    .frame(width: halfWidth, height: geo.size.height)
                    .offset(x: isOpen ? halfWidth : 0)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(!isOpen)
    }
}

private struct CurtainPanel: View {
    let isLeftSide: Bool
    
    private let velvetDark  = Color(red: 0.35, green: 0.04, blue: 0.06)
    private let velvetMid   = Color(red: 0.50, green: 0.06, blue: 0.10)
    private let velvetLight = Color(red: 0.55, green: 0.08, blue: 0.12)
    
    var body: some View {
        ZStack {
            // velvet gradient
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: isLeftSide
                            ? [velvetDark, velvetMid, velvetLight]
                            : [velvetLight, velvetMid, velvetDark], 
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // fold lines
            HStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { i in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.0),
                                    Color.white.opacity(i % 2 == 0 ? 0.06 : 0.0),
                                    Color.black.opacity(i % 2 == 0 ? 0.0 : 0.08),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            
            // top-to-bottom shading
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.0),
                            Color.black.opacity(0.15),
                            Color.black.opacity(0.30)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // center fold highlight
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: isLeftSide
                            ? [Color.clear, Color.white.opacity(0.08)]
                            : [Color.white.opacity(0.08), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 20)
                .frame(maxWidth: .infinity, alignment: isLeftSide ? .trailing : .leading)
        }
    }
}
