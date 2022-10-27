//
//  EditNavBar.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 26.10.2022.
//

import UIKit

class EditNavBar: UIView {

    let buttHeight: CGFloat = 40
    let blurAdditionalHeight: CGFloat = 30
    fileprivate(set) var backward: UIButton!
    fileprivate(set) var forward: UIButton!
    fileprivate(set) var zoomOut: UIButton!
    fileprivate(set) var clearAll: UIButton!
    fileprivate(set) var doneButt: UIButton!
    fileprivate(set) var cancelButt: UIButton!
    fileprivate(set) var displayDoneCancel: Bool = false
    
    func setZoomOut(enabled: Bool, animated: Bool) {
        if zoomOut.isEnabled == enabled { return }
        
        zoomOut.isEnabled = enabled
        if animated && zoomOut.alpha > 0 {
            zoomOut.fadeAnimation(duration: 0.2)
        }
    }
    
    static func createAndAdd(toView view: UIView) -> EditNavBar {
        let bar = EditNavBar(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.addSubview(bar)
        bar.pinEdges(to: view, edges: [.top, .leading, .trailing])
        
        let topConstraint = bar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: bar.buttHeight + bar.blurAdditionalHeight)
        NSLayoutConstraint.activate([topConstraint])
        view.layoutIfNeeded()
        
        bar.setup()
        return bar
    }
    
    func pushDoneCancel(onDone: (()->())?, onCancel: (()->())?, animated: Bool = true) {
        actions.append(Actions(done: onDone, cancel: onCancel))
        updateDoneCancelDisplay(animated: animated)
    }
    
    func popDoneCancel(animated: Bool = true) {
        _ = actions.popLast()
        updateDoneCancelDisplay(animated: animated)
    }

    
    // MARK: - private
    private struct Actions {
        let done: (()->())?
        let cancel: (()->())?
    }
    private var actions: [Actions] = []
    private var blurMask: UIView?
    
    fileprivate func updateDoneCancelDisplay(animated: Bool) {
        let newVal = actions.count > 0
        if displayDoneCancel == newVal { return }
        
        displayDoneCancel = newVal
        let doneCancelButts = [doneButt, cancelButt]
        let defaultButts = [forward, backward, zoomOut, clearAll]
        let change = {
            for butt in defaultButts {
                butt?.alpha = newVal ? 0 : 1
            }
            for butt in doneCancelButts {
                butt?.alpha = newVal ? 1 : 0
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut], animations: change)
        } else {
            change()
        }
    }
    
    fileprivate func setup() {
        setupBlurBackground()
        
        backward = UIButton(frame: CGRect(x: 4, y: height-buttHeight-blurAdditionalHeight, width: 40, height: buttHeight))
        backward.setImage(UIImage(named: "history_backward"), for: .normal)
        backward.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        addSubview(backward)
        
        forward = UIButton(frame: CGRect(x: backward.right, y: backward.y, width: 40, height: buttHeight))
        forward.setImage(UIImage(named: "history_forward"), for: .normal)
        forward.setImage(UIImage(named: "empty"), for: .disabled)
        forward.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        addSubview(forward)
        
        zoomOut = UIButton()
        zoomOut.setImage(UIImage(named: "zoom_out"), for: .normal)
        zoomOut.setTitle("Zoom Out", for: .normal)
        zoomOut.setTitleColor(UIColor.white, for: .normal)
        zoomOut.setTitleColor(.gray, for: .highlighted)
        zoomOut.setTitle("", for: .disabled)
        zoomOut.setImage(UIImage(named: "empty"), for: .disabled)
        zoomOut.titleEdgeInsets.left = 10
        zoomOut.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        zoomOut.sizeToFit()
        zoomOut.width += 20
        zoomOut.center.x = bounds.midX
        zoomOut.height = buttHeight
        zoomOut.bottom = bounds.height-blurAdditionalHeight
        zoomOut.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin]
        addSubview(zoomOut)
        
        clearAll = UIButton()
        clearAll.setTitle("Clear All", for: .normal)
        clearAll.setTitleColor(.white, for: .normal)
        clearAll.setTitleColor(.gray, for: .highlighted)
        clearAll.setTitleColor(UIColor(white: 1, alpha: 0.5), for: .disabled)
        clearAll.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        clearAll.sizeToFit()
        clearAll.height = buttHeight
        clearAll.width += 10
        clearAll.bottom = bounds.height-blurAdditionalHeight
        clearAll.right = bounds.width - 4
        clearAll.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        addSubview(clearAll)
        
        
        // Cancel / Done state
        doneButt = UIButton()
        doneButt.setTitle("Done", for: .normal)
        doneButt.setTitleColor(.white, for: .normal)
        doneButt.setTitleColor(.gray, for: .highlighted)
        doneButt.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        doneButt.sizeToFit()
        doneButt.height = buttHeight
        doneButt.width += 10
        doneButt.bottom = bounds.height-blurAdditionalHeight
        doneButt.right = bounds.width
        doneButt.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        addSubview(doneButt)
        doneButt.alpha = 0
        
        cancelButt = UIButton()
        cancelButt.setTitle("Cancel", for: .normal)
        cancelButt.setTitleColor(.white, for: .normal)
        cancelButt.setTitleColor(.gray, for: .highlighted)
        cancelButt.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        cancelButt.sizeToFit()
        cancelButt.height = buttHeight
        cancelButt.width += 10
        cancelButt.bottom = bounds.height-blurAdditionalHeight
        cancelButt.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        addSubview(cancelButt)
        cancelButt.alpha = 0
    }
    
    fileprivate func setupBlurBackground() {
        let blur = UIVisualEffectView(frame: bounds)
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blur.effect = UIBlurEffect(style: .regular)
        for sub in blur.subviews {
            let className = NSStringFromClass(type(of: sub))
            if className == "_UIVisualEffectSubview" {
                sub.backgroundColor = UIColor(white: 0, alpha: 0.3)
            }
//            print(NSStringFromClass(type(of: sub)))
        }
        
        let mask = GradientView(frame: bounds)
        mask.startPoint = CGPoint(x: 0.5, y: 0)
        mask.endPoint = CGPoint(x: 0.5, y: 1)
        mask.colors = [UIColor.black, UIColor.black, UIColor(white: 0, alpha: 0)]
        mask.locations = [0, 0.3, 1]
        mask.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blur.mask = mask
        blurMask = mask
        
        insertSubview(blur, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        blurMask?.frame = bounds
    }
    
    // MARK: - actions
    
    @objc
    fileprivate func cancelPressed() {
        actions.last?.cancel?()
        popDoneCancel()
    }
    
    @objc
    fileprivate func donePressed() {
        actions.last?.cancel?()
        popDoneCancel()
    }
}
