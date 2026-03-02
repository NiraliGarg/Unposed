import SwiftUI

// Prop Picker View

// scrollable prop picker on the camera screen
struct PropPickerView: View {
    @ObservedObject var propStore: PropStore
    @State private var selectedCategory: PropCategory = .glasses
    @State private var showScanner = false
    
    var body: some View {
        VStack(spacing: 0) {
            categoryTabs
            propsScroll
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 15, y: -5)
        )
        .sheet(isPresented: $showScanner) {
            PropScannerView(propStore: propStore)
        }
    }
    
    // Category Tabs
    
    private var categoryTabs: some View {
        HStack(spacing: 4) {
            ForEach(PropCategory.allCases, id: \.self) { category in
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = category
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: category.icon)
                            .font(.system(size: 16, weight: .medium))
                        Text(category.displayName)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(selectedCategory == category ? .white : .white.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedCategory == category ? Color.pink.opacity(0.7) : Color.clear)
                    )
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }
    
    // Props Scroll
    
    private var propsScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "None" option to deselect
                noPropButton
                
                if selectedCategory == .custom {
                    // Add custom prop button
                    addPropButton
                    
                    // Custom props
                    ForEach(propStore.customProps, id: \.id) { prop in
                        propThumbnail(prop: prop)
                            .contextMenu {
                                Button(role: .destructive) {
                                    propStore.removeCustomProp(prop)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } else {
                    // Built-in props for category
                    ForEach(propStore.props(for: selectedCategory), id: \.id) { prop in
                        propThumbnail(prop: prop)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(height: 80)
    }
    
    // Components
    
    private var noPropButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2)) {
                propStore.clearSelection()
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 22))
                    .foregroundColor(propStore.selectedProp == nil ? .white : .white.opacity(0.5))
                Text("None")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(propStore.selectedProp == nil ? .white : .white.opacity(0.5))
            }
            .frame(width: 56, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(propStore.selectedProp == nil ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(propStore.selectedProp == nil ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
    
    private var addPropButton: some View {
        Button(action: {
            showScanner = true
        }) {
            VStack(spacing: 4) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 22))
                    .foregroundColor(.white.opacity(0.7))
                Text("Scan")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(width: 56, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    )
            )
        }
    }
    
    private func propThumbnail(prop: PropItem) -> some View {
        let isSelected = propStore.selectedProp?.id == prop.id
        
        return Button(action: {
            withAnimation(.spring(response: 0.2)) {
                propStore.selectProp(prop)
            }
        }) {
            VStack(spacing: 3) {
                Image(uiImage: prop.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 36)
                
                Text(prop.name)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            .frame(width: 56, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.pink.opacity(0.5) : Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
                    )
            )
            .scaleEffect(isSelected ? 1.08 : 1.0)
        }
    }
}
