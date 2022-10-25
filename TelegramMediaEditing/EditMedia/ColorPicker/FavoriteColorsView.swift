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
    let animDuration: Double = 0.25
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
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private func setup() {
        backgroundColor = .clear
        if let data = UserDefaults.standard.object(forKey: "favorite_colors") as? Data,
           let comps = try? JSONDecoder().decode([ColorComponents].self, from: data) {
            colors = comps.map({$0.toColorOverride()})
        }
        
        colorViews = colors.map({color in
            return generateColorView(color: color)
        })
    }
    
    private func generateColorView(color: UIColor) -> ColorCircleButt {
        let b = ColorCircleButt(frame: CGRect(x: 0, y: 0, width: elemSize, height: elemSize))
        b.color = color
        b.addTarget(self, action: #selector(colorPressed(butt:)), for: .touchUpInside)
        addSubview(b)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress(gesture:)))
        b.addGestureRecognizer(longPress)
        b.onDelete = {[weak self] butt in
            guard let self = self,
                  let idx = self.colorViews.firstIndex(of: butt) else { return }
            self.colorViews.remove(at: idx)
            self.colors.remove(at: idx)
            self.animateRemove(view: butt)
            UIView.animate(withDuration: self.animDuration, delay: 0, options: [.curveEaseInOut]) {
                self.layoutColorViews()
            }
            self.saveColors()
        }
        return b
    }
    
    @objc private func onLongPress(gesture: UILongPressGestureRecognizer) {
        guard let butt = gesture.view as? ColorCircleButt else {
            return
        }
        switch gesture.state {
        case .began:
            let menuController = UIMenuController.shared
            
            guard !menuController.isMenuVisible, butt.canBecomeFirstResponder else {
                return
            }
            butt.becomeFirstResponder()
            
            menuController.menuItems = [
                UIMenuItem(
                    title: "Delete",
                    action: #selector(ColorCircleButt.deleteAction)
                )
            ]
            
            menuController.setTargetRect(butt.frame, in: self)
            menuController.setMenuVisible(true, animated: true)
            feedbackGenerator.impactOccurred()
            
        case .possible:
            feedbackGenerator.prepare()
        default: break
        }
    }
    
    private func layoutColorViews() {
        var allViews: [UIView] = colorViews
        while allViews.count > maxCount {
            allViews.removeLast()
        }
        allViews += [addColorButt]
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
        guard let newColor = onAddColor?() else {
            return
        }
        
        let newComp = newColor.components
        if let updateIdx = colors.firstIndex(where: {$0.components == newComp}) {
            // already in collection, just reorder if needed
            if updateIdx == 0 {
                animatePop(view: colorViews[0])
            } else {
                let v = colorViews.remove(at: updateIdx)
                colorViews.insert(v, at: 0)
                let c = colors.remove(at: updateIdx)
                colors.insert(c, at: 0)
                UIView.animate(withDuration: animDuration, delay: 0, options: [.curveEaseInOut]) {
                    self.layoutColorViews()
                }
                saveColors()
            }
            return
        }
        
        colors.insert(newColor, at: 0)
        let newView = generateColorView(color: newColor)
        newView.frame = colorViews.first?.frame ?? addColorButt.frame
        colorViews.insert(newView, at: 0)
        while colorViews.count > maxCount {
            colors.removeLast()
            let v = colorViews.removeLast()
            animateRemove(view: v)
        }
        
        UIView.animate(withDuration: animDuration, delay: 0, options: [.curveEaseInOut]) {
            self.layoutColorViews()
        }
        animateAdd(view: newView)
        saveColors()
    }
    
    @objc private func colorPressed(butt: ColorCircleButt) {
        feedbackGenerator.impactOccurred()
        onSelectColor?(butt.color)
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
    
    private func animatePop(view: UIView) {
        
        UIView.animate(withDuration: animDuration*0.2, delay: 0, options: [.curveEaseInOut]) {
            view.transform = .init(scaleX: 0.7, y: 0.7)
        } completion: { _ in
            UIView.animate(withDuration: self.animDuration, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: -1, options: [.beginFromCurrentState]) {
                view.transform = .identity
            }
        }
    }
    
    private func animateAdd(view: UIView) {
        view.transform = .init(scaleX: 0.5, y: 0.5)
        view.alpha = 0
        UIView.animate(withDuration: animDuration, delay: 0, options: [.curveEaseInOut]) {
            view.alpha = 1
            view.transform = .identity
        }
    }
    
    private func animateRemove(view: UIView) {
        UIView.animate(withDuration: animDuration, delay: 0, options: [.curveEaseInOut]) {
            view.transform = .init(scaleX: 0.5, y: 0.5)
            view.alpha = 0
        } completion: { _ in
            view.removeFromSuperview()
        }
    }
    
    private func saveColors() {
        let comps = colors.map({ $0.components })
        if let data = try? JSONEncoder().encode(comps) {
            UserDefaults.standard.setValue(data, forKey: "favorite_colors")
            UserDefaults.standard.synchronize()
        }
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
    var onDelete: ((ColorCircleButt)->())?
    
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
    
    @objc fileprivate func deleteAction() {
        onDelete?(self)
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
}
