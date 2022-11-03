//
//  LayerContainer.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 26.10.2022.
//

import UIKit

class LayerContainer {
    var layers: [String: CALayer] = [:]
    var views: [String: UIView] = [:] // for handle UIView manually
    var mediaView: UIView?
    var fillView: UIView?
    let toolFeedback = UIImpactFeedbackGenerator(style: .light)
    
    func generateUniqueName(prefix: String? = nil) -> String { // use prefix to distinguish object type
        generatedCount += 1
        return (prefix ?? "") + "_id_\(generatedCount)"
//        var name: String
//        repeat {
//            name = (prefix ?? "") + "_" + .random(length: 5)
//        } while (usedNames.contains(name))
//        usedNames.insert(name)
//        return name
    }
    
    func animateFill(fromPoint point: CGPoint, color: UIColor) {
        guard let fillView = fillView else {
            return
        }

        let prevFillView = UIView(frame: fillView.frame)
        prevFillView.backgroundColor = fillView.backgroundColor
        fillView.superview?.insertSubview(prevFillView, belowSubview: fillView)
        
        let newColor = color.withAlphaComponent(1)
        
        let mask = UIView(frame: CGRect(mid: point, size: .square(side: 4)))
        mask.backgroundColor = UIColor.white
        mask.layer.masksToBounds = true
        mask.layer.cornerRadius = mask.width / 2
        
        self.fillView?.mask = mask
        self.fillView?.backgroundColor = newColor
        let diameter = self.fillView!.bounds.size.point.distance()
        let scale = diameter / (mask.width * 0.5)
        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseInOut]) {
            mask.transform = .init(scaleX: scale, y: scale)
        } completion: { _ in
            mask.removeFromSuperview()
            prevFillView.removeFromSuperview()
        }
        toolFeedback.impactOccurred()
    }
    
    /// to generate unique names during launch
    fileprivate var generatedCount: Int = 0
//    fileprivate var usedNames: Set<String> = .init()
}
