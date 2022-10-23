//
//  ColorSpectrumView.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 22.10.2022.
//

import UIKit

final class ColorSpectrumView: UIImageView, ColorSelectorProtocol {
    var color: UIColor = UIColor.white
    
    var onColorSelect: ((UIColor) -> ())?
    
    deinit {
        centerView.removeFromSuperview()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if image == nil {
            setup()
        }
    }

    // MARK: - private
    private var centerInitalied = false
    private lazy var centerView: ColourPickerCirlce = {
        let v = ColourPickerCirlce(frame: CGRect(mid: bounds.mid, size: CGSize(width: 50, height: 50)))
        v.backgroundColor = color
        return v
    }()
    private func setup() {
        image = UIImage(named: "spectrum_square")!
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onGesture(_:)))
        addGestureRecognizer(tap)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onGesture(_:)))
        addGestureRecognizer(pan)
        isUserInteractionEnabled = true
    }
    
    @objc
    fileprivate func onGesture(_ gesture: UIGestureRecognizer) {
        let loc = gesture.location(in: self)
        
//        switch gesture.state {
//        case .began:
//            centerView.
//        }
        
        switch gesture.state {
        case .began:
            superview?.superview?.addSubview(centerView)
            centerView.alpha = 0
            centerView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut]) {
                self.centerView.transform = .identity
                self.centerView.alpha = 1
            } completion: { _ in }
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState]) {
                self.centerView.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
                self.centerView.alpha = 0
            } completion: { _ in
                self.centerView.removeFromSuperview()
            }
            
        default: break
        }
        
        switch gesture.state {
        case .began, .changed, .ended:
            let imgLoc = CGPoint(x: loc.x.clamp(0, bounds.width-1),
                                 y: loc.y.clamp(0, bounds.height-1))
            
            color = self.getColor(at: imgLoc) ?? .black
            centerView.backgroundColor = color
            centerView.center = convert(imgLoc, to: centerView.superview).add(CGPoint(x: 0, y: -60))
            
        default: break
        }
        
    }
}
