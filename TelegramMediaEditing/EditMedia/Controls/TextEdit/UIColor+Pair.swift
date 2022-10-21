//
//  UIColor+Pair.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 21/10/2022.
//

import Foundation
import UIKit

extension UIColor {
    var bestBackgroundColor: UIColor {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        let lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
        let isDarkColor = lum < 0.50
        let ratio: CGFloat = 0.1
        if isDarkColor {
            // find light color
            return UIColor(red: 1 - r * ratio, green: 1 - g * ratio, blue: 1 - g * ratio, alpha: 1)
        } else {
            // find dark color
            return UIColor(red: r * ratio, green: g * ratio, blue: g * ratio, alpha: 1)
        }
    }
}
