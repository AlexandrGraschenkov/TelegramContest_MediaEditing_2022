//
//  ColourPickerButton.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 16/10/2022.
//

import UIKit

final class ColourPickerButton: UIView {
    private var ringView: UIView!
    private var centerView: ColourPickerCirlce!
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    
    var onColourChange: ((UIColor) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        ringView = UIImageView(image: UIImage(named: "edit_colour_control_ring")!)
        centerView = ColourPickerCirlce()
        addSubview(ringView)
        addSubview(centerView)
        
        let longPressGR = UILongPressGestureRecognizer()
        longPressGR.addTarget(self, action: #selector(onLongPress))
        addGestureRecognizer(longPressGR)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        ringView.frame = bounds
        centerView.frame = bounds.inset(by: .all(5))
    }
    
    @objc
    private func onLongPress(recongiser: UILongPressGestureRecognizer) {
        switch recongiser.state {
        case .began:
            insertGradientView(recogniser: recongiser)
            feedbackGenerator.impactOccurred()
        case .failed, .ended, .cancelled:
            removeGradient()
            break
        case .possible:
            feedbackGenerator.prepare()
        case .changed:
            guard let activeGradientView = activeGradientView, let pickerView = pickerView else {
                return
            }
            let location = recongiser.location(in: activeGradientView)
            var center = location
            if !activeGradientView.bounds.contains(location) {
                center.x = max(0, min(activeGradientView.bounds.width, location.x))
                center.y = max(0, min(activeGradientView.bounds.height, location.y))
            }
            UIView.animate(withDuration: 0.05, delay: 0, options: [.beginFromCurrentState], animations: {
                pickerView.center = center
            }, completion: nil)
            
            let pickedColor = activeGradientView.getColor(at: center) ?? .clear
            pickerView.backgroundColor = pickedColor
            centerView.backgroundColor = pickedColor
            
            onColourChange?(pickedColor)
        @unknown default:
            break
        }
        
    }
    
    private var activeGradientView: UIImageView?
    private var pickerView: ColourPickerCirlce?
    
    private func insertGradientView(recogniser: UILongPressGestureRecognizer) {
        guard let hostView = superview?.superview?.superview else { return }
        
        let gradient = UIImageView(image: UIImage(named: "spectrum_square")!)
        gradient.translatesAutoresizingMaskIntoConstraints = false
        let selfFrame = self.frameIn(view: hostView)
        
        let width = hostView.width * 0.8
        let height = width / 1.1
        gradient.frame = CGRect(x: selfFrame.minX, y: selfFrame.maxY - height, width: width, height: height)
        
        gradient.clipsToBounds = true
        hostView.addSubview(gradient)
        activeGradientView = gradient
        
        let pickerCircle = ColourPickerCirlce()
        pickerCircle.frame = centerView.frameIn(view: gradient)
        pickerView = pickerCircle

        pickerCircle.translatesAutoresizingMaskIntoConstraints = false
        gradient.addSubview(pickerCircle)
        UIView.animate(
            withDuration: 0.1,
            delay: 0,
            options: [],
            animations: {
                pickerCircle.frame = pickerCircle.frame.inset(top: -10, left: -10, bottom: -10, right: -10)},
            completion: nil)
        transitionToGradientView(gradient: gradient)
    }
    
    private func transitionToGradientView(gradient: UIView) {
        let layerMask = CAShapeLayer()
        layerMask.frame = gradient.bounds
        
        gradient.layer.mask = layerMask
        
        let endMask = UIBezierPath.roundedRectShape(in: gradient.bounds, topLeft: self.width / 2, topRight: self.width / 2, bottomRight: self.width / 2, bottomLeft: self.width / 2).cgPath
        
        let startMask = UIBezierPath.roundedRectShape(in: CGRect(x: 0, y: gradient.height - self.width, width: self.width, height: self.width), topLeft: self.width / 2, topRight: self.width / 2, bottomRight: self.width / 2, bottomLeft: self.width / 2).cgPath
        
        
        let midMask = UIBezierPath.roundedRectShape(in: CGRect(x: 0, y: gradient.height / 2, width: gradient.width / 2, height: gradient.height / 2), topLeft: self.width / 2, topRight: gradient.width / 2, bottomRight: self.width / 2, bottomLeft: self.width / 2).cgPath
        
        layerMask.path = startMask

        
        let anim = CABasicAnimation(keyPath: "path")
        anim.duration = 0.1
        anim.autoreverses = false
        anim.isRemovedOnCompletion = true
        anim.fillMode = .forwards
        anim.fromValue = startMask
        anim.toValue = midMask
        layerMask.add(anim, forKey: "animateLayer1")
        
        let anim2 = CABasicAnimation(keyPath: "path")
        anim2.beginTime = CACurrentMediaTime() + 0.1
        anim2.duration = 0.1
        anim2.autoreverses = false
        anim2.isRemovedOnCompletion = false
        anim2.fillMode = .forwards
        anim2.fromValue = midMask
        anim2.toValue = endMask
        
        layerMask.add(anim2, forKey: "animateLayer2")
    }
    
    private func removeGradient() {
        guard let gradient = self.activeGradientView, let layerMask = self.activeGradientView?.layer.mask as? CAShapeLayer else { return }
        let endMask = UIBezierPath.roundedRectShape(in: gradient.bounds, topLeft: self.width / 2, topRight: self.width / 2, bottomRight: self.width / 2, bottomLeft: self.width / 2).cgPath
        
        let startMask = UIBezierPath.roundedRectShape(in: CGRect(x: 0, y: gradient.height - self.width, width: self.width, height: self.width), topLeft: self.width / 2, topRight: self.width / 2, bottomRight: self.width / 2, bottomLeft: self.width / 2).cgPath
        
        
        let midMask = UIBezierPath.roundedRectShape(in: CGRect(x: 0, y: gradient.height / 2, width: gradient.width / 2, height: gradient.height / 2), topLeft: self.width / 2, topRight: gradient.width / 2, bottomRight: self.width / 2, bottomLeft: self.width / 2).cgPath

        layerMask.path = endMask
        layerMask.removeAnimation(forKey: "animateLayer1")
        layerMask.removeAnimation(forKey: "animateLayer2")

        let anim = CABasicAnimation(keyPath: "path")
        anim.duration = 0.1
        anim.autoreverses = false
        anim.isRemovedOnCompletion = true
        anim.fillMode = .forwards
        anim.fromValue = endMask
        anim.toValue = midMask
        layerMask.add(anim, forKey: "animateLayer1")
        
        let anim2 = CABasicAnimation(keyPath: "path")
        anim2.beginTime = CACurrentMediaTime() + 0.1
        anim2.delegate = self
        anim2.duration = 0.1
        anim2.autoreverses = false
        anim2.isRemovedOnCompletion = false
        anim2.fillMode = .forwards
        anim2.fromValue = midMask
        anim2.toValue = startMask
        
        layerMask.add(anim2, forKey: "animateLayer2")
    }
}

extension ColourPickerButton: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        activeGradientView?.removeFromSuperview()
    }
}

