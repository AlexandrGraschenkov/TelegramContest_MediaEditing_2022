//
//  UITextView+Glyph.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 22/10/2022.
//

import UIKit

final class OutlineableTextView: UITextView {
    private var outlinedChars: [CAShapeLayer] = []
    
    var outlineColor: UIColor = .black {
        didSet {
            for layer in outlinedChars {
                layer.strokeColor = outlineColor.cgColor
                layer.shadowColor = outlineColor.cgColor
            }
        }
    }
    
    func removeOutline() {
        for layer in outlinedChars {
            layer.removeFromSuperlayer()
        }
        outlinedChars = []
    }
    
    func outline() {
        // TODO: reuse existing layers & maybe use one layer with composite bezier path
        removeOutline()
        let layout = self.layoutManager
        for i in 0..<layout.numberOfGlyphs {
            let glyph = layout.glyph(at: i)
            guard let glyphPath = CTFontCreatePathForGlyph(self.font!, glyph, nil), let container = layout.textContainer(forGlyphAt: i, effectiveRange: nil) else { continue }
            
            let glyphRect = layout.boundingRect(forGlyphRange: NSRange(location: i, length: 1), in: container)

            var inverse = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -glyphRect.size.height)
            let letterPath = glyphPath.copy(using: &inverse)!
            let layer = CAShapeLayer()
            self.layer.insertSublayer(layer, at: 0)
            layer.path = letterPath
            layer.strokeColor = outlineColor.cgColor
            layer.lineWidth = (font?.pointSize ?? 32) / 8
            layer.shadowRadius = layer.lineWidth / 2
            layer.shadowColor = outlineColor.cgColor
            layer.shadowOffset = .zero
            layer.shadowOpacity = 1

            let shift = font!.glyphShift // TODO: figure out why it's shifted and come up with universal solution for all fonts
            layer.frame = CGRect(x: glyphRect.minX + textContainerInset.left, y: glyphRect.minY + textContainerInset.top - shift, width: glyphRect.width, height: glyphRect.height)
            outlinedChars.append(layer)
        }
    }
}


private extension UIFont {
    var glyphShift: CGFloat {
        switch familyName {
        case "Helvetica", "Menlo":
            return pointSize * 0.219
        case "Snell Roundhand":
            return pointSize * 0.32
        case "Noteworthy":
            return pointSize * 0.219
        case "Courier New":
            return pointSize * 0.3
        default:
            return pointSize * 0.219
        }
    }
}
