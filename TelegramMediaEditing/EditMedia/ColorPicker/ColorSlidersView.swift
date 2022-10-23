//
//  ColorSlidersView.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 22.10.2022.
//

import UIKit

final class ColorSlidersView: UIView, ColorSelectorProtocol {
    var color: UIColor {
        get {
            return colorInfo.toColorOverride()
        }
        set {
            var info = newValue.colorInfo
            info.a = 1
            colorInfo = info
            updateColorOutside()
            updateColorLabels()
        }
    }
    
    var onColorSelect: ((UIColor) -> ())?
    fileprivate(set) var colorInfo: ColorInfo = ColorInfo(r: 0, g: 0, b: 0, a: 1)
    
    static func fromXib() -> ColorSlidersView {
        return loadFromXib()
    }
    
    @IBOutlet weak var rSlider: ColorSlider!
    @IBOutlet weak var gSlider: ColorSlider!
    @IBOutlet weak var bSlider: ColorSlider!
    @IBOutlet weak var rLabel: UILabel!
    @IBOutlet weak var gLabel: UILabel!
    @IBOutlet weak var bLabel: UILabel!
    @IBOutlet weak var hexLabel: UILabel!
    
    @IBAction func onSliderChange(_ slider: ColorSlider) {
        var hasChanges = false
        // sometimes slider trigger event without changes
        let update = { (a: CGFloat, b: inout CGFloat) in
            if a != b {
                b = a; hasChanges = true
            }
        }
        switch slider {
        case rSlider: update(CGFloat(slider.value), &colorInfo.r)
        case gSlider: update(CGFloat(slider.value), &colorInfo.g)
        case bSlider: update(CGFloat(slider.value), &colorInfo.b)
        default: break
        }
        if hasChanges {
            updateSliderGradients()
            updateColorLabels()
        }
    }
    
    fileprivate func updateColorOutside() {
        rSlider.value = Float(colorInfo.r)
        gSlider.value = Float(colorInfo.g)
        bSlider.value = Float(colorInfo.b)
        updateSliderGradients()
    }
    
    fileprivate func updateSliderGradients() {
        let color = colorInfo.toColorOverride(a: 1)
        rSlider.thumbColor = color
        rSlider.fromColor = colorInfo.toColorOverride(r: 0, a: 1)
        rSlider.toColor = colorInfo.toColorOverride(r: 1, a: 1)
        
        gSlider.thumbColor = color
        gSlider.fromColor = colorInfo.toColorOverride(g: 0, a: 1)
        gSlider.toColor = colorInfo.toColorOverride(g: 1, a: 1)
        
        bSlider.thumbColor = color
        bSlider.fromColor = colorInfo.toColorOverride(b: 0, a: 1)
        bSlider.toColor = colorInfo.toColorOverride(b: 1, a: 1)
    }
    
    fileprivate func updateColorLabels() {
        hexLabel.text = colorInfo.hex
        rLabel.text = Int(round(colorInfo.r * 255)).description
        gLabel.text = Int(round(colorInfo.g * 255)).description
        bLabel.text = Int(round(colorInfo.b * 255)).description
    }
}
