import SwiftUI
import VisionKit
import AVFoundation

struct BarcodeScannerView: View {
    @Binding var isPresented: Bool
    @Binding var scannedProduct: FoodProduct?
    @StateObject private var lookupService = FoodLookupService()
    @State private var scannedBarcode: String?
    @State private var isProcessing = false
    @State private var showError = false
    
    var body: some View {
        ZStack {
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                DataScannerRepresentable(
                    recognizedDataTypes: [.barcode()],
                    recognizesMultipleItems: false,
                    isScanning: !isProcessing
                ) { result in
                    handleScanResult(result)
                }
                .ignoresSafeArea()
            } else {
                AVBarcodeScannerView(
                    isScanning: !isProcessing,
                    onBarcodeDetected: { barcode in
                        handleBarcodeDetected(barcode)
                    }
                )
                .ignoresSafeArea()
            }
            
            VStack {
                HStack {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(EmberColors.cream)
                            .background(Circle().fill(EmberColors.dusk.opacity(0.7)))
                    }
                    .padding()
                    
                    Spacer()
                }
                
                Spacer()
                
                if isProcessing {
                    loadingView
                }
                
                if showError, let error = lookupService.errorMessage {
                    errorView(error)
                }
            }
        }
        .onChange(of: scannedProduct) { newValue in
            if newValue != nil {
                isPresented = false
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(EmberColors.ember)
            
            Text("Looking up...")
                .font(.headline)
                .foregroundColor(EmberColors.cream)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(EmberColors.dusk.opacity(0.95))
        )
        .padding()
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text(message)
                .font(.headline)
                .foregroundColor(EmberColors.cream)
                .multilineTextAlignment(.center)
            
            Button("OK") {
                showError = false
                lookupService.errorMessage = nil
            }
            .foregroundColor(EmberColors.ember)
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(EmberColors.cream.opacity(0.2))
            )
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(EmberColors.dusk.opacity(0.95))
        )
        .padding()
    }
    
    private func handleScanResult(_ result: [RecognizedItem]) {
        guard !isProcessing,
              let item = result.first,
              case .barcode(let barcode) = item,
              let barcodeString = barcode.payloadStringValue else {
            return
        }
        
        handleBarcodeDetected(barcodeString)
    }
    
    private func handleBarcodeDetected(_ barcode: String) {
        guard !isProcessing else { return }
        
        isProcessing = true
        scannedBarcode = barcode
        
        Task {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showError = false
                }
            }
            
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            let product = await lookupService.lookupBarcode(barcode)
            
            await MainActor.run {
                if let product = product {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        scannedProduct = product
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showError = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isProcessing = false
                    }
                }
            }
        }
    }
}

@available(iOS 16.0, *)
struct DataScannerRepresentable: UIViewControllerRepresentable {
    let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
    let recognizesMultipleItems: Bool
    let isScanning: Bool
    let onRecognized: ([RecognizedItem]) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .balanced,
            recognizesMultipleItems: recognizesMultipleItems,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        
        scanner.delegate = context.coordinator
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if isScanning {
            try? uiViewController.startScanning()
        } else {
            uiViewController.stopScanning()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onRecognized: onRecognized)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onRecognized: ([RecognizedItem]) -> Void
        
        init(onRecognized: @escaping ([RecognizedItem]) -> Void) {
            self.onRecognized = onRecognized
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            onRecognized([item])
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            if let first = addedItems.first {
                onRecognized([first])
            }
        }
    }
}

struct AVBarcodeScannerView: UIViewControllerRepresentable {
    let isScanning: Bool
    let onBarcodeDetected: (String) -> Void
    
    func makeUIViewController(context: Context) -> AVScannerViewController {
        let controller = AVScannerViewController()
        controller.onBarcodeDetected = onBarcodeDetected
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVScannerViewController, context: Context) {
        uiViewController.isScanning = isScanning
    }
}

class AVScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var onBarcodeDetected: ((String) -> Void)?
    var isScanning = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession,
              let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else {
            return
        }
        
        captureSession.addInput(videoInput)
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39]
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard isScanning,
              let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }
        
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        onBarcodeDetected?(stringValue)
    }
}
