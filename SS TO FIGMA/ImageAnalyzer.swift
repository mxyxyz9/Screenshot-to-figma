
import Vision
import AppKit

struct ImageAnalyzer {
    func analyze(image: NSImage, completion: @escaping ([CGRect], [(String, CGRect)]) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion([], [])
            return
        }

        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        let rectangleRequest = VNDetectRectanglesRequest { request, error in
            guard let observations = request.results as? [VNRectangleObservation] else {
                return
            }
            let boxes = observations.map { $0.boundingBox }
            
            let textRequest = VNRecognizeTextRequest { request, error in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    completion(boxes, [])
                    return
                }
                let recognizedTexts = observations.compactMap { observation -> (String, CGRect)? in
                    guard let topCandidate = observation.topCandidates(1).first else { return nil }
                    return (topCandidate.string, observation.boundingBox)
                }
                completion(boxes, recognizedTexts)
            }
            
            do {
                try requestHandler.perform([textRequest])
            } catch {
                print("Error performing text recognition: \(error)")
                completion(boxes, [])
            }
        }

        do {
            try requestHandler.perform([rectangleRequest])
        } catch {
            print("Error performing rectangle detection: \(error)")
            completion([], [])
        }
    }
}
