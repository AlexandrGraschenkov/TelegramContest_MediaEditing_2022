//
//  BackOrCancelButton.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 15/10/2022.
//

import UIKit

final class BackOrCancelButton: UIButton {
    enum Mode: Equatable {
        case cancel
        case back
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private var animatedView: CrossOrArrowView!
    
    private var mode: Mode = .cancel
    
    func setMode(_ mode: Mode, animationDuration: Double) {
        guard mode != self.mode else { return }
        self.mode = mode
        animatedView.setShape(mode, animated: true, duration: animationDuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        let animatedView = CrossOrArrowView(frame: bounds)
        animatedView.isUserInteractionEnabled = false
        addSubview(animatedView)
        animatedView.translatesAutoresizingMaskIntoConstraints = true
        animatedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        animatedView.setShape(mode, animated: false, duration: 0)
        self.animatedView = animatedView
    }
}

private final class CrossOrArrowView: UIView {
    var mode: BackOrCancelButton.Mode = .cancel
    
    private let crossSize = CGSize(width: 11, height: 11)
    private let arrowSize = CGSize(width: 5.5, height: 11.5)
    
    private let l1: CAShapeLayer
    private let l2: CAShapeLayer
    
    private func createNewPath() -> UIBezierPath {
        let path = UIBezierPath()
        path.lineWidth = 4
        path.lineCapStyle = .round
        return path
    }
    
    private var crossPath: UIBezierPath {
        let path = UIBezierPath()
        path.lineWidth = 2
        path.lineCapStyle = .round
        path.move(to: .init(x: (width + crossSize.width) / 2, y: (height - crossSize.height) / 2) )
        path.addLine(to: .init(x: (width - crossSize.width) / 2, y: (height + crossSize.height) / 2) )
        path.move(to: .init(x: (width - crossSize.width) / 2, y: (height - crossSize.height) / 2))
        path.addLine(to: .init(x: (width + crossSize.width) / 2, y: (height + crossSize.height) / 2) )
        return path
    }
    
    private var arrowPath: UIBezierPath {
        let path = UIBezierPath()
        path.lineWidth = 2
        path.lineCapStyle = .round
        path.move(to: .init(x: (width + arrowSize.width) / 2, y: (height - arrowSize.height) / 2))
        path.addLine(to: .init(x: (width - arrowSize.width) / 2, y: height / 2))
        path.move(to: .init(x: (width - arrowSize.width) / 2, y: height / 2))
        path.addLine(to: .init(x: (width + arrowSize.width) / 2, y: (height + arrowSize.height) / 2))
        return path
    }
    
    override init(frame: CGRect) {
        self.l1 = CAShapeLayer()
        self.l2 = CAShapeLayer()
        super.init(frame: frame)
        for layer in [l1, l2] {
            self.layer.addSublayer(layer)
            layer.lineWidth = 2
            layer.lineCap = .round
            layer.fillColor = UIColor.white.cgColor
            layer.strokeColor = UIColor.white.cgColor
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setShape(_ mode: BackOrCancelButton.Mode, animated: Bool, duration: Double) {
        let path = createNewPath()
        let path2 = createNewPath()
        switch mode {
        case .cancel:
            path.move(to: .init(x: (width + crossSize.width) / 2, y: (height - crossSize.height) / 2) )
            path.addLine(to: .init(x: (width - crossSize.width) / 2, y: (height + crossSize.height) / 2) )
            
            path2.move(to: .init(x: (width - crossSize.width) / 2, y: (height - crossSize.height) / 2))
            path2.addLine(to: .init(x: (width + crossSize.width) / 2, y: (height + crossSize.height) / 2) )
        case .back:
            path.move(to: .init(x: (width + arrowSize.width) / 2, y: (height - arrowSize.height) / 2))
            path.addLine(to: .init(x: (width - arrowSize.width) / 2, y: height / 2))
            
            path2.move(to: .init(x: (width - arrowSize.width) / 2, y: height / 2))
            path2.addLine(to: .init(x: (width + arrowSize.width) / 2, y: (height + arrowSize.height) / 2))
        }
        
        if animated {
            lastAnimationInfo = [(l1, path), (l2, path2)]
            animatePath(of: l1, to: path, duration: duration)
            animatePath(of: l2, to: path2, duration: duration)
        }  else {
            l1.path = path.cgPath
            l2.path = path2.cgPath
        }
    }
    
    private var lastAnimationInfo: [(CAShapeLayer, UIBezierPath)] = []
    
    private func animatePath(of layer: CAShapeLayer, to path: UIBezierPath, duration: Double) {
        let animation = CABasicAnimation(keyPath: "path")
        animation.delegate = self
        animation.duration = duration
        animation.fromValue = layer.path
        animation.toValue = path.cgPath
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        layer.add(animation, forKey: "path")
    }
}

extension CrossOrArrowView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        for (layer, path) in lastAnimationInfo {
            layer.path = path.cgPath
            layer.removeAnimation(forKey: "path")
        }
        lastAnimationInfo = []
    }
}
