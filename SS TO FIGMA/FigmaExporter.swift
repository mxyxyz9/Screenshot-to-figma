import Foundation
import AppKit
import Vision

class FigmaExporter: ObservableObject {
    private let apiClient: FigmaAPIClient
    @Published var exportStatus: ExportStatus = .idle
    
    enum ExportStatus: Equatable {
        case idle
        case analyzing
        case converting
        case uploading
        case completed
        case failed(String)
        
        static func == (lhs: FigmaExporter.ExportStatus, rhs: FigmaExporter.ExportStatus) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.analyzing, .analyzing), (.converting, .converting), (.uploading, .uploading), (.completed, .completed):
                return true
            case (.failed(let lhsError), .failed(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    // IMPORTANT: Replace "YOUR_FIGMA_API_TOKEN" with your actual Figma API token.
    // For a production app, you would want a more secure way to handle this,
    // e.g., user input, environment variables, or a secure keychain.
    init(apiToken: String = "YOUR_FIGMA_API_TOKEN") {
        self.apiClient = FigmaAPIClient(apiToken: apiToken)
    }
    
    func exportToFigma(image: NSImage?, recognizedTexts: [VNRecognizedTextObservation], detectedRectangles: [VNRectangleObservation]) async {
        guard let image = image else { 
            await MainActor.run { exportStatus = .failed("No image to export.") }
            return 
        }
        
        await MainActor.run { exportStatus = .analyzing }
        
        var figmaElements: [FigmaElement] = []
        
        // Convert recognized text to Figma elements
        for observation in recognizedTexts {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            
            let boundingBox = observation.boundingBox
            
            // Convert Vision coordinates to Figma coordinates (flip Y-axis)
            let figmaX = boundingBox.origin.x * image.size.width
            let figmaY = (1 - boundingBox.origin.y - boundingBox.height) * image.size.height
            let figmaWidth = boundingBox.width * image.size.width
            let figmaHeight = boundingBox.height * image.size.height
            
            let textElement = FigmaElement(
                type: "TEXT",
                x: figmaX,
                y: figmaY,
                width: figmaWidth,
                height: figmaHeight,
                fills: [Fill(type: "SOLID", color: Color(r: 0, g: 0, b: 0))],
                characters: topCandidate.string,
                fontSize: Double(figmaHeight * 0.8),
                fontFamily: "Inter",
                textAlignHorizontal: "LEFT",
                textAlignVertical: "TOP"
            )
            figmaElements.append(textElement)
        }
        
        // Convert detected rectangles to Figma elements
        for box in detectedRectangles {
            let boundingBox = box.boundingBox
            let figmaX = boundingBox.origin.x * image.size.width
            let figmaY = (1 - boundingBox.origin.y - boundingBox.height) * image.size.height
            let figmaWidth = boundingBox.width * image.size.width
            let figmaHeight = boundingBox.height * image.size.height
            
            let rectElement = FigmaElement(
                type: "RECTANGLE",
                x: figmaX,
                y: figmaY,
                width: figmaWidth,
                height: figmaHeight,
                fills: [Fill(type: "SOLID", color: Color(r: 0.94, g: 0.94, b: 0.94, a: 1.0))],
                characters: nil,
                fontSize: nil,
                fontFamily: nil,
                textAlignHorizontal: nil,
                textAlignVertical: nil
            )
            figmaElements.append(rectElement)
        }
        
        await MainActor.run { exportStatus = .converting }
        
        // IMPORTANT: Replace "YOUR_FIGMA_FILE_KEY" with the actual Figma file key
        // where you want to create the component. This can be obtained from the Figma URL.
        let figmaFileKey = "YOUR_FIGMA_FILE_KEY"
        
        guard figmaFileKey != "YOUR_FIGMA_FILE_KEY" else {
            await MainActor.run { exportStatus = .failed("Please provide a valid Figma file key in FigmaExporter.swift") }
            return
        }
        
        guard apiClient.apiToken != "YOUR_FIGMA_API_TOKEN" else {
            await MainActor.run { exportStatus = .failed("Please provide a valid Figma API token in FigmaExporter.swift") }
            return
        }

        let componentData = ComponentData(
            name: "Converted Screenshot \(Date().description)",
            children: figmaElements
        )
        
        await MainActor.run { exportStatus = .uploading }
        
        do {
            let _ = try await apiClient.createComponent(in: figmaFileKey, componentData: componentData)
            
            await MainActor.run { exportStatus = .completed }
            // Optionally, you could copy a link to the Figma component to the pasteboard here
            // For now, we'll just indicate completion.
        } catch {
            await MainActor.run { exportStatus = .failed("Export failed: \(error.localizedDescription)") }
        }
    }
}
