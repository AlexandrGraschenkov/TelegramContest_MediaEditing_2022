//
//  ColourPickerButton.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 16/10/2022.
//

import UIKit

final class ColourPickerButton: UIView {
    private var ringView: UIView!
    private var centerView: ColourPickerCirlceOpacity!
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var onColourChange: ((TextPanelPropertyChange.Change<UIColor>, Bool) -> Void)?
    var onPress: ((ColourPickerButton) -> Void)?
    
    var selectedColour: UIColor {
        get { centerView.color }
        set { centerView.color = newValue }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        ringView = UIImageView(image: UIImage(named: "edit_colour_control_ring")!)
        centerView = ColourPickerCirlceOpacity(frame: CGRect(origin: .zero, size: .square(side: 30)))
        addSubview(ringView)
        addSubview(centerView)
        
        let longPressGR = UILongPressGestureRecognizer()
        longPressGR.addTarget(self, action: #selector(onLongPressOrPan))
        addGestureRecognizer(longPressGR)
        
        let panGR = UIPanGestureRecognizer()
        panGR.addTarget(self, action: #selector(onLongPressOrPan))
        addGestureRecognizer(panGR)
        
        let tapGR = UITapGestureRecognizer()
        tapGR.addTarget(self, action: #selector(onTap(tap:)))
        addGestureRecognizer(tapGR)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let contentSize = CGSize.square(side: 33)
        let inset = (width - contentSize.width) / 2
        ringView.frame = bounds.inset(by: .all(inset))
        centerView.frame = ringView.frame.inset(by: .all(5))
    }
    
    @objc
    func onTap(tap: UITapGestureRecognizer) {
        if tap.state == .ended {
            onPress?(self)
        }
    }
    
    private var startColor: UIColor?
    
    @objc
    private func onLongPressOrPan(recongizer: UIGestureRecognizer) {
        switch recongizer.state {
        case .began:
            startColor = selectedColour
            insertGradientView(recogniser: recongizer)
            if recongizer is UILongPressGestureRecognizer {
                feedbackGenerator.impactOccurred()
            }
        case .failed, .cancelled:
            removeGradient()
        case .ended:
            onColourChange?(.init(oldValue: startColor, newValue: selectedColour), true)
            removeGradient()
        case .possible:
            if recongizer is UILongPressGestureRecognizer {
                feedbackGenerator.prepare()
            }
        case .changed:
            guard let activeGradientView = activeGradientView, let pickerView = pickerView else {
                return
            }
            let location = recongizer.location(in: activeGradientView)
            var center = location
            if !activeGradientView.bounds.contains(location) {
                center.x = max(0, min(activeGradientView.bounds.width-1, location.x))
                center.y = max(0, min(activeGradientView.bounds.height-1, location.y))
            }
//            UIView.animate(withDuration: 0.05, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
            pickerView.center = pickerView.superview!.convert(center.add(self.pickerViewOffset), from: activeGradientView)
//            }, completion: nil)
            
            let pickedColor = activeGradientView.getColor(at: center) ?? .clear
            pickerView.backgroundColor = pickedColor
            let oldColor = selectedColour
            centerView.color = pickedColor
            
            onColourChange?(.init(oldValue: oldColor, newValue: pickedColor), false)
        @unknown default:
            break
        }
        
    }
    
    private var activeGradientView: UIImageView?
    private var activeGradientContainer: UIView?
    private var pickerView: ColourPickerCirlce?
    private let pickerViewOffset: CGPoint = .init(x: 0, y: -60)
    
    private func insertGradientView(recogniser: UIGestureRecognizer) {
        guard let hostView = superview?.superview?.superview else { return }
        
        let gradient = UIImageView(image: UIImage(named: "spectrum_square")!)
        gradient.translatesAutoresizingMaskIntoConstraints = true
        let gradientContainer = UIView()
        gradientContainer.translatesAutoresizingMaskIntoConstraints = true
        gradientContainer.layer.masksToBounds = true
        gradientContainer.layer.cornerRadius = self.width / 2
        let selfFrame = self.frameIn(view: hostView)
        
        let width = hostView.width * 0.8
        let height = width / 1.1
        gradientContainer.frame = CGRect(x: selfFrame.minX, y: selfFrame.maxY - height, width: width, height: height)
        gradient.frame = gradientContainer.bounds
        gradientContainer.addSubview(gradient)
        
        gradient.clipsToBounds = true
        hostView.addSubview(gradientContainer)
        activeGradientView = gradient
        activeGradientContainer = gradientContainer
        
        let pickerCircle = ColourPickerCirlce()
        pickerCircle.frame = centerView.frameIn(view: hostView).inset(by: UIEdgeInsets.all(-10)).offsetBy(dx: pickerViewOffset.x, dy: pickerViewOffset.y)
        pickerCircle.transform = CGAffineTransform.init(scaleX: 0.4, y: 0.4)
        pickerCircle.alpha = 0
        pickerView = pickerCircle

        pickerCircle.translatesAutoresizingMaskIntoConstraints = true
        hostView.addSubview(pickerCircle)
        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [],
            animations: {
                pickerCircle.transform = .identity
                pickerCircle.alpha = 1
            },
            completion: nil)
        transitionToGradientView(gradient: gradient)
    }
    
    private func transitionToGradientView(gradient: UIView) {
        let viewMask = UIView(frame: centerView.convert(centerView.bounds, to: gradient).insetBy(dx: 2, dy: 2))
        viewMask.layer.cornerRadius = viewMask.width/2
        viewMask.layer.masksToBounds = true
        viewMask.backgroundColor = .black
        gradient.mask = viewMask
        
        let fromRadius = viewMask.bounds.size.diameter / 2
        let toRadius = gradient.bounds.size.diameter / 2
        let scale = 3 * toRadius / fromRadius
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            viewMask.transform = CGAffineTransform(scaleX: scale, y: scale)
        } completion: { _ in
        }
    }
    
    private func removeGradient() {
        guard let gradient = self.activeGradientView, let viewMask = gradient.mask else { return }
        
        let circle = pickerView
        pickerView = nil
        let gradientOverlay = UIView(frame: gradient.bounds)
        gradientOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        gradientOverlay.backgroundColor = centerView.color
        gradientOverlay.alpha = 0
        gradient.addSubview(gradientOverlay)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            viewMask.transform = .identity
            circle?.transform = .init(scaleX: 0.2, y: 0.2)
            circle?.alpha = 0
            gradientOverlay.alpha = 1
        } completion: { _ in
            self.activeGradientContainer?.removeFromSuperview()
            viewMask.removeFromSuperview()
            circle?.removeFromSuperview()
            gradientOverlay.removeFromSuperview()
        }
    }
}

fileprivate extension CGSize {
    var diameter: CGFloat {
        return sqrt(pow(width, 2) + pow(height, 2))
    }
}
