//
//  ValueLabel.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 23.10.2022.
//

import UIKit

class ValueLabel: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        textColor = UIColor.white
        backgroundColor = UIColor(white: 0, alpha: 0.5)
        layer.cornerRadius = 8
        layer.masksToBounds = true
        textAlignment = .center
        font = UIFont.systemFont(ofSize: 17, weight: .medium)
    }
}
