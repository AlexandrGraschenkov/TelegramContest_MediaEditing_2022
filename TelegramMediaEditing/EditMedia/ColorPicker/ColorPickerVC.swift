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
    
    var color: UIColor = .white
    var onDismiss: ((UIColor)->())?
    var onPickColorFromContent: (()->())?
    
    @IBOutlet weak var mainContainer: UIView!
    @IBOutlet weak var colorPickerContainer: UIView!
    @IBOutlet weak var colorPickerType: UISegmentedControl!
    @IBOutlet weak var opacitySlider: ColorSlider!
    @IBOutlet weak var opacityLabel: ValueLabel!
    @IBOutlet weak var finalColorView: UIView!
    @IBOutlet weak var favoriteView: FavoriteColorsView!
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
    fileprivate let defaultBgAlpha: CGFloat = 0.4
    fileprivate var firstDismissPanOffset: CGPoint? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        } else {
            // Don't care
        }
        
        mainContainer.layer.cornerRadius = 10
        mainContainer.layer.masksToBounds = true
        
        setupFinal() // set chassboard under final color
        
        opacitySlider.value = Float(color.components.a)
        opacitySlider.setupWithOpacity()
        opacitySlider.thumbColor = UIColor.clear
        colorUpdated()
        opacityLabelUpdate()
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(dismissPan(pan: )))
        view.addGestureRecognizer(pan)
        updateColorPicker()
        
        mainContainer.isHidden = true
        view.backgroundColor = UIColor(white: 0, alpha: 0)
        
        favoriteView.onAddColor = {[weak self] ()->(UIColor) in
            return self?.color ?? UIColor.gray
        }
        
        favoriteView.onSelectColor = {[weak self] (newColor: UIColor)->() in
            self?.color = newColor
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut]) {
                self?.colorPickerElem.color = newColor
                self?.colorUpdated()
                self?.opacitySlider.setValue(Float(newColor.components.a), animated: true)
                self?.opacityLabelUpdate()
            }
        }
    }
    
    func setupFinal() {
        finalColorView.layer.cornerRadius = 10
        finalColorView.layer.masksToBounds = true
        
        // setup BG
        let finalBg = UIImageView(frame: finalColorView.frame)
        finalBg.autoresizingMask = finalColorView.autoresizingMask
        finalBg.image = UIImage(named: "chessboard_bg")?.resizableImage(withCapInsets: UIEdgeInsets(), resizingMode: .tile)
//        finalBg.layer.borderColor = UIColor(white: 0.6, alpha: 1).cgColor
//        finalBg.layer.borderWidth = 1
        finalBg.layer.cornerRadius = finalColorView.layer.cornerRadius
        finalBg.layer.masksToBounds = true
        finalBg.alpha = 0.5
        
        finalColorView.superview?.insertSubview(finalBg, belowSubview: finalColorView)
        finalBg.pinEdges(to: finalColorView)
        
        // setup border overlay for dark colors
        let shape = CAShapeLayer()
        shape.path = CGPath(roundedRect: finalColorView.bounds.insetBy(dx: 1, dy: 1), cornerWidth: 10, cornerHeight: 10, transform: nil)
        shape.borderWidth = 1
        shape.strokeColor = UIColor(white: 1, alpha: 0.1).cgColor
        shape.fillColor = nil
        shape.compositingFilter = "lightenBlendMode"
        finalColorView.layer.addSublayer(shape)
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
        mainContainer.isHidden = false
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut, .allowUserInteraction]) {
            self.view.backgroundColor = UIColor(white: 0, alpha: self.defaultBgAlpha)
            self.mainContainer.transform = .identity
        } completion: { _ in
        }
    }
    
    func animateDissapear(notifyDismiss: Bool = true) {
        if notifyDismiss {
            onDismiss?(color)
        }
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
            firstDismissPanOffset = firstDismissPanOffset ?? offset
            if abs(firstDismissPanOffset!.y) < abs(firstDismissPanOffset!.x) {
                pan.isEnabled = false
                delay(0.1) { pan.isEnabled = true }
                firstDismissPanOffset = nil
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
            firstDismissPanOffset = nil
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
            firstDismissPanOffset = nil
            mainContainer.transform = .identity
            view.backgroundColor = UIColor(white: 0, alpha: defaultBgAlpha)
            
        default: break
        }
    }
    
    
    @IBAction func closePressed() {
        animateDissapear()
    }
    @IBAction func colorPickPressed() {
        onPickColorFromContent?()
        animateDissapear(notifyDismiss: false)
    }
    
    @IBAction func colorPickerSegmentChanged(_ segment: UISegmentedControl) {
        updateColorPicker()
    }
    @IBAction func opacityChanged(_ slider: ColorSlider) {
        color = color.components.toColorOverride(a: CGFloat(slider.value))
        colorUpdated()
        opacityLabelUpdate()
    }
    
    private func updateColorPicker() {
        if let prevView = colorPickerElem {
            prevView.onColorSelect = nil
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
        
        colorPickerElem.color = color
        colorPickerElem.frame = colorPickerContainer.bounds
        colorPickerElem.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        colorPickerContainer.addSubview(colorPickerElem)
        colorPickerElem.onColorSelect = { [weak self] color in
            guard let self = self else { return }
            self.color = color.components.toColorOverride(a: CGFloat(self.opacitySlider.value))
            self.colorUpdated()
        }
    }
    
    private func colorUpdated() {
        let comp = color.components
        opacitySlider.gradientColors = .init(from: comp.toColorOverride(a: 0),
                                             to: comp.toColorOverride(a: 1))
        opacitySlider.thumbStroke = comp.isLightColor ? .black : .white
        finalColorView.backgroundColor = color
        favoriteView.selectedColorChanged(color: color)
    }
    
    private func opacityLabelUpdate() {
        let percent = Int(round(opacitySlider.value * 100))
        opacityLabel.text = "\(percent)%"
    }
}
