//
//  UIControl+Ex.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 14/10/2022.
//

import UIKit

typealias VoidBlock = () -> Void

extension UIControl {
    func addAction(
        for controlEvents: UIControl.Event = .touchUpInside,
        _ closure: @escaping VoidBlock
    ) {
        @objc
        final class ClosureContainer: NSObject {
            let closure: VoidBlock
            init(_ closure: @escaping VoidBlock) { self.closure = closure }
            @objc func invoke() { closure() }
        }

        let sleeve = ClosureContainer(closure)
        addTarget(sleeve, action: #selector(ClosureContainer.invoke), for: controlEvents)
        objc_setAssociatedObject(self, "\(UUID())", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

extension UIGestureRecognizer {
    convenience init(addingTo view: UIView, action: @escaping (UIGestureRecognizer) -> Void) {
        @objc
        final class ClosureContainer: NSObject {
            let closure: (UIGestureRecognizer) -> Void
            
            init(_ closure: @escaping (UIGestureRecognizer) -> Void) { self.closure = closure }
            
            @objc
            func invoke(_ gestureRecoginser: UIGestureRecognizer) {
                closure(gestureRecoginser)
            }
        }
        
        let sleeve = ClosureContainer(action)
        self.init(target: sleeve, action: #selector(ClosureContainer.invoke))
        view.addGestureRecognizer(self)
        objc_setAssociatedObject(self, "\(UUID())", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}
