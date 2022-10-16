//
//  ToolSlider.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 15/10/2022.
//

import UIKit

final class ToolSlider: UIView {
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
        addSubview(slider)
        slider.setMaximumTrackImage(UIImage(), for: .normal)
        slider.setMinimumTrackImage(UIImage(), for: .normal)
        slider.setThumbImage(UIImage(named: "circle")!, for: .normal)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
//
//        let movingPart = UIView(frame: CGRect(x: 0, y: (height - 28) / 2, width: 28, height: 28))
//        movingPart.translatesAutoresizingMaskIntoConstraints = false
//        addSubview(movingPart)
//
//        let panGR = UIPanGestureRecognizer()
//        addGestureRecognizer(panGR)
        
    }
}
