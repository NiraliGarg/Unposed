import SwiftUI
import UIKit

@MainActor
struct BuiltInProps {
    
    @MainActor
    static func loadAll() async -> [PropItem] {
        return [
            // Glasses — anchored at eye center, slight downward offset to sit on nose bridge
            makeProp("sunglasses",       "Sunglasses",       .glasses, .eyes,     assetName: "Sunglasses",         scale: 1.15,  offsetY: 0.03),
            makeProp("meme_goggle",      "Meme Goggle",      .glasses, .eyes,     assetName: "Meme Goggle",        scale: 1.20,  offsetY: 0.03),
            makeProp("star_goggles",     "Star Goggles",     .glasses, .eyes,     assetName: "Star Goggle",        scale: 1.25,  offsetY: 0.03),
            makeProp("swimming_goggle",  "Swim Goggles",     .glasses, .eyes,     assetName: "Swimming Goggle",    scale: 1.15,  offsetY: 0.03),
            makeProp("cool_glasses",     "Cool Glasses",     .glasses, .eyes,     assetName: "Cool Glasses",       scale: 1.20,  offsetY: 0.03),
            
            // Hats — anchored at forehead, negative offset lifts them up
            makeProp("hat",              "Hat",              .hats,    .forehead, assetName: "Hat",                scale: 1.6,   offsetY: -0.30),
            makeProp("magician_hat",     "Magician Hat",     .hats,    .forehead, assetName: "Magician Hat",       scale: 1.05,  offsetY: -0.45),
            makeProp("bear_headgear",    "Bear",             .hats,    .forehead, assetName: "Bear Headgear ",     scale: 1.45,  offsetY: -0.30),
            makeProp("rabbit_headgear",  "Rabbit Ears",      .hats,    .forehead, assetName: "RabbitEar Headgear", scale: 1.45,  offsetY: -0.58),
            
            // Fun
            makeProp("joker",            "Joker",            .fun,     .eyes,     assetName: "Joker",              scale: 1.30,  offsetY: 0.10),
            makeMaskProp(),
            makeProp("pink_wig",         "Pink Wig",         .fun,     .forehead, assetName: "Pink Wig",           scale: 1.8,   offsetY: -0.05),
            makeProp("rainbow_wig",      "Rainbow Wig",      .fun,     .forehead, assetName: "Rainbow Wig",        scale: 1.8,   offsetY: -0.18),
        ]
    }
    
    // Helper
    
    private static func makeProp(
        _ id: String,
        _ name: String,
        _ category: PropCategory,
        _ anchor: PropAnchor,
        assetName: String,
        scale: CGFloat,
        offsetY: CGFloat = 0
    ) -> PropItem {
        let image: UIImage
        if let loaded = UIImage(named: assetName) {
            image = loaded
        } else {
            // red placeholder so missing assets are obvious
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
            image = renderer.image { ctx in
                UIColor.red.withAlphaComponent(0.5).setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            }
            print("⚠️ Missing prop asset: \(assetName)")
        }
        return PropItem(
            id: id,
            name: name,
            category: category,
            anchor: anchor,
            image: image,
            offsetY: offsetY,
            scaleMultiplier: scale
        )
    }
    
    // Mask Prop
    
    // Eye hole positions measured from the mask PNG (1200x673):
    //   Left eye center:  pixel (326, 438) -> normalized (0.2720, 0.6512)
    //   Right eye center: pixel (867, 437) -> normalized (0.7225, 0.6496)
    private static func makeMaskProp() -> PropItem {
        let image: UIImage
        if let loaded = UIImage(named: "Mask") {
            image = loaded
        } else {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
            image = renderer.image { ctx in
                UIColor.red.withAlphaComponent(0.5).setFill()
                ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
            }
            print("⚠️ Missing prop asset: Mask")
        }
        
        return PropItem(
            id: "mask",
            name: "Mask",
            category: .fun,
            anchor: .eyes,
            image: image,
            offsetY: 0,
            scaleMultiplier: 1.0,
            isCustom: false,
            maskEyeHoles: MaskEyeHoles(
                leftEye: CGPoint(x: 0.2720, y: 0.6512),
                rightEye: CGPoint(x: 0.7225, y: 0.6496)
            )
        )
    }
}
