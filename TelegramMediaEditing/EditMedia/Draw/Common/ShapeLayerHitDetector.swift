//
//  ShapeLayerHitDetector.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 29.10.2022.
//

import UIKit

struct ShapeLayerHitDetector {
    let path: CGPath?
    let bezier: UIBezierPath?
    let bezierCheckOffset: [CGPoint]
    
    func hit(p: CGPoint) -> Bool {
        if let bezier = bezier {
            if let _ = bezierCheckOffset.first(where: { bezier.contains($0.add(p)) }) {
                return true
            }
            return false
        }
        
        return path?.contains(p) ?? false
    }
    
    init(layer: CALayer, hitDistance: CGFloat) {
        let layer = layer.mask ?? layer
        var checkLayers: [CALayer] = layer.sublayers ?? []
        if checkLayers.isEmpty {
            checkLayers = [layer]
        }
        
        let bezier = UIBezierPath()
        let path = CGMutablePath()
        for layer in checkLayers {
            guard let shape = layer as? CAShapeLayer,
                  let shapePath = shape.path, !shapePath.isEmpty else {
                continue
            }
            
            if (shape.fillColor?.alpha ?? 0) > 0.1 {
                bezier.append(UIBezierPath(cgPath: shapePath))
            } else {
                let width = shape.lineWidth + hitDistance
                path.addPath(shapePath.copy(strokingWithWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 0, transform: .identity))
            }
        }
        self.path = path.isEmpty ? nil : path
        self.bezier = bezier.isEmpty ? nil : bezier
        if !bezier.isEmpty {
            let angles: [CGFloat] = Array<CGFloat>(stride(from: 0, to: .pi*2, by: .pi/4))
            bezierCheckOffset = angles.map({ CGPoint(x: cos($0)*hitDistance, y: sin($0)*hitDistance) })
        } else {
            bezierCheckOffset = []
        }
    }
}
