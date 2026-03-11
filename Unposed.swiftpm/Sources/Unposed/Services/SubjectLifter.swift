import UIKit
@preconcurrency import Vision
import CoreImage

// Subject Lifter

// uses Vision to isolate a subject from a photo
struct SubjectLifter {
    
    @MainActor
    static func liftSubject(from image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        return await Task.detached(priority: .userInitiated) {
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
                
                guard let result = request.results?.first else {
                    return nil
                }
                
                // generate the mask for all detected instances
                let allInstances = result.allInstances
                let maskPixelBuffer = try result.generateScaledMaskForImage(
                    forInstances: allInstances,
                    from: handler
                )
                
                // apply mask to create transparent cutout
                return applyMask(maskPixelBuffer, to: cgImage)
                
            } catch {
                print("Subject lifting failed: \(error)")
                return nil
            }
        }.value
    }
    
    // mask a CGImage with a grayscale buffer → transparent cutout
    private static func applyMask(_ maskBuffer: CVPixelBuffer, to originalImage: CGImage) -> UIImage? {
        let ciContext = CIContext()
        
        let maskImage = CIImage(cvPixelBuffer: maskBuffer)
        let originalCIImage = CIImage(cgImage: originalImage)
        
        // scale mask to match original image size
        let scaleX = originalCIImage.extent.width / maskImage.extent.width
        let scaleY = originalCIImage.extent.height / maskImage.extent.height
        let scaledMask = maskImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // use CIBlendWithMask: original where mask is white, transparent where black
        guard let blendFilter = CIFilter(name: "CIBlendWithMask") else { return nil }
        blendFilter.setValue(originalCIImage, forKey: kCIInputImageKey)
        blendFilter.setValue(CIImage.empty(), forKey: kCIInputBackgroundImageKey)
        blendFilter.setValue(scaledMask, forKey: kCIInputMaskImageKey)
        
        guard let outputImage = blendFilter.outputImage,
              let cgOutput = ciContext.createCGImage(outputImage, from: originalCIImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgOutput)
    }
}
