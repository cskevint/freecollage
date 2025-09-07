import SwiftUI

struct GridLayoutView: View {
    @Binding var collageItems: [CollageItem]
    let canvasSize: CGSize
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Choose a layout:")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    // 1x1 Layout
                    LayoutButton(
                        title: "1x1",
                        gridCount: 1,
                        action: { createLayout(columns: 1, rows: 1) }
                    )
                    
                    // 2x1 Layout
                    LayoutButton(
                        title: "2x1",
                        gridCount: 2,
                        action: { createLayout(columns: 2, rows: 1) }
                    )
                    
                    // 1x2 Layout
                    LayoutButton(
                        title: "1x2",
                        gridCount: 2,
                        action: { createLayout(columns: 1, rows: 2) }
                    )
                    
                    // 2x2 Layout
                    LayoutButton(
                        title: "2x2",
                        gridCount: 4,
                        action: { createLayout(columns: 2, rows: 2) }
                    )
                    
                    // 3x2 Layout
                    LayoutButton(
                        title: "3x2",
                        gridCount: 6,
                        action: { createLayout(columns: 3, rows: 2) }
                    )
                    
                    // 3x3 Layout
                    LayoutButton(
                        title: "3x3",
                        gridCount: 9,
                        action: { createLayout(columns: 3, rows: 3) }
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func createLayout(columns: Int, rows: Int) {
        let itemWidth = canvasSize.width / CGFloat(columns)
        let itemHeight = canvasSize.height / CGFloat(rows)
        
        var newItems: [CollageItem] = []
        
        for row in 0..<rows {
            for col in 0..<columns {
                // Position items to fill the entire canvas evenly
                let x = CGFloat(col) * itemWidth + itemWidth / 2
                let y = CGFloat(row) * itemHeight + itemHeight / 2
                
                let item = CollageItem(
                    image: nil,
                    position: CGPoint(x: x, y: y),
                    size: CGSize(width: itemWidth - 2, height: itemHeight - 2) // 2px gap between items to match outer margin
                )
                newItems.append(item)
            }
        }
        
        collageItems = newItems
    }
}

struct LayoutButton: View {
    let title: String
    let gridCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                if gridCount == 0 {
                    Image(systemName: "square.stack.3d.up")
                        .font(.title2)
                } else {
                    GridPreview(count: gridCount)
                }
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.blue)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct GridPreview: View {
    let count: Int
    
    var body: some View {
        let columns = count == 1 ? 1 : (count == 2 ? 2 : (count <= 4 ? 2 : 3))
        let rows = count == 1 ? 1 : (count == 2 ? 1 : (count <= 4 ? 2 : (count <= 6 ? 2 : 3)))
        
        VStack(spacing: 1) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<columns, id: \.self) { col in
                        let index = row * columns + col
                        if index < count {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
        }
    }
}
