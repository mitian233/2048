// Run from the project root: swift macOS/Icon/build-icon.swift
// CoreText is used only to export outlines; the SVG files contain paths only.
import AppKit
import CoreText

let output = URL(fileURLWithPath: "macOS/Icon", isDirectory: true)
let font = CTFontCreateWithName("ArialRoundedMTBold" as CFString, 260, nil)

func pathData(_ path: CGPath) -> String {
    var result = ""
    func point(_ point: CGPoint) -> String {
        String(format: "%.3f %.3f", Double(point.x), Double(point.y))
    }
    path.applyWithBlock { pointer in
        let element = pointer.pointee
        switch element.type {
        case .moveToPoint: result += "M\(point(element.points[0]))"
        case .addLineToPoint: result += "L\(point(element.points[0]))"
        case .addQuadCurveToPoint: result += "Q\(point(element.points[0])) \(point(element.points[1]))"
        case .addCurveToPoint: result += "C\(point(element.points[0])) \(point(element.points[1])) \(point(element.points[2]))"
        case .closeSubpath: result += "Z"
        @unknown default: break
        }
    }
    return result
}

func shape(_ path: CGPath, color: String) -> String {
    "<path fill=\"\(color)\" d=\"\(pathData(path))\"/>"
}

let board = shape(CGPath(roundedRect: CGRect(x: 100, y: 100, width: 824, height: 824), cornerWidth: 82, cornerHeight: 82, transform: nil), color: "#BBADA0")
let positions: [(CGFloat, CGFloat)] = [(136,136), (530,136), (136,530), (530,530)]
let colors = ["#EEE4DA", "#EDE0C8", "#F2B179", "#EDC22E"]
let digits = ["2", "0", "4", "8"]
var tiles = ""
var numbers = ""
for index in 0..<4 {
    let (horizontal, vertical) = positions[index]
    tiles += shape(CGPath(roundedRect: CGRect(x: horizontal, y: vertical, width: 358, height: 358), cornerWidth: 30, cornerHeight: 30, transform: nil), color: colors[index]) + "\n"
    var character = Array(digits[index].utf16)[0]
    var glyph: CGGlyph = 0
    CTFontGetGlyphsForCharacters(font, &character, &glyph, 1)
    guard let outline = CTFontCreatePathForGlyph(font, glyph, nil) else { fatalError("Missing glyph") }
    let bounds = outline.boundingBoxOfPath
    var transform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1,
        tx: horizontal + 179 - bounds.midX,
        ty: vertical + 179 + bounds.midY)
    guard let centered = outline.copy(using: &transform) else { fatalError("Invalid path") }
    numbers += shape(centered, color: index < 2 ? "#776E65" : "#F9F6F2") + "\n"
}

func save(_ name: String, _ paths: String) throws {
    let svg = """
    <svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
    \(paths)
    </svg>
    """
    try svg.write(to: output.appendingPathComponent(name), atomically: true, encoding: .utf8)
}
try save("2048.svg", board + "\n" + tiles + numbers)
try save("01-board.svg", board)
try save("02-tiles.svg", tiles)
try save("03-numbers.svg", numbers)
print("Exported combined SVG and three aligned path-only layers to macOS/Icon/")
