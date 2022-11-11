//
//  UIView+Blur.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 29.10.2022.
//

import UIKit
import Accelerate

public extension UIView {
    
    func snapshotInMain(scale: CGFloat = 1, blur: CGFloat = 0, completion: @escaping (CGImage?)->()) {
        let t1 = CACurrentMediaTime()
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = UIScreen.main.scale * scale
        if #available(iOS 12.0, *) {
            format.preferredRange = .standard
        } else {
            format.prefersExtendedRange = false
        }
        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
        _ = renderer.image { rendererContext in
            let t2 = CACurrentMediaTime()
            self.layer.render(in: rendererContext.cgContext)
            let t3 = CACurrentMediaTime()
            let blurred = UIView.blurImageAccelerate(context: rendererContext.cgContext, blurRadius: blur, scale: 1)
            let t4 = CACurrentMediaTime()
            completion(blurred)
            print("Blur time: prepare \(t2-t1); render \(t3-t2); blur \(t4-t3)")
        }
    }
    
    func snapshotInBackground(scale: CGFloat = 1, blur: CGFloat = 0, completion: @escaping (CGImage?)->()) {
        let contentsScale = layer.contentsScale
        let width = Int(bounds.width * contentsScale * scale)
        let height = Int(bounds.height * contentsScale * scale)
        let bytesPerRow = width * 4
        let alignedBytesPerRow = ((bytesPerRow + (64 - 1)) / 64) * 64
        
        let layer = self.layer
        let yOffset = bounds.height + bounds.minY
        performInBackground {
            let t1 = CACurrentMediaTime()
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: alignedBytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )!
            
            context.scaleBy(x: contentsScale * scale, y: contentsScale * scale)
            //            layer.draw(in: context)
            
            context.translateBy(x: 0, y: yOffset)
            context.scaleBy(x: 1.0, y: -1.0)
            
//            UIGraphicsPushContext(context)
            //        self.drawHierarchy(in: bounds, afterScreenUpdates: false)
            //        layer.draw(in: context)
            let t2 = CACurrentMediaTime()
            layer.render(in: context)
//            UIGraphicsPopContext()
            
            guard let image = context.makeImage() else {
                completion(nil)
                return
            }
            //            let img = context.makeImage()
            let t3 = CACurrentMediaTime()
            var t4 = t3
            if blur > 0 {
//                let blurred = UIView.blurImageFrom(cgImage: image, blurSize: blur, reuseContext: context)
                
                let blurred = UIView.blurImageAccelerate(context: context, blurRadius: blur, scale: contentsScale)
                t4 = CACurrentMediaTime()
                completion(blurred)
            } else {
                completion(image)
            }
            print("Blur time: prepare \(t2-t1); render \(t3-t2); blur \(t4-t3)")
        }
    }
    
    /// works much slower, cause need to transfer data to GPU
    private static func blurImageCIFilter(cgImage: CGImage, blurSize: CGFloat, reuseContext: CGContext? = nil) -> CGImage? {
        let image = CIImage(cgImage: cgImage)
        let blur = CIFilter(name: "CIGaussianBlur")!
        blur.setValue(image, forKey: kCIInputImageKey)
        blur.setValue(blurSize, forKey: kCIInputRadiusKey)
        
        let context = reuseContext.map({CIContext(cgContext: $0)}) ?? CIContext(options: nil)
        let outputImage = context.createCGImage(blur.outputImage!, from: CGRect(origin: .zero, size: CGSize(width: cgImage.width, height: cgImage.height)))
        
        return outputImage
    }
    
    private static func blurImageAccelerate(context: CGContext, blurRadius: CGFloat, scale: CGFloat) -> CGImage? {
        if blurRadius <= .ulpOfOne { return context.makeImage() }
        
        var inBuffer = vImage_Buffer()
        var outBuffer = vImage_Buffer()
        
        inBuffer.data = context.data
        inBuffer.width = vImagePixelCount(context.width)
        inBuffer.height = vImagePixelCount(context.height)
        inBuffer.rowBytes = context.bytesPerRow
        
        let outContext = CGContext(
            data: nil,
            width: context.width,
            height: context.height,
            bitsPerComponent: context.bitsPerComponent,
            bytesPerRow: context.bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: context.bitmapInfo.rawValue
        )!
        
        var outImage: CGImage? = nil
        outBuffer.data = outContext.data
        outBuffer.width = vImagePixelCount(outContext.width)
        outBuffer.height = vImagePixelCount(outContext.height)
        outBuffer.rowBytes = outContext.bytesPerRow
        
        let inputRadius = blurRadius * scale
        var radius: UInt32 = UInt32(round(inputRadius * 3.0 * sqrt(2.0 * .pi) / 4.0))
        if radius % 2 != 1 {
            radius += 1
        }
        
        vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, nil, 0, 0, radius, radius, nil, vImage_Flags(kvImageEdgeExtend))
        vImageBoxConvolve_ARGB8888(&outBuffer, &inBuffer, nil, 0, 0, radius, radius, nil, vImage_Flags(kvImageEdgeExtend))
        vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, nil, 0, 0, radius, radius, nil, vImage_Flags(kvImageEdgeExtend))
        
        outImage = outContext.makeImage()
        return outImage
    }
}
