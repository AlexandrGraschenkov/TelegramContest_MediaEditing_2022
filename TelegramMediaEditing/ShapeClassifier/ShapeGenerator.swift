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
            let path = UIBezierPath()
            let r = size / 2.0
            let flip: CGFloat = -1.0 // use this to flip the figure 1.0 or -1.0
            let polySide = CGFloat(5)
            let theta = 2.0 * Double.pi * Double(2.0 / polySide)
            path.move(to: CGPoint(x: center.x, y: r * flip + center.y))
            for i in 1..<Int(polySide) {
                let x: CGFloat = r * CGFloat( sin(Double(i) * theta) )
                let y: CGFloat = r * CGFloat( cos(Double(i) * theta) )
                path.addLine(to: CGPoint(x: x + center.x, y: y * flip + center.y))
            }
            path.close()
            return path
            
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
    
}
