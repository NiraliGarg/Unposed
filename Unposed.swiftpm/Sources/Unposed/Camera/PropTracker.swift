import SwiftUI
@preconcurrency import Vision
@preconcurrency import AVFoundation
@preconcurrency import CoreVideo

// Face Tracker

// real-time face landmark detection using Vision framework.
// processes video frames and publishes face position data for prop overlay.
//
// the video data output connection has isVideoMirrored = true for front camera
// and videoRotationAngle = 90 for portrait. so the pixel buffer arriving here
// is already mirrored and rotated to match the on-screen preview.
// we pass .up to VNImageRequestHandler and only flip Y when converting to screen coords.
@MainActor
class PropTracker: NSObject, ObservableObject {
    @Published var faceLandmarks: FaceLandmarkData? = nil
    @Published var isFaceDetected: Bool = false
    @Published var isHandDetected: Bool = false
    
    // view size for coordinate conversion
    var viewSize: CGSize = .zero
    
    // native resolution of the video buffer
    nonisolated(unsafe) var videoBufferSize: CGSize = .zero
    
    // whether the camera is front-facing
    var isFrontCamera: Bool = true
    
    // throttle: skip frames to reduce CPU usage
    private nonisolated(unsafe) var frameCount = 0
    private let processEveryNFrames = 3
    
    // serial queue for Vision requests
    private let visionQueue = DispatchQueue(label: "com.unposed.facetracker", qos: .userInteractive)
    
    // reusable requests
    private nonisolated(unsafe) var faceDetectionRequest: VNDetectFaceLandmarksRequest!
    private nonisolated(unsafe) var handPoseRequest: VNDetectHumanHandPoseRequest!
    
    override init() {
        super.init()
        
        faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            Task { @MainActor in
                self?.handleFaceDetectionResult(request: request, error: error)
            }
        }
        faceDetectionRequest.revision = VNDetectFaceLandmarksRequestRevision3
        
