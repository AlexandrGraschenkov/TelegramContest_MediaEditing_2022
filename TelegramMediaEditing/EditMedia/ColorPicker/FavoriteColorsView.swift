//
//  FavoriteColorsView.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 24.10.2022.
//

import UIKit


final class FavoriteColorsView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    fileprivate(set) var colors: [UIColor] = []
    var onSelectColor: ((UIColor)->())?
    var onAddColor: (()->(UIColor))?
    let elemSize: CGFloat = 30
    let elemSpace: CGFloat = 22
    var lineCount: Int {
        return Int((bounds.width - elemSize) / (elemSize + elemSpace)) + 1
    }
    var maxCount: Int {
        return lineCount * 2 - 1
    }
    
    // MARK: - private
    private lazy var addColorButt: UIButton = {
        let b = ExpandButton(frame: CGRect(x: 0, y: 0, width: elemSize, height: elemSize))
        b.setImage(UIImage(named: "add_favorite_color"), for: .normal)
        b.addTarget(self, action: #selector(addColorPressed), for: .touchUpInside)
        addSubview(b)
        return b
    }()
    private var colorViews: [ColorCircleButt] = []
    private var prevSize: CGSize = .zero
    private func setup() {
        backgroundColor = .clear
        if let data = UserDefaults.standard.object(forKey: "favorite_colors") as? Data,
           let comps = try? JSONDecoder().decode([ColorComponents].self, from: data) {
            colors = comps.map({$0.toColorOverride()})
        }
        colors = [UIColor.red, UIColor.blue, UIColor.cyan.withAlphaComponent(0.5)]
        
        colorViews = colors.map({color in
            let b = ColorCircleButt(frame: CGRect(x: 0, y: 0, width: elemSize, height: elemSize))
            b.color = color
            self.addSubview(b)
            return b
        })
    }
    
    private func layoutColorViews() {
        var allViews: [UIView] = colorViews + [addColorButt]
        while allViews.count > maxCount {
            allViews.remove(at: allViews.count - 2) // don't touch add color butt
        }
        let lineCount = self.lineCount
        let fromX = bounds.width - (CGFloat(lineCount) * elemSize + CGFloat(lineCount-1) * elemSpace)
        for (idx, v) in allViews.enumerated() {
            let x = fromX + CGFloat(idx % lineCount)*(elemSize+elemSpace)
            let y = CGFloat(min(1, idx / lineCount)) * (elemSize+elemSpace)
            v.frame = CGRect(x: x, y: y, width: elemSize, height: elemSize)
        }
    }
    
    @objc private func addColorPressed() {
        // TODO
        print("Add color")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if bounds.insetBy(dx: -10, dy: -10).contains(point) {
            for sub in subviews {
                if let v = sub.hitTest(point.substract(sub.frame.origin), with: event) {
                    return v
                }
            }
            return nil
        } else {
            return nil
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size == prevSize { return }
        
        prevSize = bounds.size
        layoutColorViews()
    }
}

private class ExpandButton: UIButton {
    let expandTouchDist: CGFloat = 10
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if bounds.insetBy(dx: -expandTouchDist, dy: -expandTouchDist).contains(point) {
            return self
        } else {
            return nil
        }
    }
}

private final class ColorCircleButt: ExpandButton {
    var color: UIColor = .white {
        didSet { colorUpdate() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() {
        setBackgroundImage(UIImage(named: "chessboard_bg")!, for: .normal)
        layer.cornerRadius = bounds.height / 2
        layer.masksToBounds = true
        colorUpdate()
    }
    
    private lazy var overlayColor: UIView = {
        let v = UIView(frame: bounds)
        v.isUserInteractionEnabled = false
        v.backgroundColor = color
        v.layer.borderWidth = 2
        v.layer.cornerRadius = bounds.width / 2
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(v)
        return v
    }()
    private var prevSize: CGSize = .zero
    private func colorUpdate() {
        overlayColor.backgroundColor = color
        overlayColor.layer.borderColor = color.withAlphaComponent(1).cgColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if prevSize == bounds.size { return }
        prevSize = bounds.size
        layer.cornerRadius = bounds.height / 2
        overlayColor.layer.cornerRadius = bounds.height / 2
//        overColorLayer.path = CGPath(ellipseIn: bounds, transform: nil)
    }
    
    override var isHighlighted: Bool {
        didSet {
            if oldValue == isHighlighted { return }
            let color = isHighlighted ? self.color.offsetColor(brightness: -0.2) : self.color
            internalSet(color: color)
        }
    }
    
    fileprivate func internalSet(color: UIColor) {
        overlayColor.backgroundColor = color
        overlayColor.layer.borderColor = color.withAlphaComponent(1).cgColor
    }
}
