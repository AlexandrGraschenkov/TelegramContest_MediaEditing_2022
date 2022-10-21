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
    
    var onAnyAttributeChange: VoidBlock?

    var selectedFont: UIFont {
        fontsView.selectedFont!
    }
    
    var isGradientVisible: Bool = true {
        didSet {
            leftGradient.isHidden = !isGradientVisible
            rightGradient.isHidden = !isGradientVisible
        }
    }
    
    private var fontsView:FontsSelector!
    private var leftGradient: UIView!
    private var rightGradient: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        let onChange = { [weak self] in self?.onAnyAttributeChange?() }
        
        for view in [styleButton, alignmentButton] {
            addSubview(view)
        }
        
        styleButton.autoresizingMask = [.flexibleRightMargin]
        styleButton.addAction {
            
        }
        
        alignmentButton.x = styleButton.frame.maxX
        alignmentButton.autoresizingMask = [.flexibleRightMargin]
        alignmentButton.addAction { [weak self] in
            guard let self = self else { return }
            switch self.alignmentButton.textAlignment {
            case .left:
                self.alignmentButton.textAlignment = .center
            case .right:
                self.alignmentButton.textAlignment = .left
            case .center:
                self.alignmentButton.textAlignment = .right
            default:
                break
            }
            onChange()
        }
        
        fontsView = FontsSelector(frame: CGRect(x: alignmentButton.frame.maxX, y: (bounds.height - 33) / 2, width: bounds.width - alignmentButton.frame.maxX, height: 33))
        addSubview(fontsView)
        fontsView.onFontSelect = { _ in onChange() }
        
        fontsView.autoresizingMask = [.flexibleWidth]
        let leftGradient = GradientView(frame: CGRect(x: fontsView.x, y: fontsView.y, width: 16, height: fontsView.height))
        leftGradient.startPoint = .init(x: 0, y: 0.5)
        leftGradient.endPoint = .init(x: 1, y: 0.5)
        leftGradient.colors = [.black, .clear]
        leftGradient.autoresizingMask = [.flexibleRightMargin]
        self.leftGradient = leftGradient
        
        
        let rightGradient = GradientView(frame: CGRect(x: fontsView.frame.maxX - 16, y: fontsView.y, width: 16, height: fontsView.height))
        leftGradient.startPoint = .init(x: 0, y: 0.5)
        leftGradient.endPoint = .init(x: 1, y: 0.5)
        leftGradient.colors = [.clear, .black]
        leftGradient.autoresizingMask = [.flexibleLeftMargin]
        self.rightGradient = rightGradient
        
        addSubview(leftGradient)
        addSubview(rightGradient)
    }
}

enum TextStyle {
    case regular
    case outlined
    case framed
}

final class TextStyleButton: UIButton {
    var textStyle: TextStyle = .regular {
        didSet {
            switch textStyle {
            case .framed:
                
            }
        }
    }
}