        handPoseRequest = VNDetectHumanHandPoseRequest { [weak self] request, error in
            Task { @MainActor in
                self?.handleHandDetectionResult(request: request, error: error)
            }
        }
        handPoseRequest.maximumHandCount = 1
    }
    
    // Process Frame
    
    // processes a video frame from the capture output.
    // the pixel buffer is pre-rotated and pre-mirrored by the connection settings,
    // so we tell Vision the orientation is .up.
    nonisolated func processFrame(_ sampleBuffer: CMSampleBuffer) {
        // skip frames to save CPU
        frameCount += 1
        if frameCount % 3 != 0 { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // capture native video resolution from the buffer
        let bufW = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let bufH = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        if bufW > 0 && bufH > 0 {
            videoBufferSize = CGSize(width: bufW, height: bufH)
        }
        
        // .up because the connection already applies rotation + mirroring
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: .up,
            options: [:]
        )
        
        do {
            try handler.perform([self.faceDetectionRequest, self.handPoseRequest])
        } catch {
            // Silently fail — frame will be retried on next cycle
        }
    }
    
    // Handle Results
    
    private func handleFaceDetectionResult(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNFaceObservation],
              let face = observations.first else {
            withAnimation(.easeOut(duration: 0.2)) {
                self.isFaceDetected = false
            }
            return
        }
        
        // Convert Vision normalized coordinates to view coordinates
        self.faceLandmarks = convertToViewCoordinates(face: face)
        
        if !self.isFaceDetected {
            withAnimation(.easeIn(duration: 0.15)) {
                self.isFaceDetected = true
            }
        }
    }
    
    // Hand Results
    
    private func handleHandDetectionResult(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNHumanHandPoseObservation],
              let hand = observations.first else {
            if isHandDetected {
                withAnimation { isHandDetected = false }
            }
            return
        }
        
        do {
            let thumbPoints = try hand.recognizedPoints(.thumb)
            let indexPoints = try hand.recognizedPoints(.indexFinger)
            
            guard let thumbTip = thumbPoints[.thumbTip],
                  let indexTip = indexPoints[.indexTip],
                  thumbTip.confidence > 0.3,
                  indexTip.confidence > 0.3 else { return }
            
            // check for pinch
            let distance = hypot(thumbTip.location.x - indexTip.location.x, thumbTip.location.y - indexTip.location.y)
            let isPinching = distance < 0.1
            
            if isPinching {
                let pinchMid = CGPoint(
                    x: (thumbTip.location.x + indexTip.location.x) / 2,
                    y: (thumbTip.location.y + indexTip.location.y) / 2
                )
                
                // convert to view coordinates with aspect-fill correction
                let fillTransform = aspectFillTransform()
                let viewPinch = CGPoint(
                    x: pinchMid.x * fillTransform.canvasWidth - fillTransform.offsetX,
                    y: (1 - pinchMid.y) * fillTransform.canvasHeight - fillTransform.offsetY
                )
                
                if let currentLandmarks = self.faceLandmarks {
                    self.faceLandmarks = FaceLandmarkData(
                        boundingBox: currentLandmarks.boundingBox,
                        leftEye: currentLandmarks.leftEye,
                        rightEye: currentLandmarks.rightEye,
                        nose: currentLandmarks.nose,
                        faceWidth: currentLandmarks.faceWidth,
                        faceAngle: currentLandmarks.faceAngle,
                        handPinchPosition: viewPinch
                    )
                } else {
                    self.faceLandmarks = FaceLandmarkData(
                        boundingBox: .zero,
                        leftEye: .zero,
                        rightEye: .zero,
                        nose: viewPinch,
                        faceWidth: 150,
                        faceAngle: 0,
                        handPinchPosition: viewPinch
                    )
                }
                
                if !isHandDetected {
                    withAnimation { isHandDetected = true }
                }
            } else {
                if isHandDetected {
                    withAnimation { isHandDetected = false }
                }
            }
            
        } catch {
            // Silently fail
        }
    }
    
    // Aspect-Fill Transform
    
    // returns canvas dimensions and crop offsets for aspect-fill layout.
    // Vision coordinates (0→1) map to canvasWidth/canvasHeight. The visible view
    // is offset by (offsetX, offsetY) within that canvas.
    private func aspectFillTransform() -> (canvasWidth: CGFloat, canvasHeight: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
        let viewWidth = viewSize.width
        let viewHeight = viewSize.height
        guard viewWidth > 0 && viewHeight > 0 else { return (viewWidth, viewHeight, 0, 0) }
        
        let bufSize = videoBufferSize
        let videoAspect = bufSize.width > 0 && bufSize.height > 0
            ? bufSize.width / bufSize.height
            : 4.0 / 3.0
        let viewAspect = viewWidth / viewHeight
        
        if videoAspect > viewAspect {
            let scale = viewHeight / (bufSize.height > 0 ? bufSize.height : viewHeight)
            let scaledW = (bufSize.width > 0 ? bufSize.width : viewWidth) * scale
            return (scaledW, viewHeight, (scaledW - viewWidth) / 2, 0)
        } else {
            let scale = viewWidth / (bufSize.width > 0 ? bufSize.width : viewWidth)
            let scaledH = (bufSize.height > 0 ? bufSize.height : viewHeight) * scale
            return (viewWidth, scaledH, 0, (scaledH - viewHeight) / 2)
        }
    }
    
    // Coordinate Conversion
    
    // converts Vision's normalized bounding box and landmarks to view coordinates.
    // Vision is (0,0) at bottom-left; SwiftUI is (0,0) at top-left.
    // aspect-fill correction: the preview scales video up to fill the view and crops
    // the excess. Vision's (0,0)→(1,1) maps to the full frame, so we offset.
    private func convertToViewCoordinates(face: VNFaceObservation) -> FaceLandmarkData {
        let viewWidth = viewSize.width
        let viewHeight = viewSize.height
        
        guard viewWidth > 0 && viewHeight > 0 else {
            return FaceLandmarkData(
                boundingBox: .zero, leftEye: .zero, rightEye: .zero,
                nose: .zero, faceWidth: 0, faceAngle: 0, handPinchPosition: nil
            )
        }
        
        // use shared aspect-fill transform
        let fill = aspectFillTransform()
        let canvasWidth = fill.canvasWidth
        let canvasHeight = fill.canvasHeight
        let cropX = fill.offsetX
        let cropY = fill.offsetY
        
        let bbox = face.boundingBox
        
        // convert bounding box: Vision (bottom-left origin) → view coordinates
        let faceRect = CGRect(
            x: bbox.origin.x * canvasWidth - cropX,
            y: (1 - bbox.origin.y - bbox.height) * canvasHeight - cropY,
            width: bbox.width * canvasWidth,
            height: bbox.height * canvasHeight
        )
        
        let faceWidth = faceRect.width
        
        // default positions based on bounding box (used if landmarks unavailable)
        var leftEyePos = CGPoint(x: faceRect.midX - faceWidth * 0.15, y: faceRect.midY)
        var rightEyePos = CGPoint(x: faceRect.midX + faceWidth * 0.15, y: faceRect.midY)
        var nosePos = CGPoint(x: faceRect.midX, y: faceRect.midY + faceWidth * 0.15)
        
        if let landmarks = face.landmarks {
            if let leftEye = landmarks.leftEye {
                leftEyePos = averagePoint(of: leftEye, in: bbox, canvasWidth: canvasWidth, canvasHeight: canvasHeight, offsetX: cropX, offsetY: cropY)
            }
            if let rightEye = landmarks.rightEye {
                rightEyePos = averagePoint(of: rightEye, in: bbox, canvasWidth: canvasWidth, canvasHeight: canvasHeight, offsetX: cropX, offsetY: cropY)
            }
            if let nose = landmarks.nose {
                nosePos = averagePoint(of: nose, in: bbox, canvasWidth: canvasWidth, canvasHeight: canvasHeight, offsetX: cropX, offsetY: cropY)
            }
        }
        
        // face angle from eye positions
        let eyeDeltaX = rightEyePos.x - leftEyePos.x
        let eyeDeltaY = rightEyePos.y - leftEyePos.y
        let faceAngle = atan2(eyeDeltaY, eyeDeltaX)
        
        return FaceLandmarkData(
            boundingBox: faceRect,
            leftEye: leftEyePos,
            rightEye: rightEyePos,
            nose: nosePos,
            faceWidth: faceWidth,
            faceAngle: faceAngle,
            handPinchPosition: nil
        )
    }
    
    // average point of a face landmark region in screen coordinates.
    // landmark points are normalized (0–1) relative to the face bounding box.
    private func averagePoint(
        of region: VNFaceLandmarkRegion2D,
        in boundingBox: CGRect,
        canvasWidth: CGFloat,
        canvasHeight: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat
    ) -> CGPoint {
        let points = region.normalizedPoints
        guard !points.isEmpty else { return .zero }
        
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        
        for point in points {
            // convert landmark-local to full-image normalized coords
            let normalizedX = boundingBox.origin.x + point.x * boundingBox.width
            let normalizedY = boundingBox.origin.y + point.y * boundingBox.height
            
            // map to canvas then subtract crop offset
            sumX += normalizedX * canvasWidth - offsetX
            sumY += (1 - normalizedY) * canvasHeight - offsetY
        }
        
        return CGPoint(
            x: sumX / CGFloat(points.count),
            y: sumY / CGFloat(points.count)
        )
    }
    
    // Composite Prop onto Image
    
    // bakes the selected prop onto a captured photo at the detected face position
    static func compositePropsOnto(
        image: UIImage,
        prop: PropItem,
        faceLandmarks: FaceLandmarkData,
        previewSize: CGSize
    ) -> UIImage {
        let imageSize = image.size
        
        guard previewSize.width > 0 && previewSize.height > 0 else { return image }
        
        // scale factor from preview coordinates to image coordinates
        let scaleX = imageSize.width / previewSize.width
        let scaleY = imageSize.height / previewSize.height
        
        if prop.usesEyeAlignment, let maskHoles = prop.maskEyeHoles {
            // --- eye-aligned mask compositing ---
            return compositeEyeAlignedMask(
                image: image, prop: prop, maskHoles: maskHoles,
                faceLandmarks: faceLandmarks, scaleX: scaleX, scaleY: scaleY
            )
        }
        
        // --- standard prop compositing ---
        // get prop position and size in preview coordinates
        let anchorPoint = faceLandmarks.position(for: prop.anchor)
        let propSize = faceLandmarks.propSize(scale: prop.scaleMultiplier)
        
        // convert to image coordinates (offsetY is a fraction of faceWidth)
        let relativeOffset = prop.offsetY * faceLandmarks.faceWidth
        let imageAnchorX = anchorPoint.x * scaleX
        let imageAnchorY = (anchorPoint.y + relativeOffset) * scaleY
        let imagePropWidth = propSize * scaleX
        let aspectRatio = prop.image.size.height / max(prop.image.size.width, 1)
        let imagePropHeight = imagePropWidth * aspectRatio
        
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        return renderer.image { context in
            // draw original photo
            image.draw(at: .zero)
            
            // draw prop centered on anchor
            let propRect = CGRect(
                x: imageAnchorX - imagePropWidth / 2,
                y: imageAnchorY - imagePropHeight / 2,
                width: imagePropWidth,
                height: imagePropHeight
            )
            
            // Apply face rotation
            let cgContext = context.cgContext
            cgContext.saveGState()
            cgContext.translateBy(x: propRect.midX, y: propRect.midY)
            cgContext.rotate(by: faceLandmarks.faceAngle)
            cgContext.translateBy(x: -propRect.midX, y: -propRect.midY)
            
            prop.image.draw(in: propRect)
            
            cgContext.restoreGState()
        }
    }
    
    // composites a mask prop using eye-hole alignment
    private static func compositeEyeAlignedMask(
        image: UIImage,
        prop: PropItem,
        maskHoles: MaskEyeHoles,
        faceLandmarks: FaceLandmarkData,
        scaleX: CGFloat,
        scaleY: CGFloat
    ) -> UIImage {
        let imageSize = image.size
        
        // Detected eyes in preview coordinates
        let leftEye = faceLandmarks.leftEye
        let rightEye = faceLandmarks.rightEye
        let detectedInterEye = faceLandmarks.interEyeDistance
        let eyeAngle = faceLandmarks.faceAngle
        
        // Normalized hole positions
        let leftHoleNorm = maskHoles.leftEye
        let rightHoleNorm = maskHoles.rightEye
        let holeDistNorm = hypot(rightHoleNorm.x - leftHoleNorm.x, rightHoleNorm.y - leftHoleNorm.y)
        
        // Scale mask so eye hole distance matches detected inter-eye distance
        let maskWidthPreview = (detectedInterEye / max(holeDistNorm, 0.001)) * prop.scaleMultiplier
        let imgAspect = prop.image.size.width / max(prop.image.size.height, 1)
        let maskHeightPreview = maskWidthPreview / imgAspect
        
        // Eye hole midpoint in local mask coords (unrotated)
        let holeMidLocalX = (leftHoleNorm.x + rightHoleNorm.x) / 2 * maskWidthPreview
        let holeMidLocalY = (leftHoleNorm.y + rightHoleNorm.y) / 2 * maskHeightPreview
        
        // Mask center in local coords
        let maskCenterLocalX = maskWidthPreview / 2
        let maskCenterLocalY = maskHeightPreview / 2
        
        // Offset from mask center to eye hole midpoint (local, unrotated)
        let offsetX = holeMidLocalX - maskCenterLocalX
        let offsetY = holeMidLocalY - maskCenterLocalY
        
        // Rotate offset by face angle
        let cosA = cos(eyeAngle)
        let sinA = sin(eyeAngle)
        let rotOffX = offsetX * cosA - offsetY * sinA
        let rotOffY = offsetX * sinA + offsetY * cosA
        
        // Eye midpoint in preview coordinates
        let eyeMidX = (leftEye.x + rightEye.x) / 2
        let eyeMidY = (leftEye.y + rightEye.y) / 2
        
        // Mask center in preview coords
        let maskCenterPrevX = eyeMidX - rotOffX
        let maskCenterPrevY = eyeMidY - rotOffY
        
        // Convert to image coordinates
        let imgMaskCenterX = maskCenterPrevX * scaleX
        let imgMaskCenterY = maskCenterPrevY * scaleY
        let imgMaskW = maskWidthPreview * scaleX
        let imgMaskH = maskHeightPreview * scaleY
        
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        return renderer.image { context in
            image.draw(at: .zero)
            
            let cgContext = context.cgContext
            cgContext.saveGState()
            
            // Translate to mask center, rotate, draw centered
            cgContext.translateBy(x: imgMaskCenterX, y: imgMaskCenterY)
            cgContext.rotate(by: eyeAngle)
            
            let drawRect = CGRect(
                x: -imgMaskW / 2,
                y: -imgMaskH / 2,
                width: imgMaskW,
                height: imgMaskH
            )
            prop.image.draw(in: drawRect)
            
            cgContext.restoreGState()
        }
    }
}
