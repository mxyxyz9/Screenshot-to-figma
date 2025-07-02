import ScreenCaptureKit
import SwiftUI
import AppKit

class ScreenshotManager: ObservableObject {
    @Published var capturedImage: NSImage?
    
    func captureScreen() async {
        do {
            let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            
            guard let display = availableContent.displays.first else {
                print("No display found.")
                return
            }
            
            let filter = SCContentFilter(display: display, excludingWindows: [])
            
            let configuration = SCStreamConfiguration()
            configuration.width = Int(display.width)
            configuration.height = Int(display.height)
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)
            configuration.queueDepth = 5
            
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )
            
            await MainActor.run {
                self.capturedImage = NSImage(cgImage: image, size: .zero)
            }
        } catch {
            print("Screenshot capture failed: \(error)")
        }
    }
}
