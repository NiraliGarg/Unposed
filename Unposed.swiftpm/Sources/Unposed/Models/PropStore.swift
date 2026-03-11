import SwiftUI
import UIKit

// Prop Store

@MainActor
class PropStore: ObservableObject {
    @Published var allProps: [PropItem] = []
    @Published var customProps: [PropItem] = []
    @Published var selectedProp: PropItem? = nil
    
    private let customPropsDirectory: URL
    
    init() {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        customPropsDirectory = documentsDir.appendingPathComponent("CustomProps", isDirectory: true)
        try? FileManager.default.createDirectory(at: customPropsDirectory, withIntermediateDirectories: true)
        
        Task { await loadAllProps() }
    }
    
    private func loadAllProps() async {
        let builtIn = await BuiltInProps.loadAll()
        await MainActor.run {
            self.allProps = builtIn
            self.loadCustomProps()
        }
    }
    
    // Selection
    
    func selectProp(_ prop: PropItem) {
        if selectedProp?.id == prop.id {
            selectedProp = nil
        } else {
            selectedProp = prop
        }
    }
    
    func clearSelection() {
        selectedProp = nil
    }
    
    // Custom Props
    
    func addCustomProp(name: String, image: UIImage, anchor: PropAnchor) {
        let id = "custom_\(UUID().uuidString)"
        let (scale, offset) = Self.defaultsForAnchor(anchor)
        let prop = PropItem(
            id: id,
            name: name,
            category: .custom,
            anchor: anchor,
            image: image,
            offsetY: offset,
            scaleMultiplier: scale,
            isCustom: true
        )
        
        customProps.append(prop)
        allProps.append(prop)
        saveCustomProp(prop)
    }
    
    func removeCustomProp(_ prop: PropItem) {
        customProps.removeAll { $0.id == prop.id }
        allProps.removeAll { $0.id == prop.id }
        
        let imageURL = customPropsDirectory.appendingPathComponent("\(prop.id).png")
        let metaURL = customPropsDirectory.appendingPathComponent("\(prop.id).json")
        try? FileManager.default.removeItem(at: imageURL)
        try? FileManager.default.removeItem(at: metaURL)
    }
    
    private static func defaultsForAnchor(_ anchor: PropAnchor) -> (scale: CGFloat, offsetY: CGFloat) {
        switch anchor {
        case .forehead: return (1.5, -0.65)
        case .eyes:     return (1.2, 0.03)
        case .nose:     return (0.8, 0.05)
        case .chin:     return (0.8, 0.05)
        case .hand:     return (1.0, 0.0)
        }
    }
    
    // Filtering
    
    func props(for category: PropCategory) -> [PropItem] {
        if category == .custom {
            return customProps
        }
        return allProps.filter { $0.category == category && !$0.isCustom }
    }
    
    // Persistence
    
    private func saveCustomProp(_ prop: PropItem) {
        // Save image
        let imageURL = customPropsDirectory.appendingPathComponent("\(prop.id).png")
        if let pngData = prop.image.pngData() {
            try? pngData.write(to: imageURL)
        }
        
        // Save metadata
        let meta = CustomPropMeta(
            id: prop.id,
            name: prop.name,
            anchor: prop.anchor,
            offsetY: prop.offsetY,
            scaleMultiplier: prop.scaleMultiplier
        )
        let metaURL = customPropsDirectory.appendingPathComponent("\(prop.id).json")
        if let jsonData = try? JSONEncoder().encode(meta) {
            try? jsonData.write(to: metaURL)
        }
    }
    
    private func loadCustomProps() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: customPropsDirectory, includingPropertiesForKeys: nil) else { return }
        
        let jsonFiles = files.filter { $0.pathExtension == "json" }
        
        for jsonFile in jsonFiles {
            guard let jsonData = try? Data(contentsOf: jsonFile),
                  let meta = try? JSONDecoder().decode(CustomPropMeta.self, from: jsonData) else { continue }
            
            let imageURL = customPropsDirectory.appendingPathComponent("\(meta.id).png")
            guard let imageData = try? Data(contentsOf: imageURL),
                  let image = UIImage(data: imageData) else { continue }
            
            let prop = PropItem(
                id: meta.id,
                name: meta.name,
                category: .custom,
                anchor: meta.anchor,
                image: image,
                offsetY: meta.offsetY,
                scaleMultiplier: meta.scaleMultiplier,
                isCustom: true
            )
            
            customProps.append(prop)
            allProps.append(prop)
        }
    }
}

// Persistence Model

private struct CustomPropMeta: Codable {
    let id: String
    let name: String
    let anchor: PropAnchor
    let offsetY: CGFloat
    let scaleMultiplier: CGFloat
}
