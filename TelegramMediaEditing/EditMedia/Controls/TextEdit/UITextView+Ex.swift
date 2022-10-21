//
//  UITextView+Ex.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 21/10/2022.
//


import UIKit

private enum RectsCalculatorTurnType {
    case topLeft(CGPoint)
    case topRight(CGPoint)
    case bottomLeft(CGPoint)
    case bottomRight(CGPoint)
}

extension CGPoint {
    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        .init(x: x + dx, y: y + dy)
    }
}

private class RectsCalculator {
    
    private var rects: [CGRect] = []
    func add(rect: CGRect) {
        rects.append(rect)
    }
    
    private func addTurn(radius: CGFloat, path: UIBezierPath, isDown: Bool) -> (RectsCalculatorTurnType) -> CGPoint {
        return { (type: RectsCalculatorTurnType) -> CGPoint in
            return self.turn(type: type, radius: radius, path: path, isDown: isDown)
        }
    }
    
    private func turn(type: RectsCalculatorTurnType, radius: CGFloat, path: UIBezierPath, isDown: Bool) -> CGPoint {
        var result: CGPoint = .zero
        if isDown {
            switch type {
            case .topLeft(let destination):
                path.addLine(to: destination.offsetBy(dx: 0, dy: -radius))
                path.addArc(withCenter: destination.offsetBy(dx: -radius, dy: -radius), radius: radius, startAngle: 0, endAngle: .pi / 2, clockwise: true)
                result = destination
            case .topRight(let destination):
                path.addLine(to: destination.offsetBy(dx: 0, dy: -radius))
                path.addArc(withCenter: destination.offsetBy(dx: radius, dy: -radius), radius: radius, startAngle: .pi, endAngle: .pi / 2, clockwise: false)
                result = destination
            case .bottomLeft(let destination):
                path.addLine(to: destination.offsetBy(dx: -radius, dy: 0))
                path.addArc(withCenter: destination.offsetBy(dx: -radius, dy: radius), radius: radius, startAngle: 3 * .pi / 2, endAngle: 0, clockwise: true)
                result = destination
            case .bottomRight(let destination):
                path.addLine(to: destination.offsetBy(dx: radius, dy: 0))
                path.addArc(withCenter: destination.offsetBy(dx: radius, dy: radius), radius: radius, startAngle: 3 * .pi / 2, endAngle: .pi, clockwise: false)
                result = destination
            }
        }
        else {
            switch type {
            case .topLeft(let destination):
                path.addLine(to: destination.offsetBy(dx: -radius, dy: 0))
                path.addArc(withCenter: destination.offsetBy(dx: -radius, dy: -radius), radius: radius, startAngle: .pi / 2, endAngle: 0, clockwise: false)
                result = destination
            case .topRight(let destination):
                path.addLine(to: destination.offsetBy(dx: radius, dy: 0))
                path.addArc(withCenter: destination.offsetBy(dx: radius, dy: -radius), radius: radius, startAngle: .pi / 2, endAngle: .pi, clockwise: true)
                result = destination
            case .bottomLeft(let destination):
                path.addLine(to: destination.offsetBy(dx: 0, dy: -radius))
                path.addArc(withCenter: destination.offsetBy(dx: -radius, dy: radius), radius: radius, startAngle: 0, endAngle: 3 * .pi / 2, clockwise: false)
                result = destination
            case .bottomRight(let destination):
                path.addLine(to: destination.offsetBy(dx: 0, dy: radius))
                path.addArc(withCenter: destination.offsetBy(dx: radius, dy: radius), radius: radius, startAngle: .pi, endAngle: 3 * .pi / 2, clockwise: true)
                result = destination
            }
        }
        return result
    }
    
