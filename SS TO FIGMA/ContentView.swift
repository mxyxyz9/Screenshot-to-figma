import SwiftUI

struct ContentView: View {
    @State private var userImage: NSImage?
    @State private var feedbackText = ""
    @State private var isLoading = false
    @State private var isDragOver = false

    private let imageAnalyzer = ImageAnalyzer()
    private let svgGenerator = SVGGenerator()

    var body: some View {
        VStack(spacing: 20) {
            Text("Screenshot to Figma")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.primary)

            Text("Drag and drop a screenshot to get started")
                .font(.title2)
                .foregroundColor(Color.secondary)

            if userImage == nil {
                DropView(userImage: $userImage, isDragOver: $isDragOver)
            } else {
                ImageView(userImage: $userImage)
            }

            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else {
                ConvertButton(userImage: $userImage, isLoading: $isLoading, feedbackText: $feedbackText)
            }

            Text(feedbackText)
                .font(.title3)
                .foregroundColor(Color.secondary)
        }
        .padding(30)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(20)
        .shadow(radius: 10)
        .onDrop(of: ["public.file-url"], isTargeted: $isDragOver) { providers in
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

    var body: some View {
        VStack {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(isDragOver ? .accentColor : .secondary)
            Text("Drop screenshot here")
                .font(.title2)
                .foregroundColor(isDragOver ? .accentColor : .secondary)
        }
        .frame(width: 300, height: 200)
        .background(isDragOver ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                .foregroundColor(isDragOver ? .accentColor : .secondary)
        )
    }
}

struct ImageView: View {
    @Binding var userImage: NSImage?

    var body: some View {
        Image(nsImage: userImage!)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding()
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
            feedbackText = ""

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
            Text("Convert to Figma")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .cornerRadius(10)
                .shadow(radius: 5)
        }
        .disabled(userImage == nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}