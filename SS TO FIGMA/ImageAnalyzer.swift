
import Vision
import AppKit

class ImageAnalyzer: ObservableObject {
    @Published var recognizedText: [VNRecognizedTextObservation] = []
    @Published var detectedRectangles: [VNRectangleObservation] = []
    
    func analyzeImage(_ image: NSImage) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }
        
        let textRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            DispatchQueue.main.async {
                self?.recognizedText = observations
            }
        }
        
        textRequest.recognitionLevel = .accurate
        textRequest.recognitionLanguages = ["en-US", "zh-Hans", "zh-Hant"] // Multi-language support
        
        let rectangleRequest = VNDetectRectanglesRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRectangleObservation] else {
                return
            }
            DispatchQueue.main.async {
                self?.detectedRectangles = observations
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([textRequest, rectangleRequest])
    }
}
