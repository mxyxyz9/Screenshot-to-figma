import Foundation

struct SVGGenerator {
    func generate(width: CGFloat, height: CGFloat, boxes: [CGRect], texts: [(String, CGRect)]) -> String {
        var svg = "<svg width=\"\(width)\" height=\"\(height)\" xmlns=\"http://www.w3.org/2000/svg\">\n"

        for box in boxes {
            let rect = "<rect x=\"\(box.origin.x * width)\" y=\"\((1 - box.origin.y - box.height) * height)\" width=\"\(box.width * width)\" height=\"\(box.height * height)\" style=\"fill:rgb(211,211,211);stroke-width:1;stroke:rgb(0,0,0)\" />\n"
            svg.append(rect)
        }

        for (text, box) in texts {
            let textElement = "<text x=\"\(box.origin.x * width)\" y=\"\((1 - box.origin.y - box.height) * height + box.height * height)\" font-family=\"sans-serif\" font-size=\"\(box.height * height * 0.8)\" fill=\"black\">\(text)</text>\n"
            svg.append(textElement)
        }

        svg.append("</svg>")
        return svg
    }
}
