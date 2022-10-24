//
//  ColorPickerVC.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 21.10.2022.
//

import UIKit

protocol ColorSelectorProtocol: UIView {
    var color: UIColor { get set }
    var onColorSelect: ((UIColor)->())? { get set }
}

final class ColorPickerVC: UIViewController {
    
    init() {
        super.init(nibName: "ColorPickerVC", bundle: nil)
        modalPresentationStyle = .overFullScreen
        
//        edgesForExtendedLayout = .top
//        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    @IBOutlet weak var mainContainer: UIView!
    @IBOutlet weak var colorPickerContainer: UIView!
    @IBOutlet weak var colorPickerType: UISegmentedControl!
    fileprivate var needAnimateOnAppear = true
    fileprivate var colorPickerElem: ColorSelectorProtocol!
    fileprivate lazy var gridPicker: ColorGridView = {
        let v = ColorGridView(frame: colorPickerContainer.bounds)
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return v
    }()
    fileprivate lazy var spectrumPicker: ColorSpectrumView = {
        let v = ColorSpectrumView(frame: colorPickerContainer.bounds)
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return v
    }()
    fileprivate lazy var sliderPicker: ColorSlidersView = {
        let v: ColorSlidersView = ColorSlidersView.fromXib()
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return v
    }()
    fileprivate let defaultBgAlpha: CGFloat = 0.2
    fileprivate var firstPanOffset: CGPoint? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        } else {
            // Don't care
        }
        view.backgroundColor = UIColor(white: 0, alpha: 0)
        mainContainer.layer.cornerRadius = 10
        mainContainer.layer.masksToBounds = true
        mainContainer.height += 20 + view.safeInsets.bottom
        mainContainer.y -= view.safeInsets.bottom
//        mainContainer.transform = .init(translationX: 0, y: mainContainer.height)
        
//        colorPickerContainer.layer.cornerRadius = 8
//        colorPickerContainer.layer.masksToBounds = true
        let pan = UIPanGestureRecognizer(target: self, action: #selector(dismissPan(pan: )))
        view.addGestureRecognizer(pan)
        updateColorPicker()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if needAnimateOnAppear {
            needAnimateOnAppear = false
            animateAppear()
        }
    }
    
    func animateAppear() {
        mainContainer.transform = .init(translationX: 0, y: mainContainer.height)
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
            self.view.backgroundColor = UIColor(white: 0, alpha: self.defaultBgAlpha)
            self.mainContainer.transform = .identity
        } completion: { _ in
        }
    }
    
    func animateDissapear() {
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]) {
            self.mainContainer.transform = .init(translationX: 0, y: self.mainContainer.height)
            self.view.backgroundColor = UIColor(white: 0, alpha: 0)
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }
    
    @objc func dismissPan(pan: UIPanGestureRecognizer) {
        let offset = pan.translation(in: view)
        switch pan.state {
        case .began, .changed:
            firstPanOffset = firstPanOffset ?? offset
            if abs(firstPanOffset!.y) < abs(firstPanOffset!.x) {
                pan.isEnabled = false
                delay(0.1) { pan.isEnabled = true }
                firstPanOffset = nil
                return
            }
            
            var y = offset.y
            if y < 0 {
                y = -3*log(1-y)
            }
            mainContainer.transform = CGAffineTransform(translationX: 0, y: y)
            let progress = 1 - y.percent(min: 0, max: mainContainer.height).clamp(0, 1)
            view.backgroundColor = UIColor(white: 0, alpha: defaultBgAlpha*progress)
        case .ended:
            let vel = pan.velocity(in: view)
            var needDismiss = vel.y > 0
            if abs(vel.y) < 100 {
                needDismiss = offset.y > mainContainer.height * 0.3
            }
            if needDismiss {
                animateDissapear()
            } else {
                UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
                    self.mainContainer.transform = .identity
                    self.view.backgroundColor = UIColor(white: 0, alpha: self.defaultBgAlpha)
                } completion: { _ in
                }
            }
        case .cancelled, .failed:
            mainContainer.transform = .identity
            view.backgroundColor = UIColor(white: 0, alpha: defaultBgAlpha)
            
        default: break
        }
    }
    
    @objc
    @IBAction func closePressed() {
        animateDissapear()
    }
    
    @IBAction func colorPickerSegmentChanged(_ segment: UISegmentedControl) {
        updateColorPicker()
    }
    
    private func updateColorPicker() {
        if let prevView = colorPickerElem {
            prevView.removeFromSuperview()
        }
        
        switch colorPickerType.selectedSegmentIndex {
        case 0:
            colorPickerElem = gridPicker
        case 1:
            colorPickerElem = spectrumPicker
        case 2:
            colorPickerElem = sliderPicker
        default:
            break
        }
        
        colorPickerElem.frame = colorPickerContainer.bounds
        colorPickerElem.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        colorPickerContainer.addSubview(colorPickerElem)
    }
}
