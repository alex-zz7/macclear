import AppKit
import Foundation

let pixels = 1024
guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: pixels,
    pixelsHigh: pixels,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fputs("Could not create bitmap\n", stderr)
    exit(1)
}
rep.size = NSSize(width: pixels, height: pixels)

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
NSGraphicsContext.current?.imageInterpolation = .high

NSColor(calibratedRed: 0.16, green: 0.40, blue: 0.36, alpha: 1).setFill()
NSRect(x: 0, y: 0, width: pixels, height: pixels).fill()

let configuration = NSImage.SymbolConfiguration(pointSize: 470, weight: .medium)
    .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
guard let symbol = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)?
    .withSymbolConfiguration(configuration) else {
    fputs("Could not load symbol\n", stderr)
    exit(1)
}
let symbolRect = NSRect(
    x: (CGFloat(pixels) - symbol.size.width) / 2,
    y: (CGFloat(pixels) - symbol.size.height) / 2 - 12,
    width: symbol.size.width,
    height: symbol.size.height
)
symbol.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1)

NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else {
    fputs("Could not encode png\n", stderr)
    exit(1)
}
let output = URL(fileURLWithPath: CommandLine.arguments[1])
try data.write(to: output)
