import SwiftUI

struct ContentView: View {
    @State private var userImage: NSImage?
    @State private var feedbackText = ""
    @State private var isLoading = false
    @State private var isDragOver = false

    private let imageAnalyzer = ImageAnalyzer()
    private let svgGenerator = SVGGenerator()

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

            if userImage == nil {
                DropView(userImage: $userImage, isDragOver: $isDragOver)
            } else {
                ImageView(userImage: $userImage)
            }

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
                    .padding(.vertical)
            } else {
                ConvertButton(userImage: $userImage, isLoading: $isLoading, feedbackText: $feedbackText)
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
                        self.userImage = NSImage(data: imageData)
                        self.feedbackText = ""
                    }
                }
            }
        }
        return true
    }
}

struct DropView: View {
    @Binding var userImage: NSImage?
    @Binding var isDragOver: Bool
    @State private var showFileImporter = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(isDragOver ? Color.accentColor.opacity(0.15) : Color.clear)
                .strokeBorder(
                    isDragOver ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .frame(width: 320, height: 220)

            VStack(spacing: 15) {
                Image(systemName: "plus.rectangle.on.folder.fill")
                    .font(.system(size: 70))
                    .foregroundColor(isDragOver ? .accentColor : .secondary.opacity(0.6))
                Text("Drag & Drop or Click to Select")
                    .font(.system(.title3, design: .rounded))
                    .foregroundColor(isDragOver ? .accentColor : .secondary)
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
                        self.userImage = NSImage(data: imageData)
                    }
                }
            } catch {
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
    }
}

struct ImageView: View {
    @Binding var userImage: NSImage?

    var body: some View {
        Image(nsImage: userImage!)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 400, maxHeight: 300)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 5)
            .overlay(
                Button(action: {
                    userImage = nil
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .background(Circle().fill(Color.white.opacity(0.7)))
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
    @Binding var userImage: NSImage?
    @Binding var isLoading: Bool
    @Binding var feedbackText: String

    private let imageAnalyzer = ImageAnalyzer()
    private let svgGenerator = SVGGenerator()

    var body: some View {
        Button(action: {
            guard let userImage = userImage else { return }
            isLoading = true
            feedbackText = "Analyzing image..."

            imageAnalyzer.analyze(image: userImage) { boxes, texts in
                let svgString = svgGenerator.generate(
                    width: userImage.size.width,
                    height: userImage.size.height,
                    boxes: boxes,
                    texts: texts
                )
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(svgString, forType: .string)
                
                DispatchQueue.main.async {
                    feedbackText = "Copied to clipboard!"
                    isLoading = false
                }
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
        .disabled(userImage == nil || isLoading)
        .shadow(color: .accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
