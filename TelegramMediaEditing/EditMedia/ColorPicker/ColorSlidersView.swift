//
//  ColorSlidersView.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 22.10.2022.
//

import UIKit

final class ColorSlidersView: UIView, ColorSelectorProtocol {
    var color: UIColor = UIColor.white
    
    var onColorSelect: ((UIColor) -> ())?
    
    static func fromXib() -> ColorSlidersView {
        return loadFromXib()
    }
    
    @IBOutlet weak var rSlider: ColorSlider!
    @IBOutlet weak var gSlider: ColorSlider!
    @IBOutlet weak var bSlider: ColorSlider!
    
    @IBAction func onSliderChange(_ slider: ColorSlider) {
        print(slider.value)
    }
}
