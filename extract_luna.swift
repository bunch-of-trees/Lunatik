#!/usr/bin/env swift

import AppKit
import CoreImage
import Vision

let inputPath = "/Users/forest/Pictures/Photos Library.photoslibrary/resources/derivatives/masters/A/A4845A8C-40FC-4A4C-B0A2-93B330C2F402_4_5005_c.jpeg"
let outputDir = "Lunatik/Assets.xcassets/LunaSprite.imageset"

// Create output directory
let fm = FileManager.default
try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// Load image
guard let nsImage = NSImage(contentsOfFile: inputPath),
      let tiffData = nsImage.tiffRepresentation,
      let ciImage = CIImage(data: tiffData) else {
    fatalError("Failed to load image from \(inputPath)")
}

print("Image loaded: \(ciImage.extent.width)x\(ciImage.extent.height)")

// Use Vision to generate foreground mask
let request = VNGenerateForegroundInstanceMaskRequest()
let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
try handler.perform([request])

guard let result = request.results?.first else {
    fatalError("No mask result")
}

// Generate the mask as a CIImage
let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)

print("Mask generated: \(maskCIImage.extent.width)x\(maskCIImage.extent.height)")

// Apply mask to original image using CIBlendWithMask
let context = CIContext()
let filter = CIFilter(name: "CIBlendWithMask")!
filter.setValue(ciImage, forKey: kCIInputImageKey)
filter.setValue(CIImage(color: .clear).cropped(to: ciImage.extent), forKey: kCIInputBackgroundImageKey)
filter.setValue(maskCIImage.transformed(by: CGAffineTransform(
    scaleX: ciImage.extent.width / maskCIImage.extent.width,
    y: ciImage.extent.height / maskCIImage.extent.height
)), forKey: kCIInputMaskImageKey)

guard let outputImage = filter.outputImage else {
    fatalError("Failed to apply mask")
}

// Crop to the subject's bounding box (non-transparent area)
// First render to CGImage
guard let cgFull = context.createCGImage(outputImage, from: ciImage.extent) else {
    fatalError("Failed to create CGImage")
}

// Find bounding box of non-transparent pixels
let fullWidth = cgFull.width
let fullHeight = cgFull.height
let bytesPerPixel = 4
let bytesPerRow = fullWidth * bytesPerPixel
var pixelData = [UInt8](repeating: 0, count: fullWidth * fullHeight * bytesPerPixel)

guard let cgContext = CGContext(
    data: &pixelData,
    width: fullWidth,
    height: fullHeight,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { fatalError("Failed to create context") }

cgContext.draw(cgFull, in: CGRect(x: 0, y: 0, width: fullWidth, height: fullHeight))

var minX = fullWidth, maxX = 0, minY = fullHeight, maxY = 0
for y in 0..<fullHeight {
    for x in 0..<fullWidth {
        let offset = (y * fullWidth + x) * bytesPerPixel
        let alpha = pixelData[offset + 3]
        if alpha > 20 {
            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
        }
    }
}

// Add a little padding
let pad = 20
minX = max(0, minX - pad)
minY = max(0, minY - pad)
maxX = min(fullWidth - 1, maxX + pad)
maxY = min(fullHeight - 1, maxY + pad)

let cropRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
print("Cropping to: \(cropRect)")

guard let croppedCG = cgFull.cropping(to: cropRect) else {
    fatalError("Failed to crop")
}

// Save the cropped transparent PNG
let outputPath = "\(outputDir)/Luna.png"
let url = URL(fileURLWithPath: outputPath)
guard let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
    fatalError("Failed to create destination")
}
CGImageDestinationAddImage(dest, croppedCG, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("Failed to write") }

print("Luna sprite saved: \(outputPath) (\(croppedCG.width)x\(croppedCG.height))")

// Write Contents.json
let contentsJson = """
{
  "images" : [
    {
      "filename" : "Luna.png",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""
try contentsJson.write(toFile: "\(outputDir)/Contents.json", atomically: true, encoding: .utf8)
print("Asset catalog entry created")
