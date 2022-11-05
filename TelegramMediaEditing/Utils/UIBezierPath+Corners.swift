//
//  UIBezierPath+Corners.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 05.11.2022.
//

import UIKit


public extension UIBezierPath {
    class func roundRect(_ rect: CGRect, tl: CGFloat = 0, tr: CGFloat = 0, bl: CGFloat = 0, br: CGFloat) -> UIBezierPath {
        let bezier = UIBezierPath()
        let tlP = rect.origin
        let trP = CGPoint(x: tlP.x + rect.size.width, y: tlP.y)
        let brP = CGPoint(x: tlP.x + rect.size.width, y: tlP.y + rect.size.height)
        let blP = CGPoint(x: tlP.x, y: tlP.y + rect.size.height)
        
        /*
         
          2_____3
          /     \
         1|     |4
          |     |
         8|     |5
           \   /
           7   6
         
         */
        let pi_2: CGFloat = .pi / 2
        bezier.move(to: CGPoint(x: tlP.x, y: tlP.y + tl))
        if tl > 0 {
            bezier.addArc(withCenter: CGPoint(x: tlP.x + tl, y: tlP.y + tl),
                          radius: tl,
                          startAngle: .pi,
                          endAngle: .pi*1.5,
                          clockwise: true)
        }
        
        
        bezier.addLine(to: CGPoint(x: trP.x - tr, y: trP.y))
        if tr > 0 {
            bezier.addArc(withCenter: CGPoint(x: trP.x - tr, y: trP.y + tr),
                          radius: tr,
                          startAngle: -pi_2,
                          endAngle: 0,
                          clockwise: true)
        }
        
        
        bezier.addLine(to: CGPoint(x: brP.x, y: brP.y - br))
        if br > 0 {
            bezier.addArc(withCenter: CGPoint(x: brP.x - br, y: brP.y - br),
                          radius: br,
                          startAngle: 0,
                          endAngle: pi_2,
                          clockwise: true)
        }
        
        
        bezier.addLine(to: CGPoint(x: blP.x + bl, y: blP.y))
        if bl > 0 {
            bezier.addArc(withCenter: CGPoint(x: blP.x + bl, y: blP.y - bl),
                          radius: bl,
                          startAngle: pi_2,
                          endAngle: .pi,
                          clockwise: true)
        }
        
        bezier.close()
        
        return bezier
    }
}
