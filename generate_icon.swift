#!/usr/bin/env swift

import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let w = CGFloat(size)
let h = CGFloat(size)

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: size * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Failed to create context")
}

// Helper functions
func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [r, g, b, a])!
}

func fillCircle(_ cx: CGFloat, _ cy: CGFloat, _ radius: CGFloat, _ c: CGColor) {
    ctx.setFillColor(c)
    ctx.fillEllipse(in: CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2))
}

func fillEllipse(_ cx: CGFloat, _ cy: CGFloat, _ rw: CGFloat, _ rh: CGFloat, _ c: CGColor) {
    ctx.setFillColor(c)
    ctx.fillEllipse(in: CGRect(x: cx - rw, y: cy - rh, width: rw * 2, height: rh * 2))
}

func fillRect(_ x: CGFloat, _ y: CGFloat, _ rw: CGFloat, _ rh: CGFloat, _ c: CGColor, cornerRadius: CGFloat = 0) {
    ctx.setFillColor(c)
    if cornerRadius > 0 {
        let path = CGMutablePath()
        path.addRoundedRect(in: CGRect(x: x, y: y, width: rw, height: rh), cornerWidth: cornerRadius, cornerHeight: cornerRadius)
        ctx.addPath(path)
        ctx.fillPath()
    } else {
        ctx.fill(CGRect(x: x, y: y, width: rw, height: rh))
    }
}

// ============================================
// BACKGROUND - Vibrant gradient
// ============================================

// Gradient from deep blue-purple at bottom to bright orange-yellow at top
let gradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        color(0.95, 0.45, 0.15),  // bright orange
        color(1.0, 0.7, 0.1),     // golden yellow
        color(0.95, 0.45, 0.15),  // bright orange
        color(0.7, 0.15, 0.35),   // deep magenta
    ] as CFArray,
    locations: [0.0, 0.35, 0.7, 1.0]
)!
ctx.drawLinearGradient(gradient, start: CGPoint(x: w/2, y: h), end: CGPoint(x: w/2, y: 0), options: [])

// Radial glow behind Luna
let radialGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        color(1.0, 1.0, 0.6, 0.4),
        color(1.0, 0.9, 0.3, 0.0),
    ] as CFArray,
    locations: [0.0, 1.0]
)!
ctx.drawRadialGradient(radialGradient, startCenter: CGPoint(x: w/2, y: h * 0.52), startRadius: 0, endCenter: CGPoint(x: w/2, y: h * 0.52), endRadius: 350, options: [])

// Speed lines (diagonal streaks)
ctx.setLineCap(.round)
for i in 0..<18 {
    let alpha = CGFloat.random(in: 0.08...0.2)
    ctx.setStrokeColor(color(1.0, 1.0, 1.0, alpha))
    ctx.setLineWidth(CGFloat.random(in: 2...6))
    let y = CGFloat(i) * 60 + CGFloat.random(in: -20...20)
    let xStart = CGFloat.random(in: -50...200)
    ctx.move(to: CGPoint(x: xStart, y: y))
    ctx.addLine(to: CGPoint(x: xStart + CGFloat.random(in: 100...300), y: y + CGFloat.random(in: -10...10)))
    ctx.strokePath()
}

// ============================================
// LUNA - Big cartoon dog, center of icon
// ============================================

let lunaX = w * 0.48
let lunaY = h * 0.45

let bodyW: CGFloat = 200
let bodyH: CGFloat = 140

let black = color(0.1, 0.1, 0.12)
let darkBlack = color(0.06, 0.06, 0.08)
let white = color(0.92, 0.92, 0.94)
let gray = color(0.5, 0.5, 0.55, 0.6)
let brown = color(0.4, 0.25, 0.1)
let noseBrown = color(0.18, 0.13, 0.13)

