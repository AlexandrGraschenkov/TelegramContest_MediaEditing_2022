//
//  ColorSlider.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 23.10.2022.
//

import UIKit

final class ColorSlider: UISlider {

    enum ThumbStroke {
        case white, black
    }
    struct Gradient {
        var from: UIColor
        var to: UIColor
    }
    
    var thumbColor: UIColor = .white {
        didSet { thumbColorView?.backgroundColor = thumbColor }
    }
    var gradientColors: Gradient = .init(from: .red, to: .blue) {
        didSet { updateGradientColors() }
    }
    var thumbStroke: ThumbStroke = .white {
        didSet { if oldValue != thumbStroke { updateThumbStrokeAnimated() } }
    }
    var sliderHeight: CGFloat = 36
    var thumbInset: CGFloat = 1
    
    func setupWithOpacity() {
        if bgChessboard != nil { return }
        
        let imgView = UIImageView(frame: bounds)
        imgView.image = UIImage(named: "chessboard_bg")?.resizableImage(withCapInsets: UIEdgeInsets(), resizingMode: .tile)
        imgView.layer.cornerRadius = bounds.height / 2
        imgView.layer.masksToBounds = true
        imgView.alpha = 0.5
        imgView.isUserInteractionEnabled = false
        insertSubview(imgView, at: 0)
        
        bgChessboard = imgView
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        bgChessboard?.frame = bounds
        if height == prevHeight {
            return
        }
        prevHeight = height
        setup()
        setupThumb()
        
        gradient.layer.cornerRadius = prevHeight / 2
        bgChessboard?.layer.cornerRadius = prevHeight / 2
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
    fileprivate var bgChessboard: UIImageView?
    fileprivate var thumbColorView: UIView!
    fileprivate var prevHeight: CGFloat = 0
    
    fileprivate func setup() {
        if setupDone { return }
        setupDone = true
        
        let thumbImg = UIImage(named: "slider_thumb_shadow")!
        let states: [UIControl.State] = [.normal, .disabled, .highlighted, .selected]
        states.forEach({setThumbImage(thumbImg, for: $0)})
        states.forEach({setMaximumTrackImage(UIImage(), for: $0)})
        states.forEach({setMinimumTrackImage(UIImage(), for: $0)})
        
        gradient = GradientView(frame: bounds)
        gradient.isUserInteractionEnabled = false
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        if let bgChessboard = bgChessboard {
            insertSubview(gradient, aboveSubview: bgChessboard)
        } else {
            insertSubview(gradient, at: 0)
        }
        updateGradientColors()
        
        backgroundColor = .clear
    }
    fileprivate func setupThumb() {
        if thumbColorView != nil { return }
        // insert into thumb colorfull circle
        // it allow us keep all logic from UISlider
        var sub: [UIView] = [] // find thumb img view
        sub = subviews
        var thumbImgView: UIImageView? = nil
        let thumbFrame = thumbRect(forBounds: bounds, trackRect: trackRect(forBounds: bounds), value: value)
        while !sub.isEmpty {
            let v = sub.popLast()
            if let v = v as? UIImageView, v.frame.size == thumbFrame.size, v.frame.minY == thumbFrame.minY {
                thumbImgView = v
                break
            }
            sub.append(contentsOf: v?.subviews ?? [])
        }
        guard let thumbImgView = thumbImgView else {
            return
        }
        
        thumbColorView = UIView(frame: thumbImgView.bounds.insetBy(dx: 0.5, dy: 0.5))
        thumbColorView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        thumbColorView.layer.cornerRadius = thumbColorView.height / 2
        thumbColorView.layer.borderColor = thumbStroke == .white ? UIColor.white.cgColor : UIColor.black.cgColor
        thumbColorView.layer.borderWidth = 3
        thumbColorView.backgroundColor = thumbColor
        thumbColorView.layer.masksToBounds = true
        thumbColorView.isUserInteractionEnabled = false
        thumbImgView.addSubview(thumbColorView)
    }
    
    fileprivate func updateGradientColors() {
        gradient?.colors = [gradientColors.from, gradientColors.to]
    }
    @objc
    private func sliderTapped(touch: UITouch) {
        let point = touch.location(in: self)
        let rect = bounds.insetBy(dx: sliderHeight/2 + thumbInset, dy: thumbInset)
        
        let percentage = Float((point.x - rect.minX) / rect.width)
        let delta = percentage * (maximumValue - minimumValue)
        let newValue = minimumValue + delta
        if newValue != value {
            setValue(newValue, animated: true)
        }
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        sliderTapped(touch: touch)
        return true
    }
    
    fileprivate func updateThumbStrokeAnimated() {
        guard let thumbColorView = thumbColorView else { return }
        
        let toColor: UIColor = thumbStroke == .white ? .white : .black
        let presentationLayer = thumbColorView.layer.presentation() as? CAShapeLayer ?? thumbColorView.layer
        let anim = CABasicAnimation(keyPath: "borderColor")
        anim.duration = 0.2
        anim.autoreverses = false
        anim.isRemovedOnCompletion = false
        anim.fillMode = .forwards
        anim.fromValue = presentationLayer.borderColor
        anim.toValue = toColor.cgColor
        thumbColorView.layer.add(anim, forKey: "borderColor")
        
//        thumbColorView.layer.borderColor = toColor.cgColor
    }
}
