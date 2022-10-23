//
//  ColorSlider.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 23.10.2022.
//

import UIKit

final class ColorSlider: UISlider {

    var fromColor: UIColor = .red {
        didSet { updateGradientColors() }
    }
    var toColor: UIColor = .blue {
        didSet { updateGradientColors() }
    }
    var sliderHeight: CGFloat = 36
    var thumbInset: CGFloat = 1
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if height == prevHeight {
            return
        }
        prevHeight = height
        setup()
        setupThumb()
        
        gradient.layer.cornerRadius = prevHeight / 2
    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let h = min(sliderHeight, bounds.height)
        return CGRect(mid: bounds.mid, size: CGSize(width: bounds.width, height: h))
    }

    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let thumbBounds = rect.insetBy(dx: thumbInset, dy: thumbInset)
        let thumbSize = thumbBounds.height
        let x = CGFloat(value).percentToRange(min: thumbBounds.minX, max: thumbBounds.maxX - thumbSize)
        let y = thumbBounds.minY
        return CGRect(x: x, y: y, width: thumbSize, height: thumbSize)
    }
    
    fileprivate var setupDone: Bool = false
    fileprivate var gradient: GradientView!
    fileprivate var thumbColor: UIView!
    fileprivate var prevHeight: CGFloat = 0
    fileprivate lazy var defaultThumbImg: UIImage = UIImage(named: "slider_thumb_black")!
    
    fileprivate func setup() {
        if setupDone { return }
        setupDone = true
        
        let states: [UIControl.State] = [.normal, .disabled, .highlighted, .selected]
        states.forEach({setThumbImage(defaultThumbImg, for: $0)})
        states.forEach({setMaximumTrackImage(UIImage(), for: $0)})
        states.forEach({setMinimumTrackImage(UIImage(), for: $0)})
        
        gradient = GradientView(frame: bounds)
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        insertSubview(gradient, at: 0)
        updateGradientColors()
        
        backgroundColor = .clear
    }
    fileprivate func setupThumb() {
        if thumbColor != nil { return }
        // insert into thumb colorfull circle
        // it allow us keep all logic from UISlider
        var sub: [UIView] = [] // find thumb img view
        sub = subviews
        var thumbImgView: UIImageView? = nil
        let thumbFrame = thumbRect(forBounds: bounds, trackRect: trackRect(forBounds: bounds), value: value)
        while !sub.isEmpty {
            let v = sub.popLast()
            if let v = v as? UIImageView, v.frame == thumbFrame {
                thumbImgView = v
                break
            }
            sub.append(contentsOf: v?.subviews ?? [])
        }
        guard let thumbImgView = thumbImgView else {
            return
        }
        
        thumbColor = UIView(frame: thumbImgView.bounds.insetBy(dx: 4, dy: 4))
        thumbColor.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        thumbColor.layer.cornerRadius = thumbColor.height / 2
        thumbColor.backgroundColor = UIColor.green
        thumbColor.layer.masksToBounds = true
        thumbColor.isUserInteractionEnabled = false
        thumbImgView.addSubview(thumbColor)
    }
    
    fileprivate func updateGradientColors() {
        gradient.colors = [fromColor, toColor]
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return true
    }
}
