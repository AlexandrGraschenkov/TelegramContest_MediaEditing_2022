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
            return colorComponents.toColorOverride()
        }
        set {
            var comp = newValue.components
            comp.a = 1
            colorComponents = comp
            updateColorOutside()
            updateColorLabels()
        }
    }
    
    var onColorSelect: ((UIColor) -> ())?
    fileprivate(set) var colorComponents: ColorComponents = ColorComponents(r: 0, g: 0, b: 0, a: 1)
    
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
        case rSlider: update(CGFloat(slider.value), &colorComponents.r)
        case gSlider: update(CGFloat(slider.value), &colorComponents.g)
        case bSlider: update(CGFloat(slider.value), &colorComponents.b)
        default: break
        }
        if hasChanges {
            updateSliderGradients()
            updateColorLabels()
            onColorSelect?(colorComponents.toColorOverride(a: 1))
        }
    }
    
    fileprivate func updateColorOutside() {
        rSlider.value = Float(colorComponents.r)
        gSlider.value = Float(colorComponents.g)
        bSlider.value = Float(colorComponents.b)
        updateSliderGradients()
    }
    
    fileprivate func updateSliderGradients() {
        let color = colorComponents.toColorOverride(a: 1)
        let thumbStroke: ColorSlider.ThumbStroke = colorComponents.isLightColor ? .black : .white
        rSlider.thumbColor = color
        rSlider.gradientColors = .init(from: colorComponents.toColorOverride(r: 0, a: 1),
                                       to: colorComponents.toColorOverride(r: 1, a: 1))
        rSlider.thumbStroke = thumbStroke
        
        gSlider.thumbColor = color
        gSlider.gradientColors = .init(from: colorComponents.toColorOverride(g: 0, a: 1),
                                       to: colorComponents.toColorOverride(g: 1, a: 1))
        gSlider.thumbStroke = thumbStroke
        
        bSlider.thumbColor = color
        bSlider.gradientColors = .init(from: colorComponents.toColorOverride(b: 0, a: 1),
                                       to: colorComponents.toColorOverride(b: 1, a: 1))
        bSlider.thumbStroke = thumbStroke
    }
    
    fileprivate func updateColorLabels() {
        hexLabel.text = colorComponents.hex
        rLabel.text = Int(round(colorComponents.r * 255)).description
        gLabel.text = Int(round(colorComponents.g * 255)).description
        bLabel.text = Int(round(colorComponents.b * 255)).description
    }
}
