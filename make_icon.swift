import AppKit

// Draws a green power-button icon and writes it as a 1024x1024 PNG to the given path.
let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let inset: CGFloat = 100
let rect = NSRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
NSGradient(starting: NSColor(red: 0.30, green: 0.85, blue: 0.40, alpha: 1),
           ending: NSColor(red: 0.10, green: 0.60, blue: 0.25, alpha: 1))!
    .draw(in: NSBezierPath(ovalIn: rect), angle: -90)

NSColor.white.setStroke()
let center = NSPoint(x: size / 2, y: size / 2)
let arc = NSBezierPath()
arc.appendArc(withCenter: center, radius: 230, startAngle: 120, endAngle: 60, clockwise: false)
arc.lineWidth = 70
arc.lineCapStyle = .round
arc.stroke()

let bar = NSBezierPath()
bar.move(to: NSPoint(x: center.x, y: center.y + 20))
bar.line(to: NSPoint(x: center.x, y: center.y + 280))
bar.lineWidth = 70
bar.lineCapStyle = .round
bar.stroke()

image.unlockFocus()

let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!
    .write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
