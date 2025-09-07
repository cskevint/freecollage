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
    @State private var canvasSize = CGSize(width: 300, height: 300) // Default size, will be updated
    @State private var activeInteractionItemId: UUID? = nil // Track which image is being interacted with
    
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
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - 4 // Account for 2px padding on each side
            let newCanvasSize = CGSize(width: availableWidth, height: availableWidth)
            
            canvasContent(canvasSize: newCanvasSize)
                .onAppear {
                    canvasSize = newCanvasSize
                    // Set default 1x1 grid layout when canvas size is known
                    if collageItems.isEmpty {
                        createDefaultGrid(canvasSize: newCanvasSize)
                    }
                }
                .onChange(of: geometry.size) { oldValue, newValue in
                    let updatedWidth = newValue.width - 4
                    let updatedCanvasSize = CGSize(width: updatedWidth, height: updatedWidth)
                    canvasSize = updatedCanvasSize
                    // Recreate grid if items exist but need resizing
                    if !collageItems.isEmpty && collageItems.count == 1 {
                        createDefaultGrid(canvasSize: updatedCanvasSize)
                    }
                }
        }
        .aspectRatio(1, contentMode: .fit) // Keep it square
    }
    
    private func canvasContent(canvasSize: CGSize) -> some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
                .frame(width: canvasSize.width, height: canvasSize.height)
                .onTapGesture {
                    selectedItemId = nil
                    activeInteractionItemId = nil
                }
            
            // Collage Items
            ForEach(Array(collageItems.enumerated()), id: \.element.id) { index, item in
                let xOffset = item.position.x - canvasSize.width / 2
                let yOffset = item.position.y - canvasSize.height / 2
                
                CollageItemView(
                    item: item,
                    itemImages: itemImages,
                    isSelected: selectedItemId == item.id,
                    activeInteractionItemId: $activeInteractionItemId,
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
                .zIndex(Double(index)) // Explicit z-index based on array position
                .allowsHitTesting(activeInteractionItemId == nil || activeInteractionItemId == item.id)
                .id("\(item.id)-\(refreshTrigger)")
            }
        }
        .clipped()
        .padding(2) // Consistent 2px outer margin to match inner cell spacing
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
            // Initial setup will happen after canvas size is calculated
        }
    }
    
    // MARK: - Helper Methods
    
    private func createDefaultGrid(canvasSize: CGSize) {
        let centerPosition = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        // Use same sizing logic as GridLayoutView for 1x1 grid
        let itemSize = CGSize(width: canvasSize.width - 2, height: canvasSize.height - 2)
        
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
        
        // Create fresh 1x1 grid with current canvas size
        createDefaultGrid(canvasSize: canvasSize)
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
            refreshTrigger.toggle() // Trigger UI refresh for z-index update
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
    @Binding var activeInteractionItemId: UUID?
    let onTap: () -> Void
    let onSelect: () -> Void
    let onPositionChange: (CGPoint) -> Void
    let onSizeChange: (CGSize) -> Void
    let canvasSize: CGSize
    
    @State private var isResizing = false
    
    // New state for image zoom and pan within the frame
    @State private var imageScale: CGFloat = 1.0
    @State private var imagePanOffset = CGSize.zero
    @State private var lastImagePanOffset = CGSize.zero
    
    // Reset zoom and pan when image changes
    private func resetImageTransformation() {
        imageScale = 1.0
        imagePanOffset = .zero
        lastImagePanOffset = .zero
    }
    
    var body: some View {
        ZStack {
            // Main content
            Group {
                if let image = itemImages[item.id] ?? item.image {
                    // Show image with zoom and pan support - strictly cropped to cell dimensions
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: item.size.width, height: item.size.height)
                        .background(
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .scaleEffect(imageScale)
                                .offset(imagePanOffset)
                                .frame(width: item.size.width, height: item.size.height)
                        )
                        .clipShape(Rectangle())
                        .contentShape(Rectangle()) // Explicitly limit gesture area to rectangle bounds
                        .gesture(
                            SimultaneousGesture(
                                // Pinch to zoom gesture
                                MagnificationGesture()
                                    .onChanged { value in
                                        // Only respond if no other item is active or this item is already active
                                        guard activeInteractionItemId == nil || activeInteractionItemId == item.id else { return }
                                        
                                        // Set this item as active immediately when pinch starts
                                        activeInteractionItemId = item.id
                                        
                                        imageScale = max(1.0, min(3.0, value))
                                    }
                                    .onEnded { _ in
                                        // Reset pan if zooming out to 1.0
                                        withAnimation(.spring()) {
                                            if imageScale <= 1.0 {
                                                imageScale = 1.0
                                                imagePanOffset = .zero
                                                lastImagePanOffset = .zero
                                            }
                                        }
                                        
                                        // Reset active interaction when pinch ends
                                        activeInteractionItemId = nil
                                    },
                                
                                // Pan gesture for moving within the frame
                                DragGesture()
                                    .onChanged { value in
                                        // Only respond if no other item is active or this item is already active
                                        guard activeInteractionItemId == nil || activeInteractionItemId == item.id else { return }
                                        
                                        // Set this item as active immediately when drag starts
                                        activeInteractionItemId = item.id
                                        
                                        // Select item when starting to pan the image
                                        if imagePanOffset == lastImagePanOffset {
                                            onSelect()
                                        }
                                        
                                        let newOffset = CGSize(
                                            width: lastImagePanOffset.width + value.translation.width,
                                            height: lastImagePanOffset.height + value.translation.height
                                        )
                                        
                                        // Calculate the actual image dimensions when scaled and aspect-filled
                                        let imageAspectRatio = image.size.width / image.size.height
                                        let cellAspectRatio = item.size.width / item.size.height
                                        
                                        var imageDisplayWidth: CGFloat
                                        var imageDisplayHeight: CGFloat
                                        
                                        // Determine how the image fills the cell (aspectRatio fill behavior)
                                        if imageAspectRatio > cellAspectRatio {
                                            // Image is wider - height fills cell, width extends beyond
                                            imageDisplayHeight = item.size.height * imageScale
                                            imageDisplayWidth = imageDisplayHeight * imageAspectRatio
                                        } else {
                                            // Image is taller - width fills cell, height extends beyond
                                            imageDisplayWidth = item.size.width * imageScale
                                            imageDisplayHeight = imageDisplayWidth / imageAspectRatio
                                        }
                                        
                                        // Calculate maximum pan distances to keep cell fully covered
                                        let maxPanX = max(0, (imageDisplayWidth - item.size.width) / 2)
                                        let maxPanY = max(0, (imageDisplayHeight - item.size.height) / 2)
                                        
                                        // Constrain panning to keep cell fully covered by image
                                        imagePanOffset = CGSize(
                                            width: max(-maxPanX, min(maxPanX, newOffset.width)),
                                            height: max(-maxPanY, min(maxPanY, newOffset.height))
                                        )
                                    }
                                    .onEnded { _ in
                                        lastImagePanOffset = imagePanOffset
                                        
                                        // Reset active interaction when drag ends
                                        activeInteractionItemId = nil
                                    }
                            )
                        )
                        .onTapGesture {
                            // Immediately claim this item for interaction
                            activeInteractionItemId = item.id
                            
                            onTap()
                            
                            // Reset after a short delay to allow other interactions
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if activeInteractionItemId == item.id {
                                    activeInteractionItemId = nil
                                }
                            }
                        }
                } else {
                    // Show empty placeholder with consistent gray color regardless of background
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: item.size.width, height: item.size.height)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(Color.gray.opacity(0.8))
                                .font(.title2)
                        )
                        .onTapGesture {
                            // Clear active interaction when tapping empty cell
                            activeInteractionItemId = nil
                            onTap()
                        }
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
        .onChange(of: itemImages[item.id] ?? item.image) { oldValue, newValue in
            // Reset zoom and pan when image changes
            if oldValue != newValue {
                resetImageTransformation()
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
