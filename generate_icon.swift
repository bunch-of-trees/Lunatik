#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO

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

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1.0) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [r, g, b, a])!
}

// ============================================
// BACKGROUND - Vibrant gradient
// ============================================

let bgGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        color(0.35, 0.45, 0.85),  // bright periwinkle blue (top)
        color(0.22, 0.25, 0.65),  // medium blue-purple
        color(0.14, 0.12, 0.45),  // deep indigo
        color(0.08, 0.05, 0.25),  // dark navy (bottom)
    ] as CFArray,
    locations: [0.0, 0.35, 0.65, 1.0]
)!
ctx.drawLinearGradient(bgGradient, start: CGPoint(x: w/2, y: h), end: CGPoint(x: w/2, y: 0), options: [])

// Radial glow behind Luna's face
let glowGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        color(0.55, 0.5, 0.95, 0.5),
        color(0.4, 0.35, 0.8, 0.0),
    ] as CFArray,
    locations: [0.0, 1.0]
)!
ctx.drawRadialGradient(glowGradient, startCenter: CGPoint(x: w * 0.5, y: h * 0.5), startRadius: 0, endCenter: CGPoint(x: w * 0.5, y: h * 0.5), endRadius: 500, options: [])

// ============================================
// LUNA PHOTO - Big face crop!
// ============================================

let lunaPath = "Lunatik/Assets.xcassets/LunaSprite.imageset/Luna.png"
guard let lunaDataProvider = CGDataProvider(filename: lunaPath),
      let lunaImage = CGImage(pngDataProviderSource: lunaDataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
else {
    fatalError("Failed to load Luna.png from \(lunaPath)")
}

let lunaOrigW = CGFloat(lunaImage.width)
let lunaOrigH = CGFloat(lunaImage.height)

// Scale Luna up big so the face + pizza fills the icon.
// Luna faces forward with pizza in mouth — face+pizza is in the
// lower ~60% of the 251x419 image. We want that area to fill the 1024 icon.
let scaleFactor = w / lunaOrigW * 1.35  // show more of Luna so full pizza is visible
let scaledW = lunaOrigW * scaleFactor
let scaledH = lunaOrigH * scaleFactor

// Center horizontally, shift so face+full pizza slice are visible
let lunaDrawX = (w - scaledW) / 2
let lunaDrawY = h * 0.5 - scaledH * 0.52

let lunaRect = CGRect(x: lunaDrawX, y: lunaDrawY, width: scaledW, height: scaledH)

// Drop shadow for depth
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -8), blur: 30, color: color(0, 0, 0, 0.5))
ctx.draw(lunaImage, in: lunaRect)
ctx.restoreGState()

// Draw Luna crisp
ctx.draw(lunaImage, in: lunaRect)

// Subtle vignette around edges
let vignetteGradient = CGGradient(
    colorsSpace: colorSpace,
    colors: [
        color(0.0, 0.0, 0.0, 0.0),
        color(0.05, 0.03, 0.15, 0.45),
    ] as CFArray,
    locations: [0.0, 1.0]
)!
ctx.drawRadialGradient(vignetteGradient, startCenter: CGPoint(x: w/2, y: h/2), startRadius: 350, endCenter: CGPoint(x: w/2, y: h/2), endRadius: 720, options: [.drawsAfterEndLocation])

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
