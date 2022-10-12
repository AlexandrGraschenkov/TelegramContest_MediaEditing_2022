//
//  AccessVC.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 11.10.2022.
//

import UIKit
import Photos
import Lottie

// Dirty, but who cares?
class DoubleShimmerContainer: UIView {
    lazy var secondContainer: UIView = {
        let container = UIView()
        container.alpha = 0.6
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(container, at: 0)
        container.backgroundColor = backgroundColor
        container.layer.masksToBounds = true
        return container
    }()
    fileprivate var animLayers: [CALayer] = []
    
    override var backgroundColor: UIColor? {
        didSet {
            secondContainer.backgroundColor = backgroundColor
        }
    }
    var corner: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            secondContainer.layer.cornerRadius = newValue-1
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        secondContainer.frame = bounds.insetBy(dx: 2, dy: 2)
    }
    
    func startAnimation() {
        stopAnimation()
        
        let shineWidth: CGFloat = 150
        addShine(toView: self, width: shineWidth, shineVal: 0.4)
    }
    
    func stopAnimation() {
        animLayers.forEach({$0.removeFromSuperlayer()})
        animLayers.removeAll()
    }
    
    private func addShine(toView: UIView, width: CGFloat, shineVal: CGFloat = 1) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.frame = CGRect(x: 0, y: 0, width: width, height: toView.height)
        gradient.colors = [UIColor(white: 1, alpha: 0),
                           UIColor(white: 1, alpha: 0.78*shineVal),
                           UIColor(white: 1, alpha: 1*shineVal),
                           UIColor(white: 1, alpha: 1*shineVal),
                           UIColor(white: 1, alpha: 1*shineVal),
                           UIColor(white: 1, alpha: 0.78*shineVal),
                           UIColor(white: 1, alpha: 0)].map({$0.cgColor})
        gradient.locations = [0.2, 0.4, 0.45, 0.5, 0.55, 0.6, 0.8]
        toView.layer.insertSublayer(gradient, at: 0)

        let anim = CABasicAnimation(keyPath: "transform.translation.x")
        anim.duration = 3
        anim.repeatCount = .infinity
        anim.autoreverses = false
        anim.isRemovedOnCompletion = false
        anim.fillMode = .forwards
        anim.fromValue = -gradient.frame.width*4
        anim.toValue = gradient.frame.width*4 + toView.width
//        print(anim.fromValue, anim.toValue)
        gradient.add(anim, forKey: "animateLayer")
        animLayers.append(gradient)
    }
}

/// make button more interactable
class HighlightButton: UIButton {
    var normalBg: UIColor = UIColor.clear
    var highlightBg: UIColor = UIColor(white: 0, alpha: 0.1)
    fileprivate var isSetupDone: Bool = false
    fileprivate func setup() {
        if isSetupDone { return }
        
        addTarget(self, action: #selector(pressDown), for: .touchDown)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setup()
    }
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? highlightBg : normalBg
        }
    }
    
    @objc private func pressDown() {
        isHighlighted = true
    }
}

class AccessVC: UIViewController {

    @IBOutlet weak var accessButton: UIButton!
    @IBOutlet weak var doubleShineButtCntainer: DoubleShimmerContainer!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var animationView: LottieAnimationView!
//    @IBOutlet weak var image: UIButton!
//    @IBOutlet weak var label: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupAccessButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        doubleShineButtCntainer.startAnimation()
        animationView.play()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        doubleShineButtCntainer.stopAnimation()
        animationView.stop()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let maxContainerWidth: CGFloat = 414
        containerView.width = min(maxContainerWidth, view.bounds.width, view.bounds.height)
        containerView.center = view.bounds.mid
    }
    
    func setupAccessButton() {
        doubleShineButtCntainer.backgroundColor = UIColor(rgb: 0x007AFF)
        doubleShineButtCntainer.corner = 10
    }
    
    // MARK: - photo access
    @IBAction func openAccessPressed() {
        PHPhotoLibrary.requestAccess { granted in
            if granted {
                self.goToGallery()
            } else {
                let alert = UIAlertController(title: "No photo access", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Open Settings", style: .cancel, handler: { _ in
                    
                    UIApplication.openSettings(onReturnToApplication: {
                        if PHPhotoLibrary.accessAllowed {
                            self.goToGallery()
                        }
                    })
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func goToGallery() {
        let gallery = GalleryViewController()
        navigationController?.pushViewController(gallery, animated: true)
    }
}
