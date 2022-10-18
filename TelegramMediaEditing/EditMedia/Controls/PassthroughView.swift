//
//  PassthroughView.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 16/10/2022.
//

import UIKit

final class PassthroughView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
}
