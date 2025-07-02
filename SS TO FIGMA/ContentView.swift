//
//  ContentView.swift
//  SS TO FIGMA
//
//  Created by Pala Rushil on 7/2/25.
//

import SwiftUI

struct ContentView: View {
    @State private var userImage: NSImage?
    @State private var showFileImporter = false
    @State private var feedbackText = ""

    private let imageAnalyzer = ImageAnalyzer()
    private let svgGenerator = SVGGenerator()

    var body: some View {
        VStack {
            if let userImage = userImage {
                Image(nsImage: userImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            } else {
                Text("Select a screenshot")
                    .padding()
            }

            Button("Select Screenshot") {
                showFileImporter = true
            }
            .padding(.bottom)

            Button("Convert to Figma") {
                guard let userImage = userImage else { return }
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
                    feedbackText = "Copied to clipboard!"
                }
            }
            .padding(.bottom)
            .disabled(userImage == nil)

            Text(feedbackText)
                .padding()
        }
        .padding()
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile: URL = try result.get().first else { return }
                if let imageData = try? Data(contentsOf: selectedFile) {
                    self.userImage = NSImage(data: imageData)
                }
            } catch {
                // Handle error
                print(error.localizedDescription)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
