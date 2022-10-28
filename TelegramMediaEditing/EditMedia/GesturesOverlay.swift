//
//  GesturesController.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 27/10/2022.
//

import Foundation
import UIKit

final class GesturesOverlay: UIView {
    
    private weak var overlaysContainer: UIView?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var overlays: [UIView] = []
    
    var onTap: ((UIView) -> Void)?
    
    private var activeOverlay: UIView?

    private var rotateGRIsActive: Bool = false {
        didSet {
            updateUserFingersState()
        }
    }
    
    private var panGRIsActive: Bool = false {
        didSet {
            updateUserFingersState()
        }
    }
    private var pinchGRIsActive: Bool = false {
        didSet {
            updateUserFingersState()
        }
    }
    
    private var userFingersOnScreen: Bool = false {
        didSet {
            guard userFingersOnScreen != oldValue else { return }
            if !userFingersOnScreen {
                activeOverlay = nil
            }
            UIView.animate(withDuration: 0.1) {
                if self.userFingersOnScreen {
//                    self.delegate?.overlayBeginMovementEvents(self)
                }
                else {
//                    self.delegate?.overlayEndMovementEvents(self)
                }
            }
        }
    }
    
    private func updateUserFingersState() {
        userFingersOnScreen = panGRIsActive || pinchGRIsActive || rotateGRIsActive
    }
    
    private lazy var tapGR: UITapGestureRecognizer = {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerDidFire))
        tap.delegate = self
        return tap
    }()
    
    private var panGR: UIPanGestureRecognizer!
    private var pinchGR: UIPinchGestureRecognizer!
    private var rotateGR: UIRotationGestureRecognizer!

    init(overlaysContainer: UIView, frame: CGRect) {
        self.overlaysContainer = overlaysContainer
        super.init(frame: frame)
        panGR = UIPanGestureRecognizer()
        panGR.addTarget(self, action: #selector(panGestureRecognizerDidFire))
        
        pinchGR = UIPinchGestureRecognizer()
        pinchGR.addTarget(self, action: #selector(pinchGestureRecognizerDidFire))
        
        rotateGR = UIRotationGestureRecognizer()
        rotateGR.addTarget(self, action: #selector(rotateGestureRecognizerDidFire))
        
        tapGR = UITapGestureRecognizer(target: self, action: #selector(tapGestureRecognizerDidFire))
        
        for gesture in [panGR, pinchGR, rotateGR, tapGR] {
            gesture?.delegate = self
            self.addGestureRecognizer(gesture!)
        }
    }
    
    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard activeOverlay == nil || !userFingersOnScreen else { return true }
        
        var hitViews: [(UIView, Bool)] = []
        for view in overlays.reversed() {
            if view.superview == nil { continue }
            let convertPoint = convert(point, to: view)
            if view.bounds.insetBy(dx: -10, dy: -10).contains(convertPoint) {
                hitViews.append((view, true))
            }
        }
        if hitViews.count == 0 {
            activeOverlay = nil
            return false
        } else {
            let opaque = hitViews.filter { $0.1 }.first
            let active = hitViews.filter { $0.0 == activeOverlay }.first
            if let (view, _) = opaque {
                activeOverlay = view
                return true
            } else if let _ = active {
                return true
            } else {
                activeOverlay = nil
                return false
            }
        }
    }
    
    @objc
    private func tapGestureRecognizerDidFire(_ sender: UITapGestureRecognizer) {
        guard let overlay = activeOverlay else { return }
        onTap?(overlay)
        activeOverlay = nil
    }

    private var initialOffset: CGSize? {
        didSet {
            panGRIsActive = initialOffset != nil
        }
    }
    private var initialPoint: CGPoint?
    
    @objc
    private func panGestureRecognizerDidFire(_ sender: UIPanGestureRecognizer) {
        guard let overlaysContainer = overlaysContainer else {
            return
        }

        let point = sender.location(in: self)
        if sender.state == .began, let overlay = activeOverlay {
            let center = overlaysContainer.convert(overlay.center, to: self)
            initialOffset = CGSize(width: center.x - point.x, height: center.y - point.y)
            initialPoint = center
        }
        else if sender.state == .changed, let overlay = activeOverlay, let initialCenter = initialPoint {
            let translation = sender.translation(in: self)
            var desiredCenter = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
            desiredCenter = convert(desiredCenter, to: overlaysContainer)
            desiredCenter.y = max(overlay.height / 2, min(desiredCenter.y, self.bounds.size.height - overlay.height / 2))
            overlay.center = desiredCenter
            if let textView = overlay as? TextEditingResultView {
                textView.movedCenterInCanvas = desiredCenter
            }
        } else {
            initialOffset = nil
        }
    }
    
    @objc
    private func pinchGestureRecognizerDidFire(_ sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .began:
            pinchGRIsActive = activeOverlay != nil
        case .ended, .failed:
            pinchGRIsActive = false
        default:
            break
        }
        guard let overlay = activeOverlay else { return }
        overlay.transform = overlay.transform.scaledBy(x: sender.scale, y: sender.scale)
        sender.scale = 1
    }
    
    @objc
    private func rotateGestureRecognizerDidFire(_ sender: UIRotationGestureRecognizer) {
        switch sender.state {
        case .began:
            rotateGRIsActive = activeOverlay != nil
        case .ended, .failed:
            rotateGRIsActive = false
        default:
            break
        }
        guard let overlay = activeOverlay else { return }
        overlay.transform = overlay.transform.rotated(by: sender.rotation)
        sender.rotation = 0
    }
}

extension GesturesOverlay: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
