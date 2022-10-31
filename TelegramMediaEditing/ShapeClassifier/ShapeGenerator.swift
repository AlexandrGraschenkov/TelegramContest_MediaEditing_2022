//
//  ShapeGenerator.swift
//  BezierHitTest
//
//  Created by Alexander Graschenkov on 31.10.2022.
//

import UIKit

extension ShapeClassifier.Shape {
    func generate() -> UIBezierPath? {
        switch self {
        case .ellipse(center: let center, size: let size):
            return UIBezierPath(ovalIn: CGRect(mid: center, size: size))
            
        case .rectangle(center: let center, size: let size):
            return UIBezierPath(rect: CGRect(mid: center, size: size))
            
        case .star(center: let center, size: let size):
            return generateStar(center: center, size: size)
//            let path = UIBezierPath()
//            let r = size / 2.0
//            let flip: CGFloat = -1.0 // use this to flip the figure 1.0 or -1.0
//            let polySide = CGFloat(5)
//            let theta = 2.0 * Double.pi * Double(2.0 / polySide)
//            path.move(to: CGPoint(x: center.x, y: r * flip + center.y))
//            for i in 1..<Int(polySide) {
//                let x: CGFloat = r * CGFloat( sin(Double(i) * theta) )
//                let y: CGFloat = r * CGFloat( cos(Double(i) * theta) )
//                path.addLine(to: CGPoint(x: x + center.x, y: y * flip + center.y))
//            }
//            path.close()
//            return path
            
        case .rhombus(center: let center, size: let size):
            let path = UIBezierPath()
            let offset = size * sqrt(2) / 2
            path.move(to: center.add(CGPoint(x: 0, y: -offset)))
            path.addLine(to: center.add(CGPoint(x: offset, y: 0)))
            path.addLine(to: center.add(CGPoint(x: 0, y: offset)))
            path.addLine(to: center.add(CGPoint(x: -offset, y: 0)))
            path.close()
            return path
            
        case .triangle(center: let center, size: let size):
            let height = size * sqrt(3) / 2 // высота равностороннего треугольника
            let path = UIBezierPath()
            path.move(to: center.add(CGPoint(x: 0, y: -height/2)))
            path.addLine(to: center.add(CGPoint(x: -size/2, y: height/2)))
            path.addLine(to: center.add(CGPoint(x: size/2, y: height/2)))
            path.close()
            return path
            
        case .arrow(from: _, to: _):
            // TODO
            break
        }
        
        return nil
    }
    
    fileprivate func generateStar(center: CGPoint, size: CGFloat) -> UIBezierPath {
        // better star
        let pointsTuples: [CGPoint] = [CGPoint(x: 50, y: 4.55270614), CGPoint(x: 61.2240581, y: 37.5514093), CGPoint(x: 96.0761145, y: 38.0289629), CGPoint(x: 68.1609076, y: 58.9008366), CGPoint(x: 78.4766048, y: 92.1946841), CGPoint(x: 50, y: 72.0955083), CGPoint(x: 21.5233952, y: 92.1946841), CGPoint(x: 31.8390924, y: 58.9008366), CGPoint(x: 3.92388548, y: 38.0289629), CGPoint(x: 38.7759419, y: 37.5514093), CGPoint(x: 50, y: 4.55270614)]
        
        let points = pointsTuples.map { (p: CGPoint)->CGPoint in
            CGPoint(x: (p.x-50)*size/100 + center.x,
                    y: (p.y-50)*size/100 + center.y)
        }
        let bezier = UIBezierPath()
        for (i, p) in points.enumerated() {
            if i == 0 {
                bezier.move(to: p)
            } else {
                bezier.addLine(to: p)
            }
        }
        bezier.close()
        return bezier
    }
}
