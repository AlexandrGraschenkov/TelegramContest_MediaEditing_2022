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
    var onEndInteraction: VoidBlock?
    
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
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = true
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(imageView)
        
        let slider = UISlider(frame: bounds)
        slider.addAction(for: .valueChanged) { [weak self] in
            guard let self = self else { return }
            let value = CGFloat(self.slider.value)
            self.currentValue = value
            self.onChange?(value)
        }
        slider.addTarget(self, action: #selector(onTouchUp), for: .touchUpInside)
        slider.addTarget(self, action: #selector(onTouchUp), for: .touchUpOutside)
        addSubview(slider)
        slider.setMaximumTrackImage(UIImage(), for: .normal)
        slider.setMinimumTrackImage(UIImage(), for: .normal)
        slider.setThumbImage(UIImage(named: "circle")!, for: .normal)
        slider.translatesAutoresizingMaskIntoConstraints = true
        slider.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.slider = slider
    }
    
    @objc
    private func onTouchUp() {
        self.onEndInteraction?()
    }
}
