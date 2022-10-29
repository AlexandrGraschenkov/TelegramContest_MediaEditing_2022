//
//  DemoToolSizeView.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 29.10.2022.
//

import UIKit

/// View for display Tool size on screen
class DemoToolSizeView: UIView {

    func animateAppear() {
        alpha = 0
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState]) {
            self.alpha = 1
        }
    }
    
    func animateDisappearAndRemove() {
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState]) {
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
    
    override class var layerClass: AnyClass {
        CAShapeLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        shape?.fillColor = UIColor.white.cgColor
        shape?.strokeColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        shape?.lineWidth = 0.5
        
        shape?.shadowColor = UIColor.black.cgColor
        shape?.shadowOpacity = 0.5
        shape?.shadowOffset = CGSize(width: 0, height: 1)
        shape?.shadowRadius = 4
    }
    
    private var prevSize: CGSize = .zero
    private var shape: CAShapeLayer? { layer as? CAShapeLayer }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if prevSize == bounds.size { return }
        
        CALayer.withoutAnimation {
            shape?.path = CGPath(ellipseIn: bounds, transform: nil)
        }
    }

}
