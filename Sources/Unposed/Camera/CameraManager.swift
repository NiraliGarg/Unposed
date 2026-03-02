import SwiftUI
@preconcurrency import AVFoundation
@preconcurrency import Vision
@MainActor
class CameraManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isCameraReady = false
    @Published var lastCapturedImage: UIImage?
    
    private let captureSession = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoDataOutput = AVCaptureVideoDataOutput()
    private var currentDevice: AVCaptureDevice?
    private var captureCompletion: ((UIImage?) -> Void)?
    
    // face tracker for real-time prop overlay
    // nonisolated(unsafe) to allow access from the video data delegate queue
    nonisolated(unsafe) var propTracker: PropTracker?
    
    // whether the current camera is front-facing
    var isFrontCamera: Bool {
        currentDevice?.position == .front
    }
    
    // serial queue for video frame processing
    private let videoDataQueue = DispatchQueue(label: "com.unposed.videodata", qos: .userInteractive)
    
    // stored at capture time — rotation angle in degrees
    private var captureVideoRotationAngle: CGFloat = 90
    
    // current video data rotation angle (kept in sync with rotation coordinator)
    private var currentVideoDataRotationAngle: CGFloat = 90
    
    // rotation coordinator for orientation handling
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?
    private var videoDataRotationObservation: NSKeyValueObservation?
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override init() {
        super.init()
        checkAuthorization()
    }
    
    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    self.isAuthorized = granted
                    if granted {
                        self.setupCamera()
                    }
                }
            }
        default:
            isAuthorized = false
        }
    }
    
    func setupCamera() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        
        // use front camera for selfies
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("No front camera available")
            return
        }
        
        currentDevice = device
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            // add video data output for face/hand tracking
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataQueue)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
                
                // set initial orientation and mirroring for video data output
                if let connection = videoDataOutput.connection(with: .video) {
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = (device.position == .front)
                    }
                    // rotation coordinator will update this dynamically
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                }
            }
            
            captureSession.commitConfiguration()
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            
            // set up rotation coordinator for orientation handling
            setupRotationCoordinator(for: device)
            
            DispatchQueue.main.async {
                self.isCameraReady = true
            }
        } catch {
            print("Camera setup error: \(error)")
        }
    }
    
    func startSession() {
        guard !captureSession.isRunning else { return }
        let session = self.captureSession
        Task.detached(priority: .userInitiated) {
            session.startRunning()
        }
    }
    
    func stopSession() {
        guard captureSession.isRunning else { return }
        let session = self.captureSession
        Task.detached(priority: .userInitiated) {
            session.stopRunning()
        }
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        captureCompletion = completion
        
        // Store the current video rotation angle from the rotation coordinator
        if let coordinator = rotationCoordinator {
            captureVideoRotationAngle = coordinator.videoRotationAngleForHorizonLevelCapture
        } else {
            captureVideoRotationAngle = 90
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        
        // Set the photo output connection rotation angle
        if let connection = photoOutput.connection(with: .video),
           connection.isVideoRotationAngleSupported(captureVideoRotationAngle) {
            connection.videoRotationAngle = captureVideoRotationAngle
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func switchCamera() {
        captureSession.beginConfiguration()
        
        // remove current input
        if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput {
            captureSession.removeInput(currentInput)
        }
        
        // Toggle camera position
        let newPosition: AVCaptureDevice.Position = currentDevice?.position == .front ? .back : .front
        
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
            captureSession.commitConfiguration()
            return
        }
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newDevice)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
                currentDevice = newDevice
                
                // Notify prop tracker of camera switch
                propTracker?.isFrontCamera = (newDevice.position == .front)
                
                // update rotation coordinator for new device
                setupRotationCoordinator(for: newDevice)
                
                // update video data output orientation and mirroring for new camera
                if let connection = videoDataOutput.connection(with: .video) {
                    let angle = currentVideoDataRotationAngle
                    if connection.isVideoRotationAngleSupported(angle) {
                        connection.videoRotationAngle = angle
                    }
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = (newDevice.position == .front)
                    }
                }
            }
        } catch {
            print("Switch camera error: \(error)")
        }
        
        captureSession.commitConfiguration()
    }
    
    // sets up the rotation coordinator for orientation handling
    private func setupRotationCoordinator(for device: AVCaptureDevice) {
        rotationObservation?.invalidate()
        videoDataRotationObservation?.invalidate()
        
        guard let previewLayer = previewLayer else { return }
        
        rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        
        // Observe rotation changes and update preview layer
        rotationObservation = rotationCoordinator?.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.new]) { [weak self] coordinator, _ in
            Task { @MainActor in
                guard let previewLayer = self?.previewLayer,
                      let connection = previewLayer.connection else { return }
                
                let angle = coordinator.videoRotationAngleForHorizonLevelPreview
                if connection.isVideoRotationAngleSupported(angle) {
                    connection.videoRotationAngle = angle
                }
            }
        }
        
        // observe rotation changes and update video data output connection
        videoDataRotationObservation = rotationCoordinator?.observe(\.videoRotationAngleForHorizonLevelCapture, options: [.new]) { [weak self] coordinator, _ in
            Task { @MainActor in
                guard let self = self else { return }
                let angle = coordinator.videoRotationAngleForHorizonLevelCapture
                self.currentVideoDataRotationAngle = angle
                if let connection = self.videoDataOutput.connection(with: .video),
                   connection.isVideoRotationAngleSupported(angle) {
                    connection.videoRotationAngle = angle
                }
            }
        }
        
        // Set initial rotation for preview
        if let connection = previewLayer.connection,
           let coordinator = rotationCoordinator {
            let angle = coordinator.videoRotationAngleForHorizonLevelPreview
            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        }
        
        // Set initial rotation for video data output
        if let coordinator = rotationCoordinator {
            let angle = coordinator.videoRotationAngleForHorizonLevelCapture
            currentVideoDataRotationAngle = angle
            if let connection = videoDataOutput.connection(with: .video),
               connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("Photo capture error: \(error)")
                self.captureCompletion?(nil)
                return
            }
            
            guard let imageData = photo.fileDataRepresentation(),
                  let originalImage = UIImage(data: imageData) else {
                self.captureCompletion?(nil)
                return
            }
            
            let isFrontCamera = self.currentDevice?.position == .front
            
            // flatten image so EXIF orientation is baked in
            let orientedImage = originalImage.normalizedOrientation()
            
            // for front camera, mirror to match selfie preview
            let finalImage: UIImage
            if isFrontCamera {
                finalImage = self.mirrorHorizontally(orientedImage)
            } else {
                finalImage = orientedImage
            }
            
            self.lastCapturedImage = finalImage
            self.captureCompletion?(finalImage)
        }
    }
    
    // mirrors an image horizontally (for front camera selfie mirror effect)
    private func mirrorHorizontally(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: .upMirrored)
        }
        
        context.translateBy(x: width, y: 0)
        context.scaleBy(x: -1, y: 1)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let mirroredCGImage = context.makeImage() else {
            return UIImage(cgImage: cgImage, scale: image.scale, orientation: .upMirrored)
        }
        
        return UIImage(cgImage: mirroredCGImage, scale: image.scale, orientation: .up)
    }
}

// Video Data Delegate (Face Tracking)

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        propTracker?.processFrame(sampleBuffer)
    }
}

// SwiftUI Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        return CameraPreviewUIView(cameraManager: cameraManager)
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.updateLayout()
    }
}

// custom UIView that manages the preview layer
class CameraPreviewUIView: UIView {
    private let cameraManager: CameraManager
    
    init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
        super.init(frame: .zero)
        backgroundColor = .black
        
        if let previewLayer = cameraManager.previewLayer {
            previewLayer.frame = bounds
            layer.addSublayer(previewLayer)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }
    
    func updateLayout() {
        guard let previewLayer = cameraManager.previewLayer else { return }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        previewLayer.frame = bounds
        
        // rotation coordinator manages the preview connection's videoRotationAngle
        
        CATransaction.commit()
    }
}
