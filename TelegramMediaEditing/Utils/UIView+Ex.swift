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
    func pinEdges(to otherView: UIView,
                  edges: NSDirectionalRectEdge = .all,
                  insets: UIEdgeInsets = .zero,
                  respectSafeArea: Bool = false
    ) {
        self.translatesAutoresizingMaskIntoConstraints = false
        var constraints: [NSLayoutConstraint] = []
        if edges.contains(.leading) {
            let other = respectSafeArea ? otherView.safeAreaLayoutGuide.leadingAnchor : otherView.leadingAnchor
            constraints.append(leadingAnchor.constraint(equalTo: other, constant: insets.left))
        }
        if edges.contains(.trailing) {
            let other = respectSafeArea ? otherView.safeAreaLayoutGuide.trailingAnchor : otherView.trailingAnchor
            constraints.append(trailingAnchor.constraint(equalTo: other, constant: insets.right))
        }
        if edges.contains(.top) {
            let other = respectSafeArea ? otherView.safeAreaLayoutGuide.topAnchor : otherView.topAnchor
            constraints.append(topAnchor.constraint(equalTo: other, constant: insets.top))
        }
        if edges.contains(.bottom) {
            let other = respectSafeArea ? otherView.safeAreaLayoutGuide.bottomAnchor : otherView.bottomAnchor
            constraints.append(bottomAnchor.constraint(equalTo: other, constant: insets.bottom))
        }
        NSLayoutConstraint.activate(constraints)
    }
    
    func pinWidth(to constant: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.widthAnchor.constraint(equalToConstant: constant).isActive = true
    }
    
    func pinHeight(to constant: CGFloat) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.heightAnchor.constraint(equalToConstant: constant).isActive = true
    }
    
    func pinSize(to size: CGSize) {
        pinWidth(to: size.width)
        pinHeight(to: size.height)
    }
    
    func pinCenterX(to otherView: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.centerXAnchor.constraint(equalTo: otherView.centerXAnchor).isActive = true
    }
    
    func pinCenterY(to otherView: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        self.centerYAnchor.constraint(equalTo: otherView.centerYAnchor).isActive = true
    }
    
    func pinCenter(to otherView: UIView) {
        pinCenterX(to: otherView)
        pinCenterY(to: otherView)
    }
}
