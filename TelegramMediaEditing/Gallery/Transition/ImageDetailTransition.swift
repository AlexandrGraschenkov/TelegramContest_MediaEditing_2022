//
//  ImageDetailTransition.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 30/10/2022.
//

import UIKit

class ImageDetailTransitionController: NSObject {
    
    let animator: ImageDetailAnimator

    weak var fromDelegate: ImageDetailAnimatorDelegate?
    weak var toDelegate: ImageDetailAnimatorDelegate?
    
    override init() {
        animator = ImageDetailAnimator()
        super.init()
    }
}

extension ImageDetailTransitionController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.animator.isPresenting = true
        self.animator.fromDelegate = fromDelegate
        self.animator.toDelegate = toDelegate
        return self.animator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.animator.isPresenting = false
        let tmp = self.fromDelegate
        self.animator.fromDelegate = self.toDelegate
        self.animator.toDelegate = tmp
        return self.animator
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        nil
    }

}
