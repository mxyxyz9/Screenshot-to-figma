import Foundation
import AppKit

struct FigmaComponent: Codable {
    let id: String
    let name: String
    // Add other properties as needed based on Figma API response
}

struct ComponentData: Codable {
    let name: String
    let children: [FigmaElement]
}

struct FigmaElement: Codable {
    let type: String
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let fills: [Fill]?
    let characters: String?
    let fontSize: Double?
    let fontFamily: String?
    let textAlignHorizontal: String?
    let textAlignVertical: String?
}

struct Fill: Codable {
    let type: String
    let color: Color
}

struct Color: Codable {
    let r: Double
    let g: Double
    let b: Double
    let a: Double?
    
    init(r: Double, g: Double, b: Double, a: Double? = 1.0) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }
}

enum FigmaAPIError: Error {
    case invalidURL
    case requestFailed
    case invalidResponse
    case decodingError
    case custom(String)
}

class FigmaAPIClient: ObservableObject {
    let apiToken: String
    private let baseURL = "https://api.figma.com/v1"
    
    init(apiToken: String) {
        self.apiToken = apiToken
    }
    
    private var headers: [String: String] {
        return [
            "X-Figma-Token": apiToken,
            "Content-Type": "application/json"
        ]
    }
    
    func createComponent(in fileKey: String, componentData: ComponentData) async throws -> FigmaComponent {
        guard let url = URL(string: "\(baseURL)/files/\(fileKey)/nodes") else {
            throw FigmaAPIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // For debugging
        
        let jsonData = try encoder.encode(componentData)
        request.httpBody = jsonData
        
        print("Figma API Request Body: \(String(data: jsonData, encoding: .utf8) ?? "Invalid JSON")")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FigmaAPIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let responseString = String(data: data, encoding: .utf8) ?? ""
            print("Figma API Error Response: \(responseString)")
            throw FigmaAPIError.custom("Figma API returned status code \(httpResponse.statusCode): \(responseString)")
        }
        
        let decoder = JSONDecoder()
        do {
            let figmaResponse = try decoder.decode([String: FigmaComponent].self, from: data)
            // The Figma API for creating nodes returns a dictionary where keys are node IDs
            // We'll just return the first component if successful
            guard let firstComponent = figmaResponse.values.first else {
                throw FigmaAPIError.decodingError
            }
            return firstComponent
        } catch {
            print("Figma API Decoding Error: \(error)")
            throw FigmaAPIError.decodingError
        }
    }
}
