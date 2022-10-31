//
//  UIApplication+Ex.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 29/10/2022.
//

import UIKit

extension UIApplication {
    var tm_keyWindow: UIWindow {
        return delegate!.window!!
    }
}
