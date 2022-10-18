//
//  ToolShapeSelector.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 16/10/2022.
//

import UIKit

enum ToolShape {
    case arrow
    case circle
    
    static let all: [ToolShape] = [.arrow, .circle]
    
    var name: String {
        switch self {
        case .arrow:
            return "Arrow"
        case .circle:
            return "Round"
        }
    }
    
    var preview: UIImage! {
        switch self {
        case .circle:
            return .init(named: "circle_shape")!
        case .arrow:
            return .init(named: "arrow_shape")!
        }
    }
}

final class ToolShapeSelector: UIButton {
    private let shapePreview = UIImageView(frame: CGRect(origin: .zero, size: .square(side: 22)))
    private let nameLabel = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 50, height: 22)))
    
    var onShapeChange: ((ToolShape) -> Void)?
    
    var shape: ToolShape = .circle {
        didSet {
            shapePreview.image = shape.preview
            nameLabel.text = shape.name
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        for view in [nameLabel, shapePreview] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
            view.y = (height - view.height) / 2
            view.isUserInteractionEnabled = false
        }
        shapePreview.x = width - shapePreview.width
        nameLabel.font = .systemFont(ofSize: 17)
        shapePreview.contentMode = .scaleAspectFit
        nameLabel.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        shapePreview.autoresizingMask = [.flexibleLeftMargin, .flexibleBottomMargin]
        self.addAction { [weak self] in
            self?.insertShapesMenu()
        }
    }
    
    private func insertShapesMenu() {
        guard let window = self.window else { return }
        let container = MenuOverlayView(frame: window.bounds)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(container)
        
        let actions = ToolShape.all.map { shape in
            PopupMenu.Action(title: shape.name, image: shape.preview, action: { [weak self, weak container] in
                self?.shape = shape
                self?.onShapeChange?(shape)
                container?.onInteraction?()
            })
        }
        
        
        func animate(_ animation: @escaping VoidBlock, completion: VoidBlock? = nil) {
            UIView.animate(
                withDuration: 0.4,
                delay: 0,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0,
                options: [],
                animations: animation,
                completion: { finished in
                    if finished {
                        completion?()
                    }
                }
            )
        }
        
        let selfFrame = self.frameIn(view: window)
        
        let initialFrame = CGRect(x: selfFrame.origin.x - 50, y: selfFrame.origin.y - 50, width: 150, height: 10)
        
        let targetFrame = CGRect(
            x: container.width - 150 - 8,
            y: selfFrame.origin.y - CGFloat(actions.count * 44) - 8,
            width: 150,
            height: CGFloat(actions.count) * 44
        )
        
        let menu = PopupMenu(
            actions: actions,
            frame: initialFrame
        )
        menu.alpha = 0
        menu.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(menu)
        menu.frame = initialFrame
        
        container.onInteraction = { [weak menu, weak container] in
            animate({
                    menu?.alpha = 0
                    menu?.frame = initialFrame
                }, completion: {
                    container?.removeFromSuperview()
                })
        }
        
        animate({
            menu.alpha = 1
            menu.frame = targetFrame
        })
    }
}


private final class MenuOverlayView: UIView {
    var onInteraction: VoidBlock?
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            if !subview.isHidden && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        DispatchQueue.main.async {
            self.onInteraction?()
        }
        return true
    }
}
