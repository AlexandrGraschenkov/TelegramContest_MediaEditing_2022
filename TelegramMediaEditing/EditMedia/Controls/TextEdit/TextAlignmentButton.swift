//
//  TextAlignmentButton.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 21/10/2022.
//

import UIKit

final class TextAlignmentButton: UIButton {
    var textAlignment: NSTextAlignment = .center {
        didSet {
            updateLines(animated: true)
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            for line in lines {
                line.alpha = isHighlighted ? 0.7 : 1
            }
        }
    }
    
    private let maxLen: CGFloat = 20
    private let minLen: CGFloat = 12
    private let lineHeight: CGFloat = 2
    private let lineSpace: CGFloat = 3
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private var lines: [UIView] = []
    
    private func createLine(length: CGFloat) -> UIView {
        let view = UIView(frame: .init(origin: .zero, size: CGSize(width: length, height: lineHeight)))
        view.backgroundColor = .white
        view.layer.cornerRadius = lineHeight / 2
        return view
    }
    
    private func setup() {
        let linesCount: CGFloat = 4
        let totalHeight = (linesCount * lineHeight) + (linesCount - 1) * lineSpace
        let startY = (bounds.height - totalHeight) / 2
        
        var y = startY
        for i in 0..<Int(linesCount) {
            let len = (i % 2 == 0) ? maxLen : minLen
            let line = createLine(length: len)
            addSubview(line)
            line.y = y
            line.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
            y += lineHeight + lineSpace
            lines.append(line)
        }
        updateLines(animated: false)
    }
    
    private func updateLines(animated: Bool) {
        let change = {
            for line in self.lines {
                switch self.textAlignment {
                case .left:
                    line.x = (self.bounds.width - self.maxLen) / 2
                case .center:
                    line.x = (self.bounds.width - line.width) / 2
                case .right, .justified, .natural:
                    line.x = (self.bounds.width - self.maxLen) / 2 - (line.width - self.maxLen)
                @unknown default:
                    break
                }
            }
        }
        if !animated {
            change()
        } else {
            UIView.animate(
                withDuration: 0.2,
                delay: 0,
                usingSpringWithDamping: 0.5,
                initialSpringVelocity: 0,
                options: [],
                animations: change,
                completion: nil
            )
        }
    }
}
