//
//  UIImage+Ex.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 12.10.2022.
//

import UIKit

extension UIImage {
    var pixelSize: CGSize {
        return CGSize(width: size.width * scale, height: size.height * scale)
    }
}
