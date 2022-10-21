//
//  TextEditPanel.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 18/10/2022.
//

import UIKit

protocol TextPanelDelegate: AnyObject {
    func textPanel(_ textPanel: TextPanel, didChangeAlignment: NSTextAlignment)
    func textPanel(_ textPanel: TextPanel, didChangeTextStyle: TextStyle)
    func textPanel(_ textPanel: TextPanel, didChangeFont: UIFont)
}

final class TextPanel: UIView {
    let styleButton = TextStyleButton(frame: CGRect(origin: .zero, size: .square(side: 44)))
    let alignmentButton = TextAlignmentButton(frame: CGRect(origin: .zero, size: .square(side: 44)))
    
    var selectedFont: UIFont {
        get {
            .systemFont(ofSize: 32)
        }
        set {
            
        }
    }
    
    private let fontsView = UIScrollView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        for view in [styleButton, alignmentButton, fontsView] {
            addSubview(view)
        }
        styleButton.autoresizingMask = [.flexibleRightMargin]
        alignmentButton.x = styleButton.frame.maxX
        alignmentButton.autoresizingMask = [.flexibleRightMargin]
        fontsView.x = styleButton.frame.maxX
        fontsView.frame.size = CGSize(width: bounds.width - fontsView.x, height: 33)
        fontsView.y = (bounds.height - fontsView.height) / 2
        fontsView.autoresizingMask = [.flexibleWidth]
        
        let leftGradient = GradientView(frame: CGRect(x: fontsView.x, y: fontsView.y, width: 16, height: fontsView.height))
        leftGradient.startPoint = .init(x: 0, y: 0.5)
        leftGradient.endPoint = .init(x: 1, y: 0.5)
        leftGradient.colors = [.black, .clear]
        leftGradient.autoresizingMask = [.flexibleRightMargin]
        
        
        let rightGradient = GradientView(frame: CGRect(x: fontsView.frame.maxX - 16, y: fontsView.y, width: 16, height: fontsView.height))
        leftGradient.startPoint = .init(x: 0, y: 0.5)
        leftGradient.endPoint = .init(x: 1, y: 0.5)
        leftGradient.colors = [.clear, .black]
        leftGradient.autoresizingMask = [.flexibleLeftMargin]
        
        addSubview(leftGradient)
        addSubview(rightGradient)
    }
}

final class TextAlignmentButton: UIButton {
    var textAlignment: NSTextAlignment = .center
}

enum TextStyle {
    case regular
    case outlined
    case framed
}

final class TextStyleButton: UIButton {
    var textStyle: TextStyle = .regular
}