// Tail (behind body)
ctx.saveGState()
let tailPath = CGMutablePath()
tailPath.move(to: CGPoint(x: lunaX - bodyW * 0.5, y: lunaY + bodyH * 0.1))
tailPath.addQuadCurve(
    to: CGPoint(x: lunaX - bodyW * 0.5 - 80, y: lunaY + bodyH * 0.1 + 100),
    control: CGPoint(x: lunaX - bodyW * 0.5 - 30, y: lunaY + bodyH * 0.1 + 90)
)
tailPath.addQuadCurve(
    to: CGPoint(x: lunaX - bodyW * 0.5 + 5, y: lunaY + bodyH * 0.1 - 10),
    control: CGPoint(x: lunaX - bodyW * 0.5 - 50, y: lunaY + bodyH * 0.1 + 60)
)
tailPath.closeSubpath()
ctx.setFillColor(black)
ctx.addPath(tailPath)
ctx.fillPath()
// White tail tip
fillCircle(lunaX - bodyW * 0.5 - 75, lunaY + bodyH * 0.1 + 95, 15, white)
ctx.restoreGState()

// Back legs
let legW: CGFloat = 32
let legH: CGFloat = 75
fillRect(lunaX - bodyW * 0.25 - legW/2, lunaY - bodyH * 0.5 - legH + 10, legW, legH, black, cornerRadius: 8)
fillRect(lunaX - bodyW * 0.35 - legW/2, lunaY - bodyH * 0.5 - legH + 15, legW, legH, black, cornerRadius: 8)
// Back paws
fillEllipse(lunaX - bodyW * 0.25, lunaY - bodyH * 0.5 - legH + 14, legW/2 + 3, 12, white)
fillEllipse(lunaX - bodyW * 0.35, lunaY - bodyH * 0.5 - legH + 19, legW/2 + 3, 12, white)

// Front legs
fillRect(lunaX + bodyW * 0.15 - legW/2, lunaY - bodyH * 0.5 - legH + 5, legW, legH, black, cornerRadius: 8)
fillRect(lunaX + bodyW * 0.05 - legW/2, lunaY - bodyH * 0.5 - legH + 15, legW, legH, black, cornerRadius: 8)
// Front paws
fillEllipse(lunaX + bodyW * 0.15, lunaY - bodyH * 0.5 - legH + 9, legW/2 + 3, 12, white)
fillEllipse(lunaX + bodyW * 0.05, lunaY - bodyH * 0.5 - legH + 19, legW/2 + 3, 12, white)

// Body - black oval
fillEllipse(lunaX, lunaY, bodyW/2, bodyH/2, black)
// Body outline
ctx.setStrokeColor(darkBlack)
ctx.setLineWidth(3)
ctx.strokeEllipse(in: CGRect(x: lunaX - bodyW/2, y: lunaY - bodyH/2, width: bodyW, height: bodyH))

// White chest
fillEllipse(lunaX + bodyW * 0.2, lunaY - bodyH * 0.05, bodyW * 0.18, bodyH * 0.32, white)

// Gray merle speckles
fillEllipse(lunaX - 30, lunaY + 20, 18, 14, gray)
fillEllipse(lunaX - 55, lunaY - 10, 14, 11, gray)
fillEllipse(lunaX + 10, lunaY + 30, 12, 10, color(0.45, 0.45, 0.5, 0.5))

// Head
let headR: CGFloat = 75
let headX = lunaX + bodyW * 0.3
let headY = lunaY + bodyH * 0.35
fillCircle(headX, headY, headR, black)
ctx.setStrokeColor(darkBlack)
ctx.setLineWidth(3)
ctx.strokeEllipse(in: CGRect(x: headX - headR, y: headY - headR, width: headR * 2, height: headR * 2))

// White face stripe / muzzle
fillEllipse(headX + 15, headY - 15, 30, 38, white)

// Nose
fillEllipse(headX + 38, headY - 8, 14, 11, noseBrown)
// Nose highlight
fillEllipse(headX + 35, headY - 4, 4, 3, color(0.35, 0.25, 0.25, 0.5))

// Mouth / smile line
ctx.setStrokeColor(noseBrown)
ctx.setLineWidth(2.5)
let mouthPath = CGMutablePath()
mouthPath.move(to: CGPoint(x: headX + 30, y: headY - 20))
mouthPath.addQuadCurve(to: CGPoint(x: headX + 15, y: headY - 28), control: CGPoint(x: headX + 25, y: headY - 28))
ctx.addPath(mouthPath)
ctx.strokePath()

