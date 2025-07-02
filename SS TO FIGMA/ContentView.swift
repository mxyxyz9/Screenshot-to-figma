import SwiftUI
import ScreenCaptureKit // Added for ScreenshotManager

struct ContentView: View {
    @StateObject private var screenshotManager = ScreenshotManager()
    @StateObject private var imageAnalyzer = ImageAnalyzer()
    @StateObject private var uiElementDetector = UIElementDetector()
    @StateObject private var figmaExporter = FigmaExporter()

    @State private var feedbackText = ""
    @State private var isDragOver = false

    var body: some View {
        VStack(spacing: 25) {
            Text("Screenshot to Figma")
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.heavy)
                .foregroundColor(.primary)

            Text("Drag and drop a screenshot or click to select")
                .font(.system(.title2, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if screenshotManager.capturedImage == nil {
                DropView(capturedImage: $screenshotManager.capturedImage, isDragOver: $isDragOver)
            } else {
                ImageView(capturedImage: $screenshotManager.capturedImage)
            }

            // New: Capture Screen Button
            Button(action: {
                Task {
                    await screenshotManager.captureScreen()
                }
            }) {
                Label("Capture Screen", systemImage: "macwindow.on.rectangle")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.semibold)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 25)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.blue) // A different tint for capture
            .disabled(figmaExporter.exportStatus != .idle) // Disable if exporting

            if figmaExporter.exportStatus != .idle {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
                    .padding(.vertical)
                Text(statusMessage(for: figmaExporter.exportStatus))
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(.secondary)
                    .animation(.easeInOut, value: figmaExporter.exportStatus)
            } else {
                ConvertButton(
                    capturedImage: $screenshotManager.capturedImage,
                    imageAnalyzer: imageAnalyzer,
                    uiElementDetector: uiElementDetector,
                    figmaExporter: figmaExporter
                )
            }

            Text(feedbackText)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.secondary)
                .animation(.easeInOut, value: feedbackText)
        }
        .padding(35)
        .background(Material.ultraThin)
        .cornerRadius(25)
        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 10)
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            handleDrop(providers: providers)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let item = providers.first else { return false }
        item.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (urlData, error) in
            if let urlData = urlData as? Data, let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                if let imageData = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        self.screenshotManager.capturedImage = NSImage(data: imageData)
                        self.feedbackText = ""
                    }
                }
            }
        }
        return true
    }

    private func statusMessage(for status: FigmaExporter.ExportStatus) -> String {
        switch status {
        case .idle: return ""
        case .analyzing: return "Analyzing image..."
        case .converting: return "Converting to Figma format..."
        case .uploading: return "Uploading to Figma..."
        case .completed: return "Export completed!"
        case .failed(let error): return "Export failed: \(error)"
        }
    }
}

struct DropView: View {
    @Binding var capturedImage: NSImage?
    @Binding var isDragOver: Bool
    @State private var showFileImporter = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(isDragOver ? SwiftUI.Color.accentColor.opacity(0.15) : SwiftUI.Color.clear)
                .strokeBorder(
                    isDragOver ? SwiftUI.Color.accentColor : SwiftUI.Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .frame(width: 320, height: 220)

            VStack(spacing: 15) {
                Image(systemName: "plus.rectangle.on.folder.fill")
                    .font(.system(size: 70))
                    .foregroundColor(isDragOver ? SwiftUI.Color.accentColor : SwiftUI.Color.secondary.opacity(0.6))
                Text("Drag & Drop or Click to Select")
                    .font(.system(.title3, design: .rounded))
                    .foregroundColor(isDragOver ? SwiftUI.Color.accentColor : SwiftUI.Color.secondary)
            }
        }
        .onTapGesture {
            showFileImporter = true
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile: URL = try result.get().first else { return }
                if let imageData = try? Data(contentsOf: selectedFile) {
                    DispatchQueue.main.async {
                        self.capturedImage = NSImage(data: imageData)
                    }
                }
            } catch {
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
    }
}

struct ImageView: View {
    @Binding var capturedImage: NSImage?

    var body: some View {
        Image(nsImage: capturedImage!)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 400, maxHeight: 300)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 5)
            .overlay(
                Button(action: {
                    capturedImage = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .background(Circle().fill(SwiftUI.Color.white.opacity(0.7)))
                        .padding(5)
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(5),
                alignment: .topTrailing
            )
            .padding(.vertical)
    }
}

struct ConvertButton: View {
    @Binding var capturedImage: NSImage?
    @ObservedObject var imageAnalyzer: ImageAnalyzer
    @ObservedObject var uiElementDetector: UIElementDetector
    @ObservedObject var figmaExporter: FigmaExporter

    var body: some View {
        Button(action: {
            guard let image = capturedImage else { return }
            
            Task {
                // Perform analysis and detection first
                imageAnalyzer.analyzeImage(image)
                uiElementDetector.detectElements(in: image)
                
                // Then export to Figma
                await figmaExporter.exportToFigma(
                    image: image,
                    recognizedTexts: imageAnalyzer.recognizedText,
                    detectedRectangles: imageAnalyzer.detectedRectangles
                )
            }
        }) {
            Label("Convert to Figma", systemImage: "arrow.right.doc.on.clipboard")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.semibold)
                .padding(.vertical, 12)
                .padding(.horizontal, 25)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.accentColor)
        .disabled(capturedImage == nil || figmaExporter.exportStatus != .idle)
        .shadow(color: .accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}