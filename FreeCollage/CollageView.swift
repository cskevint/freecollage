import SwiftUI

struct CollageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var collageItems: [CollageItem] = []
    @State private var itemImages: [UUID: UIImage] = [:]
    @State private var selectedItemId: UUID?
    @State private var backgroundColor: Color = .white
    @State private var showingSaveConfirmation = false
    @State private var showingShareSheet = false
    @State private var imageToShare: UIImage?
    @State private var showingPhotoPicker = false
    @State private var exportedImage: UIImage?
    @State private var showingSaveAlert = false
    @State private var saveMessage = ""
    @State private var selectedImage: UIImage?
    @State private var itemToUpdate: UUID?
    @State private var refreshTrigger = false
    @StateObject private var exportManager = ExportManager()
    
    private let canvasSize = CGSize(width: 300, height: 300)
    
    // Computed property to control sheet presentation
    private var shouldShowShareSheet: Binding<Bool> {
        Binding(
            get: { imageToShare != nil },
            set: { newValue in
                if !newValue {
                    imageToShare = nil
                }
            }
        )
    }
    
    private var hasAnyImages: Bool {
        guard !collageItems.isEmpty else { return false }
        
        let hasImagesInStructs = collageItems.contains { !$0.isEmpty }
        let hasImagesInDictionary = !itemImages.isEmpty
        
        return hasImagesInStructs || hasImagesInDictionary
    }
    
    private var canvasView: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .frame(width: canvasSize.width, height: canvasSize.height)
                .border(Color.gray.opacity(0.3), width: 1)
                .onTapGesture {
                    selectedItemId = nil
                }
            
            // Collage Items
            ForEach(collageItems) { item in
                let isEmpty = item.isEmpty && itemImages[item.id] == nil
                let xOffset = item.position.x - canvasSize.width / 2
                let yOffset = item.position.y - canvasSize.height / 2
                
                CollageItemView(
                    item: item,
                    itemImages: itemImages,
                    isSelected: selectedItemId == item.id,
                    onTap: {
                        // Always show photo picker when tapping any grid cell
                        itemToUpdate = item.id
                        showingPhotoPicker = true
                    },
                    onSelect: {
                        selectedItemId = item.id
                    },
                    onPositionChange: { newPosition in
                        updateItemPosition(item.id, newPosition)
                    },
                    onSizeChange: { newSize in
                        updateItemSize(item.id, newSize)
                    },
                    canvasSize: canvasSize
                )
                .offset(x: xOffset, y: yOffset)
                .id("\(item.id)-\(refreshTrigger)")
            }
        }
        .clipped()
        .padding()
    }
    
    private var controlsSection: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Layout Options
                GridLayoutView(
                    collageItems: $collageItems,
                    canvasSize: canvasSize
                )
                
                // Background Color Picker
                if !collageItems.isEmpty {
                    backgroundColorPicker
                }
                
                // Selected Item Controls
                if let selectedId = selectedItemId,
                   let selectedIndex = collageItems.firstIndex(where: { $0.id == selectedId }),
                   !collageItems[selectedIndex].isEmpty {
                    selectedItemControls
                }
            }
            .padding()
        }
    }
    
    private var backgroundColorPicker: some View {
        VStack(spacing: 10) {
            Text("Choose a background color:")
                .font(.headline)
            
            HStack(spacing: 15) {
                ColorButton(color: .white, isSelected: backgroundColor == .white) {
                    backgroundColor = .white
                }
                ColorButton(color: .black, isSelected: backgroundColor == .black) {
                    backgroundColor = .black
                }
                ColorButton(color: .gray, isSelected: backgroundColor == .gray) {
                    backgroundColor = .gray
                }
                ColorButton(color: .blue, isSelected: backgroundColor == .blue) {
                    backgroundColor = .blue
                }
                ColorButton(color: .green, isSelected: backgroundColor == .green) {
                    backgroundColor = .green
                }
                ColorButton(color: .red, isSelected: backgroundColor == .red) {
                    backgroundColor = .red
                }
            }
        }
    }
    
    private var selectedItemControls: some View {
        VStack(spacing: 15) {
            Text("Edit Selected Item")
                .font(.headline)
            
            // Layer Controls
            HStack(spacing: 20) {
                Button("Send Back") {
                    if let selectedId = selectedItemId {
                        moveItemToBack(selectedId)
                    }
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                Button("Bring Forward") {
                    if let selectedId = selectedItemId {
                        moveItemToFront(selectedId)
                    }
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                Button("Replace Photo") {
                    if let selectedId = selectedItemId {
                        itemToUpdate = selectedId
                        showingPhotoPicker = true
                    }
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .foregroundColor(.green)
                .cornerRadius(8)
                
                Button("Remove Photo") {
                    if let selectedId = selectedItemId {
                        removeImageFromItem(selectedId)
                    }
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Canvas Area
                canvasView
                
                Spacer()
                
                // Controls Section
                controlsSection
            }
            .navigationTitle("FreeCollage")
            .navigationBarTitleDisplayMode(.inline)
           .toolbar {
               ToolbarItem(placement: .navigationBarLeading) {
                   Button {
                       resetToDefaultState()
                   } label: {
                       Image(systemName: "arrow.clockwise")
                   }
               }
               
               ToolbarItem(placement: .navigationBarTrailing) {
                   Button {
                       exportCollageForShare()
                   } label: {
                       Image(systemName: "square.and.arrow.up")
                   }
                   .disabled(!hasAnyImages)
               }
           }
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPickerView(selectedImage: $selectedImage)
        }
        .sheet(isPresented: shouldShowShareSheet) {
            if let image = imageToShare {
                ShareSheet(image: image)
            }
        }
        .alert("Save Result", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text(saveMessage)
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            if let image = newValue, let itemId = itemToUpdate {
                updateItemImage(itemId, image)
                selectedImage = nil
                itemToUpdate = nil
            }
        }
        .onAppear {
            // Set default 1x1 grid layout when view appears
            if collageItems.isEmpty {
                let centerPosition = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                // Use same sizing logic as GridLayoutView for 1x1 grid
                let itemSize = CGSize(width: canvasSize.width - 4, height: canvasSize.height - 4)
                
                let newItem = CollageItem(
                    id: UUID(),
                    image: nil,
                    position: centerPosition,
                    size: itemSize,
                    rotation: 0,
                    isSelected: false
                )
                
                collageItems = [newItem]
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetToDefaultState() {
        // Clear all state
        collageItems = []
        itemImages = [:]
        selectedItemId = nil
        backgroundColor = .white
        imageToShare = nil
        selectedImage = nil
        itemToUpdate = nil
        refreshTrigger = false
        
        // Create fresh 1x1 grid
        let centerPosition = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let itemSize = CGSize(width: canvasSize.width - 4, height: canvasSize.height - 4)
        
        let newItem = CollageItem(
            id: UUID(),
            image: nil,
            position: centerPosition,
            size: itemSize,
            rotation: 0,
            isSelected: false
        )
        
        collageItems = [newItem]
    }
    
    private func getItemsWithImages() -> [CollageItem] {
        return collageItems.compactMap { item in
            // Check dictionary first, then struct property
            if let image = itemImages[item.id] ?? item.image {
                return CollageItem(
                    id: item.id,
                    image: image,
                    position: item.position,
                    size: item.size,
                    rotation: item.rotation,
                    isSelected: item.isSelected
                )
            }
            return nil
        }
    }
    
    private func updateItemPosition(_ id: UUID, _ position: CGPoint) {
        if let index = collageItems.firstIndex(where: { $0.id == id }) {
            collageItems[index].position = position
        }
    }
    
    private func updateItemSize(_ id: UUID, _ size: CGSize) {
        if let index = collageItems.firstIndex(where: { $0.id == id }) {
            collageItems[index].size = size
        }
    }
    
    private func updateItemImage(_ id: UUID, _ image: UIImage) {
        // Store the image in the dictionary
        itemImages[id] = image
        
        // Force UI update
        refreshTrigger.toggle()
    }
    
    private func removeImageFromItem(_ id: UUID) {
        if let index = collageItems.firstIndex(where: { $0.id == id }) {
            collageItems[index].image = nil
            itemImages.removeValue(forKey: id)
            selectedItemId = nil
        }
    }
    
    private func moveItemToBack(_ id: UUID) {
        if let index = collageItems.firstIndex(where: { $0.id == id }) {
            let item = collageItems.remove(at: index)
            collageItems.insert(item, at: 0)
        }
    }
    
    private func moveItemToFront(_ id: UUID) {
        if let index = collageItems.firstIndex(where: { $0.id == id }) {
            let item = collageItems.remove(at: index)
            collageItems.append(item)
        }
    }
    
    private func saveCollageToPhotos() {
        let itemsWithImages = getItemsWithImages()
        guard !itemsWithImages.isEmpty else { return }
        
        guard let image = exportManager.exportCollage(items: itemsWithImages, canvasSize: canvasSize, backgroundColor: backgroundColor) else {
            saveMessage = "Failed to create collage"
            showingSaveAlert = true
            return
        }
        
        exportManager.saveToPhotoLibrary(image) { success, error in
            DispatchQueue.main.async {
                if success {
                    saveMessage = "Collage saved to Photos!"
                } else {
                    saveMessage = "Failed to save collage: \(error?.localizedDescription ?? "Unknown error")"
                }
                showingSaveAlert = true
            }
        }
    }
    
    private func exportCollageForShare() {
        let itemsWithImages = getItemsWithImages()
        
        guard !itemsWithImages.isEmpty else { 
            return 
        }
        
        guard let image = exportManager.exportCollage(items: itemsWithImages, canvasSize: canvasSize, backgroundColor: backgroundColor) else {
            return
        }
        
        // Simply set the image - the computed binding will handle showing the sheet
        imageToShare = image
    }
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(Color.primary, lineWidth: isSelected ? 3 : 1)
                )
        }
    }
}

struct CollageItemView: View {
    let item: CollageItem
    let itemImages: [UUID: UIImage]
    let isSelected: Bool
    let onTap: () -> Void
    let onSelect: () -> Void
    let onPositionChange: (CGPoint) -> Void
    let onSizeChange: (CGSize) -> Void
    let canvasSize: CGSize
    
    @State private var dragOffset = CGSize.zero
    @State private var isResizing = false
    
    var body: some View {
        ZStack {
            // Main content
            Group {
                if let image = itemImages[item.id] ?? item.image {
                    // Show image (check dictionary first, then struct property)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: item.size.width, height: item.size.height)
                        .clipped()
                } else {
                    // Show empty placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: item.size.width, height: item.size.height)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.title2)
                        )
                }
            }
            
            // Selection border and resize handles
            if isSelected && !item.isEmpty {
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(width: item.size.width, height: item.size.height)
                
                // Resize handle
                Circle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 20)
                    .offset(
                        x: item.size.width / 2 - 10,
                        y: item.size.height / 2 - 10
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newSize = CGSize(
                                    width: max(50, item.size.width + value.translation.width),
                                    height: max(50, item.size.height + value.translation.height)
                                )
                                onSizeChange(newSize)
                            }
                    )
            }
        }
        .offset(dragOffset)
        .onTapGesture {
            onTap()
        }
        .gesture(
            !item.isEmpty ? DragGesture()
                .onChanged { value in
                    // Select the item when drag starts (only on first change)
                    if dragOffset == .zero {
                        onSelect()
                    }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let newX = max(item.size.width / 2, min(canvasSize.width - item.size.width / 2, item.position.x + value.translation.width))
                    let newY = max(item.size.height / 2, min(canvasSize.height - item.size.height / 2, item.position.y + value.translation.height))
                    
                    onPositionChange(CGPoint(x: newX, y: newY))
                    dragOffset = .zero
                } : nil
        )
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
