//
//  UIView+Ex.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 11.10.2022.
//

import UIKit

extension UIView {
    
    var x: CGFloat {
        get { return frame.origin.x }
        set { frame.origin.x = newValue }
    }
    
    var y: CGFloat {
        get { return frame.origin.y }
        set { frame.origin.y = newValue }
    }
    
    var right: CGFloat {
        get { return frame.maxX }
        set { frame.origin.x = newValue - frame.size.width }
    }
    
    var bottom: CGFloat {
        get { return frame.maxY }
        set { frame.origin.y = newValue - frame.size.height }
    }
    
    var width: CGFloat {
        get { return frame.width }
        set { frame.size.width = newValue }
    }
    
    var height: CGFloat {
        get { return frame.height }
        set { frame.size.height = newValue }
    }
    
    func fadeAnimation(duration: Double = 0.2) {
        let transition = CATransition()
        transition.duration = duration
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        transition.type = CATransitionType.fade
        
        self.layer.add(transition, forKey: "fade")
    }
    
    func infiniteRotation(duration: Double = 1.0) {
        self.layer.infiniteRotation(duration: duration)
    }
    
    func sendToBack() {
        self.superview?.sendSubviewToBack(self)
    }
    
    func bringToFront() {
        self.superview?.bringSubviewToFront(self)
    }
    
    func frameIn(view: UIView?) -> CGRect {
        return self.convert(bounds, to: view)
    }
}

// MARK: - animations
extension UIView {
    func shake_my(duration: Double = 0.3) {
        let shakeKey = "shake_key"
        layer.removeAnimation(forKey: shakeKey)
        let vals: [Double] = [-2, 2, -2, 2, 0]
        
        let translation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        translation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        translation.values = vals
        
        let rotation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        rotation.values = vals.map { (degrees: Double) in
            let radians: Double = (Double.pi * degrees) / 180.0
            return radians
        }
        
        let shakeGroup: CAAnimationGroup = CAAnimationGroup()
        shakeGroup.animations = [translation, rotation]
        shakeGroup.duration = duration
        self.layer.add(shakeGroup, forKey: shakeKey)
    }
}

extension CALayer {
    
    func infiniteRotation(duration: Double = 1.0) {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = CGFloat.pi * 2.0
        rotationAnimation.duration = Double(duration)
        rotationAnimation.isCumulative = true
        rotationAnimation.repeatCount = 999999.0
        
        self.add(rotationAnimation, forKey: "rotation")
    }
    
    var isAnimating: Bool {
        return (animationKeys() ?? []).count > 0
    }
    
    class func withoutAnimation(_ actionsWithoutAnimation: () -> Void){
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        actionsWithoutAnimation()
        CATransaction.commit()
    }
}

// Autolayout
extension UIView {
    func pinEdges(to otherView: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.leadingAnchor.constraint(equalTo: otherView.leadingAnchor),
            self.topAnchor.constraint(equalTo: otherView.topAnchor),
            self.trailingAnchor.constraint(equalTo: otherView.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: otherView.bottomAnchor),
        ])
    }
}
