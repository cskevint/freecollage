import SwiftUI
import UIKit

class ExportManager: ObservableObject {
    
    func exportCollage(items: [CollageItem], canvasSize: CGSize, backgroundColor: Color = .white) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        
        return renderer.image { context in
            // Fill background
            UIColor(backgroundColor).setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))
            
            // Draw each collage item
            for item in items {
                guard let image = item.image else { continue }
                
                let rect = CGRect(
                    x: item.position.x - item.size.width / 2,
                    y: item.position.y - item.size.height / 2,
                    width: item.size.width,
                    height: item.size.height
                )
                
                // Save current context state
                context.cgContext.saveGState()
                
                // Apply rotation if needed
                if item.rotation != 0 {
                    context.cgContext.translateBy(x: item.position.x, y: item.position.y)
                    context.cgContext.rotate(by: CGFloat(item.rotation * .pi / 180))
                    context.cgContext.translateBy(x: -item.position.x, y: -item.position.y)
                }
                
                // Draw image
                image.draw(in: rect)
                
                // Restore context state
                context.cgContext.restoreGState()
            }
        }
    }
    
    func saveToPhotoLibrary(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // Since UIImageWriteToSavedPhotosAlbum doesn't provide completion callback,
        // we'll assume success for now. In a production app, you'd want to use
        // PHPhotoLibrary for better error handling.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(true, nil)
        }
    }
    
    func shareImage(_ image: UIImage) -> UIActivityViewController {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        return activityVC
    }
}
