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

enum TextPanelPropertyChange {
    struct Change<T> {
        let oldValue: T?
        let newValue: T
    }
    case font(Change<UIFont>)
    case alignment(Change<NSTextAlignment>)
    case style(Change<TextStyle>)
}

final class TextPanel: UIView {
    let styleButton = TextStyleButton(frame: CGRect(origin: .zero, size: .square(side: 44)))
    let alignmentButton = TextAlignmentButton(frame: CGRect(origin: .zero, size: .square(side: 44)))
    
    var onAttributeChange: ((TextPanelPropertyChange) -> Void)?

    var selectedFont: UIFont {
        get { fontsView.selectedFont! }
        set { fontsView.selectedFont = newValue }
    }
    
    var isGradientVisible: Bool {
        get { fontsView.isGradientVisible }
        set { fontsView.isGradientVisible = newValue }
    }
    
    private var fontsView:FontsSelector!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        
        for view in [styleButton, alignmentButton] {
            addSubview(view)
        }
        
        styleButton.autoresizingMask = [.flexibleRightMargin]
        styleButton.addAction { [weak self] in
            guard let self = self else { return }
            let oldValue = self.styleButton.textStyle
            let styles: [TextStyle] = [.regular, .outlined, .framed]
            let index = styles.firstIndex(of: self.styleButton.textStyle)!
            let nextIndex = (index + 1) % styles.count
            self.styleButton.setStyle(styles[nextIndex], animated: true)
            self.onAttributeChange?(.style(.init(oldValue: oldValue, newValue: styles[nextIndex])))
        }
        styleButton.setStyle(.regular, animated: true)
        
        alignmentButton.x = styleButton.frame.maxX
        alignmentButton.autoresizingMask = [.flexibleRightMargin]
        alignmentButton.addAction { [weak self] in
            guard let self = self else { return }
            var textAlginment: NSTextAlignment = .center
            switch self.alignmentButton.textAlignment {
            case .left:
                textAlginment = .center
            case .right:
                textAlginment = .left
            case .center:
                textAlginment = .right
            default:
                break
            }
            let oldValue = self.alignmentButton.textAlignment
            self.alignmentButton.textAlignment = textAlginment
            self.onAttributeChange?(.alignment(.init(oldValue: oldValue, newValue: textAlginment)))
        }
        
        fontsView = FontsSelector(frame: CGRect(x: alignmentButton.frame.maxX, y: (bounds.height - 33) / 2, width: bounds.width - alignmentButton.frame.maxX, height: 33))
        addSubview(fontsView)
        fontsView.onFontSelect = { [weak self] oldFont, font in
            self?.onAttributeChange?(.font(.init(oldValue: oldFont, newValue: font)))
        }
        
        fontsView.autoresizingMask = [.flexibleWidth]
    }
}

enum TextStyle: Equatable {
    case regular
    case outlined
    case framed
}

final class TextStyleButton: UIButton {
    private(set) var textStyle: TextStyle = .regular
    func setStyle(_ textStyle: TextStyle, animated: Bool) {
        let imageName: String
        switch textStyle {
        case .regular:
            imageName = "regular_text_style"
        case .framed:
            imageName = "framed_text_style"
        case .outlined:
            imageName = "outlined_text_style"
        }
        let change = {
            self.setImage(.init(named: imageName), for: .normal)
        }
        self.textStyle = textStyle
        if animated {
            UIView.animate(withDuration: 0.2, animations: change)
        } else {
            change()
        }
    }
}
