//
//  ToolSlider.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 15/10/2022.
//

import UIKit

final class ToolSlider: UIView {
    
    var valuesRange: ClosedRange<CGFloat> = 0...1 {
        didSet {
            slider.minimumValue = Float(valuesRange.lowerBound)
            slider.maximumValue = Float(valuesRange.upperBound)
        }
    }
    
    var currentValue: CGFloat = 0 {
        didSet {
            slider.value = Float(currentValue)
        }
    }
    
    var onChange: ((CGFloat) -> Void)?
    
    private lazy var slider = UISlider(frame: self.bounds)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        let imageView = UIImageView(image: UIImage(named: "slider_bg")!)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(imageView)
        
        let slider = UISlider(frame: bounds)
        slider.addAction(for: .valueChanged) { [weak self] in
            self?.onChange?(CGFloat(self?.slider.value ?? 0))
        }
        addSubview(slider)
        slider.setMaximumTrackImage(UIImage(), for: .normal)
        slider.setMinimumTrackImage(UIImage(), for: .normal)
        slider.setThumbImage(UIImage(named: "circle")!, for: .normal)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.slider = slider
        
//
//        let movingPart = UIView(frame: CGRect(x: 0, y: (height - 28) / 2, width: 28, height: 28))
//        movingPart.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(movingPart)
//
//        let panGR = UIPanGestureRecognizer()
//        addGestureRecognizer(panGR)
        
    }
}
