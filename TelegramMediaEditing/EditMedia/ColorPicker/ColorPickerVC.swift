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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        } else {
            // Don't care
        }
        view.backgroundColor = UIColor(white: 0, alpha: 0)
        mainContainer.layer.cornerRadius = 20
        mainContainer.layer.masksToBounds = true
//        mainContainer.transform = .init(translationX: 0, y: mainContainer.height)
        
        colorPickerContainer.layer.cornerRadius = 8
        colorPickerContainer.layer.masksToBounds = true
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
            self.view.backgroundColor = UIColor(white: 0, alpha: 0.2)
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
    
    @objc
    @IBAction func closePressed() {
        animateDissapear()
    }
    
    @IBAction func colorPickerSegmentChanged(_ segment: UISegmentedControl) {
        updateColorPicker()
    }
    
    func updateColorPicker() {
        if let prevView = colorPickerElem {
            prevView.removeFromSuperview()
        }
        
        switch colorPickerType.selectedSegmentIndex {
        case 0:
            colorPickerElem = ColorGridView(frame: colorPickerContainer.bounds)
            colorPickerElem.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            colorPickerContainer.addSubview(colorPickerElem)
        case 1:
            colorPickerElem = ColorSpectrumView(frame: colorPickerContainer.bounds)
            colorPickerElem.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            colorPickerContainer.addSubview(colorPickerElem)
        default:
            break
        }
    }
}

extension ColorPickerVC: UIViewControllerTransitioningDelegate {
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return HalfSizePresentationController(presentedViewController: presented, presenting: presentingViewController)
    }
//    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
//        return HalfSizePresentationController(presentedViewController: presented, presenting: presentingViewController)
//    }
}

class HalfSizePresentationController: UIPresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let bounds = containerView?.bounds else { return .zero }
        return CGRect(x: 0, y: bounds.height / 2, width: bounds.width, height: bounds.height / 2)
    }
}