    func calculate(for alignment: NSTextAlignment, size: CGSize) -> UIBezierPath {
        guard rects.count > 0 else { return UIBezierPath(roundedRect: rects[0], cornerRadius: 8) }
        if alignment == .left {
            rects = rects.map { $0.insetBy(dx: $0.origin.x, dy: 0).offsetBy(dx: -2 * $0.origin.x, dy: 0) }
        }
        var repeatIndex: Int? = 0
        while let start = repeatIndex {
            var i = start
            repeatIndex = nil
            for j in start + 1 ..< rects.count {
                let delta = alignment == .left ? rects[i].width - rects[j].width : rects[i].origin.x - rects[j].origin.x
                if delta > 0 && delta < 20 {
                    if repeatIndex == nil {
                        repeatIndex = max(i - 1, 0)
                    }
                    let y = rects[i].origin.y
                    rects[i] = rects[j]
                    rects[i].origin.y = y
                }
                else if delta < 0 && delta > -20 {
                    let y = rects[j].origin.y
                    rects[j] = rects[i]
                    rects[j].origin.y = y
                }
                i += 1
            }
        }
        
        let rounded = rects.map { $0.integral }
        let path = UIBezierPath()
        let radius = 4 * UIScreen.main.scale
        var mirrorTurns: [RectsCalculatorTurnType] = []
        let downTurn = addTurn(radius: radius, path: path, isDown: true)
        let topCenter = rounded[0].origin.offsetBy(dx: rounded[0].width / 2, dy: 0)
        let mirror: (CGPoint) -> CGPoint = {
            let delta = topCenter.x - $0.x
            return CGPoint(x: topCenter.x + delta, y: $0.y)
        }
        
        path.move(to: topCenter)
        var currentPoint = alignment == .left ? CGPoint(x: 0, y: rounded[0].origin.y) : rounded[0].origin
        currentPoint = downTurn(.bottomRight(currentPoint))
        if alignment == .center {
            mirrorTurns.append(.bottomLeft(mirror(currentPoint)))
        }
        else if alignment == .right {
            mirrorTurns.append(.bottomLeft(CGPoint(x: size.width, y: currentPoint.y)))
        }
        else if alignment == .left {
            currentPoint = CGPoint(x: rounded[0].maxX, y: rounded[0].origin.y)
            mirrorTurns.append(.bottomLeft(currentPoint))
        }
        
        for (i, next) in rounded.suffix(from: 1).enumerated() {
            let bottomPoint = CGPoint(x: currentPoint.x, y: next.origin.y)
            if alignment != .left && next.origin.x - currentPoint.x > 1 {
                currentPoint = downTurn(.topRight(bottomPoint))
                if alignment == .center {
                    mirrorTurns.append(.topLeft(mirror(currentPoint)))
                }
                
                currentPoint = downTurn(.bottomLeft(next.origin))
                if alignment == .center {
                    mirrorTurns.append(.bottomRight(mirror(currentPoint)))
                }
            }
            else if alignment != .left && (next.origin.x - currentPoint.x < -1) {
                currentPoint = downTurn(.topLeft(bottomPoint))
                if alignment == .center {
                    mirrorTurns.append(.topRight(mirror(currentPoint)))
                }
                
                currentPoint = downTurn(.bottomRight(next.origin))
                if alignment == .center {
                    mirrorTurns.append(.bottomLeft(mirror(currentPoint)))
                }
            }
            else if alignment == .left && next.maxX - currentPoint.x > 1 {
                mirrorTurns.append(.topRight(CGPoint(x: currentPoint.x, y: next.origin.y)))
                currentPoint = CGPoint(x: next.maxX, y: next.origin.y)
                mirrorTurns.append(.bottomLeft(currentPoint))
            }
            else if alignment == .left && next.maxX - currentPoint.x < -1 {
                mirrorTurns.append(.topLeft(CGPoint(x: currentPoint.x, y: next.origin.y)))
                currentPoint = CGPoint(x: next.maxX, y: next.origin.y)
                mirrorTurns.append(.bottomRight(currentPoint))
            }
            if i == rounded.count - 2 { // started from second element
                let bottomPoint = next.origin.offsetBy(dx: 0, dy: next.height)
                if alignment == .left {
                    let leftPoint = CGPoint(x: 0, y: bottomPoint.y)
                    _ = downTurn(.topRight(leftPoint))
                    mirrorTurns.append(.topLeft(CGPoint(x: currentPoint.x, y: next.origin.y + next.height)))
                }
                else {
                    currentPoint = downTurn(.topRight(bottomPoint))
                    if alignment == .center {
                        mirrorTurns.append(.topLeft(mirror(currentPoint)))
                    }
                    else if alignment == .right {
                        mirrorTurns.append(.topLeft(CGPoint(x: size.width, y: currentPoint.y)))
                    }
                }
            }
        }
        if rounded.count == 1 {
            let bottom = currentPoint.offsetBy(dx: 0, dy: rounded[0].height)
            if alignment == .left {
                _ = downTurn(.topRight(CGPoint(x: 0, y: bottom.y)))
            }
            else {
                _ = downTurn(.topRight(bottom))
            }
            if case .bottomLeft(let pnt)? = mirrorTurns.first {
                mirrorTurns.append(.topLeft(CGPoint(x: pnt.x, y: bottom.y)))
            }
        }
        for step in mirrorTurns.reversed() {
            _ = addTurn(radius: radius, path: path, isDown: false)(step)
        }
        path.close()
        return path
    }
}

