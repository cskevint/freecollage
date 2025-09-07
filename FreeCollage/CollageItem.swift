import SwiftUI
import UIKit

struct CollageItem: Identifiable, Equatable {
    let id: UUID
    var image: UIImage?
    var position: CGPoint
    var size: CGSize
    var rotation: Double = 0
    var isSelected: Bool = false
    var isEmpty: Bool {
        return image == nil
    }
    
    init(id: UUID = UUID(), image: UIImage? = nil, position: CGPoint, size: CGSize, rotation: Double = 0, isSelected: Bool = false) {
        self.id = id
        self.image = image
        self.position = position
        self.size = size
        self.rotation = rotation
        self.isSelected = isSelected
    }
    
    static func == (lhs: CollageItem, rhs: CollageItem) -> Bool {
        return lhs.id == rhs.id
    }
}