// Eyes
let eyeR: CGFloat = 16
let leftEyeX = headX - 8
let leftEyeY = headY + 15
let rightEyeX = headX + 22
let rightEyeY = headY + 18

// Eye whites
fillCircle(leftEyeX, leftEyeY, eyeR, color(1, 1, 1))
fillCircle(rightEyeX, rightEyeY, eyeR, color(1, 1, 1))

// Irises (brown like Luna's)
let irisR: CGFloat = 10
fillCircle(leftEyeX + 3, leftEyeY, irisR, brown)
fillCircle(rightEyeX + 3, rightEyeY, irisR, brown)

// Pupils
fillCircle(leftEyeX + 4, leftEyeY + 1, 5, color(0.05, 0.05, 0.05))
fillCircle(rightEyeX + 4, rightEyeY + 1, 5, color(0.05, 0.05, 0.05))

// Eye shine
fillCircle(leftEyeX + 6, leftEyeY + 4, 3, color(1, 1, 1, 0.9))
fillCircle(rightEyeX + 6, rightEyeY + 4, 3, color(1, 1, 1, 0.9))

// Eyebrows (expressive!)
ctx.setStrokeColor(color(0.2, 0.15, 0.1))
ctx.setLineWidth(4)
ctx.setLineCap(.round)
let lbPath = CGMutablePath()
lbPath.move(to: CGPoint(x: leftEyeX - 14, y: leftEyeY + 22))
lbPath.addLine(to: CGPoint(x: leftEyeX + 10, y: leftEyeY + 28))
ctx.addPath(lbPath)
ctx.strokePath()
let rbPath = CGMutablePath()
rbPath.move(to: CGPoint(x: rightEyeX - 6, y: rightEyeY + 28))
rbPath.addLine(to: CGPoint(x: rightEyeX + 18, y: rightEyeY + 22))
ctx.addPath(rbPath)
ctx.strokePath()

// Floppy ears
let leftEarPath = CGMutablePath()
leftEarPath.move(to: CGPoint(x: headX - 50, y: headY + 40))
leftEarPath.addCurve(
    to: CGPoint(x: headX - 75, y: headY - 20),
    control1: CGPoint(x: headX - 80, y: headY + 55),
    control2: CGPoint(x: headX - 90, y: headY + 5)
)
leftEarPath.addLine(to: CGPoint(x: headX - 40, y: headY + 25))
leftEarPath.closeSubpath()
ctx.setFillColor(black)
ctx.addPath(leftEarPath)
ctx.fillPath()

let rightEarPath = CGMutablePath()
rightEarPath.move(to: CGPoint(x: headX + 25, y: headY + 60))
rightEarPath.addCurve(
    to: CGPoint(x: headX + 65, y: headY + 5),
    control1: CGPoint(x: headX + 55, y: headY + 75),
    control2: CGPoint(x: headX + 75, y: headY + 30)
)
rightEarPath.addLine(to: CGPoint(x: headX + 30, y: headY + 40))
rightEarPath.closeSubpath()
ctx.setFillColor(black)
ctx.addPath(rightEarPath)
ctx.fillPath()

// ============================================
// PIZZA SLICE IN MOUTH!
// ============================================

let pizzaX = headX + 30
let pizzaY = headY - 35

ctx.saveGState()
// Rotate pizza slightly
ctx.translateBy(x: pizzaX, y: pizzaY)
ctx.rotate(by: -0.3)

// Pizza crust (outer edge)
let crustPath = CGMutablePath()
crustPath.move(to: CGPoint(x: 0, y: 50))
crustPath.addLine(to: CGPoint(x: -35, y: -20))
crustPath.addQuadCurve(to: CGPoint(x: 35, y: -20), control: CGPoint(x: 0, y: -28))
crustPath.closeSubpath()
ctx.setFillColor(color(0.85, 0.65, 0.2))
ctx.addPath(crustPath)
ctx.fillPath()

// Pizza cheese (inner)
let cheesePath = CGMutablePath()
cheesePath.move(to: CGPoint(x: 0, y: 42))
cheesePath.addLine(to: CGPoint(x: -28, y: -12))
cheesePath.addLine(to: CGPoint(x: 28, y: -12))
cheesePath.closeSubpath()
ctx.setFillColor(color(1.0, 0.85, 0.3))
ctx.addPath(cheesePath)
ctx.fillPath()

