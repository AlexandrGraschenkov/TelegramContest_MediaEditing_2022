//
//  ColourPickerCirlce.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 15/10/2022.
//

import UIKit

final class ColourPickerCirlce: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.clipsToBounds = true
        self.backgroundColor = .white
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 2
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = width / 2
    }
}

final class ColourPickerCirlceOpacity: UIImageView {
    
    var color: UIColor = .white {
        didSet { overlayView.backgroundColor = color }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        self.clipsToBounds = true
        self.backgroundColor = .clear
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = 2
        
        image = UIImage(named: "chessboard_bg")!
        contentMode = .scaleAspectFill
        
        overlayView = UIView(frame: bounds)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.backgroundColor = color
        addSubview(overlayView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = width / 2
    }
    
    private var overlayView: UIView!
}
