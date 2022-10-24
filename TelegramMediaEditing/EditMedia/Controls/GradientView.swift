//
//  GradientView.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 18/10/2022.
//

import UIKit

final class GradientView: UIView {
    
    private var gradientLayer: CAGradientLayer { self.layer as! CAGradientLayer }
    
    var colors: [UIColor] = [.clear, .black] {
        didSet {
            gradientLayer.colors = colors.map(\.cgColor)
        }
    }
    
    var startPoint: CGPoint = CGPoint(x: 0.5, y: 0) {
        didSet {
            gradientLayer.startPoint = startPoint
        }
    }
    
    var endPoint: CGPoint = CGPoint(x: 0.5, y: 1) {
        didSet {
            gradientLayer.endPoint = endPoint
        }
    }
    
    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let layer = self.layer as! CAGradientLayer
        layer.colors = self.colors.map(\.cgColor)
    }
    
    override func action(for layer: CALayer, forKey event: String) -> CAAction? {
        if event == "colors" && isInsideAnimationBlock {
            let tr = CATransition()
            tr.type = .fade
            return tr
        }
        return super.action(for: layer, forKey: event)
    }
}