class RoundedBackgroundLayoutManager: NSLayoutManager {
    
    private var lastInvalidatedTime: Date = Date().addingTimeInterval(-100)
    var alignment: NSTextAlignment = .center
    
    override func fillBackgroundRectArray(_ rectArray: UnsafePointer<CGRect>, count rectCount: Int, forCharacterRange charRange: NSRange, color: UIColor) {
        
        let range = NSRange(location: 0, length: numberOfGlyphs)
        if Date().timeIntervalSince(lastInvalidatedTime) > 0.4 {
            invalidateDisplay(forCharacterRange: range)
            lastInvalidatedTime = Date()
        }
        let context = UIGraphicsGetCurrentContext()
        let calculator = RectsCalculator()
        enumerateLineFragments(forGlyphRange: range) { (rect, usedRect, textContainer, range, _) in
//            print(NSStringFromCGRect(rect), NSStringFromCGRect(usedRect), range)
            calculator.add(rect: usedRect.insetBy(dx: -5, dy: 0).offsetBy(dx: 0, dy: 8))
        }
        context?.addPath(calculator.calculate(for: alignment, size: textContainers.first!.size).cgPath)
        context?.setStrokeColor(UIColor.clear.cgColor)
        context?.drawPath(using: .fill)
    }
}

extension UITextView {

    class func roundedBackgroundTextView(size: CGSize, frame: CGRect) -> UITextView {
        let textStorage = NSTextStorage()
        let textLayout = RoundedBackgroundLayoutManager()
        textStorage.addLayoutManager(textLayout)
        let textContainer = NSTextContainer(size: size)
        textLayout.addTextContainer(textContainer)
        let textView = UITextView(frame: frame, textContainer: textContainer)
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textView.textAlignment = .center
        textView.font = UIFont.systemFont(ofSize: 32, weight: UIFont.Weight.bold)
        textView.backgroundColor = .clear
        textView.tintColor = .white
        textView.keyboardAppearance = .dark
        textView.spellCheckingType = .no
        return textView
    }
    
    var alignment: NSTextAlignment {
        get {
            return (textStorage.layoutManagers.first as! RoundedBackgroundLayoutManager).alignment
        }
        set {
            (textStorage.layoutManagers.first as! RoundedBackgroundLayoutManager).alignment = newValue
        }
    }
    
    func updateContent(fromOldSize size: CGSize) {
        guard let font = attributedText.attribute(NSAttributedString.Key.font, at: 0, effectiveRange: nil) as? UIFont else { return }
        let scale = bounds.size.width / size.width
        let updatedFont = UIFont.boldSystemFont(ofSize: font.pointSize * scale)
        let update = NSMutableAttributedString(attributedString: attributedText)
//        update.setAttributes([NSFontAttributeName: updatedFont], range: NSRange(location: 0, length: (attributedText.string as NSString).length))
        update.addAttribute(NSAttributedString.Key.font, value: updatedFont, range: NSRange(location: 0, length: (attributedText.string as NSString).length))
        attributedText = update
    }
}
