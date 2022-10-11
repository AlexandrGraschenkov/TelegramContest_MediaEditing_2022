//
//  UIColor+Ex.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 11.10.2022.
//

import UIKit

extension UIColor {
    
    convenience init(red: Int, green: Int, blue: Int, a: CGFloat = 1.0) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: a
        )
    }

    convenience init(rgb: Int, a: CGFloat = 1.0) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF,
            a: a
        )
    }
    
    static func color(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) -> UIColor {
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    func hexString(_ includeAlpha: Bool = true) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        if (includeAlpha) {
            return String(format: "#%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
        } else {
            return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        }
    }
    
    func offsetColor(hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, resultAlpha alpha: CGFloat? = nil) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0
        var b: CGFloat = 0, a: CGFloat = 0
        
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a)
            else {return self}
        
        h = min(1, max(h + hue, 0.0))
        s = min(1, max(s + saturation, 0.0))
        b = min(1, max(b + brightness, 0.0))
        return UIColor(hue: h,
                       saturation: s,
                       brightness: b,
                       alpha: alpha ?? a)
    }
}


extension UIColor {
    static func color(white: UIColor, dark: UIColor) -> UIColor {
        if #available(iOS 13, *) {
            return UIColor { (UITraitCollection: UITraitCollection) -> UIColor in
                if UITraitCollection.userInterfaceStyle == .dark {
                    /// Return the color for Dark Mode
                    return dark
                } else {
                    /// Return the color for Light Mode
                    return white
                }
            }
        } else {
            /// Return a fallback color for iOS 12 and lower.
            return white
        }
    }
}