extension UIBezierPath {
    static func roundedRectShape(in rect: CGRect, topLeft: CGFloat, topRight: CGFloat, bottomRight: CGFloat, bottomLeft: CGFloat) -> UIBezierPath {
        let minX = rect.minX
        let minY = rect.minY
        let maxX = rect.maxX
        let maxY = rect.maxY
        let path = UIBezierPath()
        path.move(to: CGPoint(x: minX + topLeft, y: minY))
        path.addLine(to: CGPoint(x: maxX - topRight, y: minY))
        path.addArc(withCenter: CGPoint(x: maxX - topRight, y: minY + topRight), radius: topRight, startAngle:CGFloat(3 * Double.pi / 2), endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: maxX, y: maxY - bottomRight))
        path.addArc(withCenter: CGPoint(x: maxX - bottomRight, y: maxY - bottomRight), radius: bottomRight, startAngle: 0, endAngle: CGFloat(Double.pi / 2), clockwise: true)
        path.addLine(to: CGPoint(x: minX + bottomLeft, y: maxY))
        path.addArc(withCenter: CGPoint(x: minX + bottomLeft, y: maxY - bottomLeft), radius: bottomLeft, startAngle: CGFloat(Double.pi / 2), endAngle: CGFloat(Double.pi), clockwise: true)
        path.addLine(to: CGPoint(x: minX, y: minY + topLeft))
        path.addArc(withCenter: CGPoint(x: minX + topLeft, y: minY + topLeft), radius: topLeft, startAngle: CGFloat(Double.pi), endAngle: CGFloat(3 * Double.pi / 2), clockwise: true)
        path.close()
        return path
    }
}