// Pepperoni!
fillCircle(-8, 10, 7, color(0.8, 0.15, 0.1))
fillCircle(10, 5, 6, color(0.75, 0.12, 0.08))
fillCircle(0, 28, 6.5, color(0.8, 0.15, 0.1))
fillCircle(-15, -3, 5, color(0.7, 0.1, 0.08))
fillCircle(18, 20, 5.5, color(0.75, 0.12, 0.08))

// Cheese drip
let dripPath = CGMutablePath()
dripPath.move(to: CGPoint(x: -10, y: -12))
dripPath.addQuadCurve(to: CGPoint(x: -14, y: -30), control: CGPoint(x: -8, y: -22))
dripPath.addLine(to: CGPoint(x: -10, y: -28))
dripPath.addQuadCurve(to: CGPoint(x: -7, y: -12), control: CGPoint(x: -5, y: -20))
dripPath.closeSubpath()
ctx.setFillColor(color(1.0, 0.9, 0.35, 0.8))
ctx.addPath(dripPath)
ctx.fillPath()

ctx.restoreGState()

// ============================================
// "LUNATIK" TEXT
// ============================================

let textY: CGFloat = 95
let titleText = "LUNATIK" as CFString

// Text attributes
let fontSize: CGFloat = 135
let fontName = "AvenirNext-Heavy" as CFString
let ctFont = CTFontCreateWithName(fontName, fontSize, nil)

// Shadow/outline first (draw multiple offsets)
let shadowOffsets: [(CGFloat, CGFloat)] = [(-4, -4), (4, -4), (-4, 4), (4, 4), (0, -5), (0, 5), (-5, 0), (5, 0)]
for (dx, dy) in shadowOffsets {
    let shadowAttrs: [CFString: Any] = [
        kCTFontAttributeName: ctFont,
        kCTForegroundColorAttributeName: color(0.4, 0.1, 0.0, 0.7),
    ]
    let shadowAttrString = CFAttributedStringCreate(nil, titleText, shadowAttrs as CFDictionary)!
    let shadowLine = CTLineCreateWithAttributedString(shadowAttrString)
    let shadowBounds = CTLineGetBoundsWithOptions(shadowLine, .useGlyphPathBounds)
    let shadowTextX = (w - shadowBounds.width) / 2 - shadowBounds.origin.x + dx
    ctx.textPosition = CGPoint(x: shadowTextX, y: textY + dy)
    CTLineDraw(shadowLine, ctx)
}

// Main text - bright yellow/gold
let mainAttrs: [CFString: Any] = [
    kCTFontAttributeName: ctFont,
    kCTForegroundColorAttributeName: color(1.0, 0.92, 0.15),
]
let mainAttrString = CFAttributedStringCreate(nil, titleText, mainAttrs as CFDictionary)!
let mainLine = CTLineCreateWithAttributedString(mainAttrString)
let mainBounds = CTLineGetBoundsWithOptions(mainLine, .useGlyphPathBounds)
let mainTextX = (w - mainBounds.width) / 2 - mainBounds.origin.x
ctx.textPosition = CGPoint(x: mainTextX, y: textY)
CTLineDraw(mainLine, ctx)

// Highlight pass on top
let highlightAttrs: [CFString: Any] = [
    kCTFontAttributeName: ctFont,
    kCTForegroundColorAttributeName: color(1.0, 1.0, 0.7, 0.3),
]
let highlightAttrString = CFAttributedStringCreate(nil, titleText, highlightAttrs as CFDictionary)!
let highlightLine = CTLineCreateWithAttributedString(highlightAttrString)
ctx.textPosition = CGPoint(x: mainTextX, y: textY + 3)
CTLineDraw(highlightLine, ctx)

// ============================================
// SAVE
// ============================================

guard let image = ctx.makeImage() else { fatalError("Failed to create image") }

let outputPath = "Lunatik/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let url = URL(fileURLWithPath: outputPath)

guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("Failed to create image destination")
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("Failed to write image") }

print("App icon generated: \(outputPath)")
