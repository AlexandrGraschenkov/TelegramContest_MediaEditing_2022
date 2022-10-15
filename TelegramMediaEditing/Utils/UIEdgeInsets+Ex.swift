//
//  UIEdgeInsets+Ex.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 14/10/2022.
//

import UIKit

extension UIEdgeInsets {
    static func tm_insets(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) -> Self {
        return .init(top: top, left: left, bottom: bottom, right: right)
    }
    
    static func all(_ side: CGFloat) -> Self {
        .init(top: side, left: side, bottom: side, right: side)
    }
}

extension CGSize {
    static func square(side: CGFloat) -> Self {
        return .init(width: side, height: side)
    }
}
