//
//  PhotoPermissionOverlay.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 12/10/2022.
//

import UIKit
import Lottie
import Photos

final class PhotoPermissionOverlay: UIView {
    private var buttonContainer: DoubleShimmerContainer!
    private var button: UIButton!
    private var animationView: LottieAnimationView!
    
    var onPermissionGranted: (() -> Void)?
    var onNavigationIntent: ((UIViewController) -> Void)?
    private var dismissCompletion: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func startAnimation() {
        buttonContainer.startAnimation()
        animationView.play()
    }
    
    private func setup() {
        backgroundColor = .black
        let centerContainer = UIView()
        centerContainer.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(centerContainer)
        let animation = LottieAnimation.named("duck")
        let animationView = LottieAnimationView(animation: animation)
        self.animationView = animationView
        
        let shimmerContainer = DoubleShimmerContainer()
        shimmerContainer.layer.masksToBounds = true
        shimmerContainer.corner = 10
        shimmerContainer.backgroundColor = UIColor(rgb: 0x007AFF)
        centerContainer.addSubview(shimmerContainer)
        self.buttonContainer = shimmerContainer
        
        let button = HighlightButton()
        button.highlightBg = UIColor(white: 0, alpha: 0.4)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        centerContainer.addSubview(button)
        button.setTitle("Allow Access", for: .normal)
        button.addTarget(self, action: #selector(onButtonTap), for: .touchUpInside)
        self.button = button
        
        let label = UILabel()
        label.textAlignment = .center
        label.text = "Access Your Photos and Videos"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .white
        
        let views: [UIView] = [animationView, shimmerContainer, button, label]
        views.forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            centerContainer.addSubview(view)
        }
        
        NSLayoutConstraint.activate([
            centerContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            centerContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            centerContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            animationView.topAnchor.constraint(equalTo: centerContainer.topAnchor),
            animationView.centerXAnchor.constraint(equalTo: centerContainer.centerXAnchor),
            animationView.widthAnchor.constraint(equalToConstant: 144),
            animationView.heightAnchor.constraint(equalToConstant: 144),
            
            label.leadingAnchor.constraint(equalTo: centerContainer.leadingAnchor, constant: 15),
            label.trailingAnchor.constraint(equalTo: centerContainer.trailingAnchor, constant: -15),
            label.topAnchor.constraint(equalTo: animationView.bottomAnchor, constant: 20),
            
            
            shimmerContainer.leadingAnchor.constraint(equalTo: centerContainer.leadingAnchor, constant: 16),
            shimmerContainer.trailingAnchor.constraint(equalTo: centerContainer.trailingAnchor, constant: -16),
            shimmerContainer.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 25),
            shimmerContainer.heightAnchor.constraint(equalToConstant: 50),
            shimmerContainer.bottomAnchor.constraint(equalTo: centerContainer.bottomAnchor),
            
            button.leadingAnchor.constraint(equalTo: shimmerContainer.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: shimmerContainer.trailingAnchor),
            button.topAnchor.constraint(equalTo: shimmerContainer.topAnchor),
            button.bottomAnchor.constraint(equalTo: shimmerContainer.bottomAnchor),
        ])
    }
    
    func dismiss(completion: @escaping () -> Void) {
        let maskLayer = CAGradientLayer()

        maskLayer.frame = CGRect(x: 0, y: -height, width: width, height: height * 2)
        maskLayer.colors = [
            UIColor.clear,
            UIColor.white,
        ].map(\.cgColor)
        
        maskLayer.startPoint = .init(x: 0, y: 0)
        maskLayer.endPoint = .init(x: 0, y: 0.5)

        layer.mask = maskLayer
        
        dismissCompletion = {[weak self] in
            self?.buttonContainer.stopAnimation()
            completion()
        }
        let anim = CABasicAnimation(keyPath: "transform.translation.y")
        anim.duration = 0.3
        anim.delegate = self
        anim.autoreverses = false
        anim.isRemovedOnCompletion = false
        anim.fillMode = .forwards
        anim.fromValue = 0
        anim.toValue = height * 2
        maskLayer.add(anim, forKey: "animateLayer")
    }
    
    @objc
    private func onButtonTap() {
        PHPhotoLibrary.requestAccess { granted in
            if granted {
                self.onPermissionGranted?()
            } else {
                let alert = UIAlertController(title: "No photo access", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
                    
                    UIApplication.openSettings(onReturnToApplication: {
                        if PHPhotoLibrary.accessAllowed {
                            self.onPermissionGranted?()
                        }
                    })
                }))
                
                self.onNavigationIntent?(alert)
            }
        }
    }
}

extension PhotoPermissionOverlay: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        dismissCompletion?()
    }
}

final class ShimmeringButton: UIButton {
    private let movingView = UIImageView(image: UIImage(named: "btn_shine"))
    
    func startShimmering() {
        addSubview(movingView)
        movingView.layer.compositingFilter = "softLightBlendMode"

        movingView.x = -movingView.width
        movingView.frame.size = CGSize(width: bounds.width / 2, height: height)
        UIView.animateKeyframes(withDuration: 2.5, delay: 0, options: [.repeat], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.3) {
                self.movingView.x = self.width
            }
        }, completion: nil)
    }
    
    func stopShimmering() {
        layer.removeAllAnimations()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        movingView.frame.size = CGSize(width: bounds.width / 2, height: height)
    }
}
