//
//  ToolShapeSelector.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 16/10/2022.
//

import UIKit

enum ToolShape: String {
    case arrow
    case circle
    case eraserNormal
    case eraserObject
    case eraserBlur
    
    static let brush: [ToolShape] = [.circle, .arrow]
    static let eraser: [ToolShape] = [.eraserNormal, .eraserObject, .eraserBlur]
    
    var shortName: String {
        switch self {
        case .arrow:
            return "Arrow"
        case .circle:
            return "Round"
        case .eraserNormal:
            return "Eraser"
        case .eraserBlur:
            return "Blur"
        case .eraserObject:
            return "Object"
        }
    }
    
    var name: String {
        switch self {
        case .arrow:
            return "Arrow"
        case .circle:
            return "Round"
        case .eraserNormal:
            return "Eraser"
        case .eraserBlur:
            return "Background Blur"
        case .eraserObject:
            return "Object Eraser"
        }
    }
    
    var preview: UIImage! {
        switch self {
        case .circle:
            return .init(named: "circle_shape")!
        case .arrow:
            return .init(named: "arrow_shape")!
        case .eraserNormal:
            return .init(named: "circle_shape")!
        case .eraserBlur:
            return .init(named: "eraser_type_blur_icon")!
        case .eraserObject:
            return .init(named: "eraser_type_obj_shape")!
        }
    }
}

final class ToolShapeSelector: UIButton {
    private let shapePreview = UIImageView(frame: CGRect(origin: .zero, size: .square(side: 22)))
    private let nameLabel = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: 65, height: 22)))
    
    var onShapeChange: ((ToolShape) -> Void)?
    
    var allowShapes: [ToolShape] = ToolShape.brush
    var shape: ToolShape = .circle {
        didSet {
            shapePreview.image = shape.preview
            nameLabel.text = shape.shortName
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
            view.translatesAutoresizingMaskIntoConstraints = true
            addSubview(view)
            view.y = (height - view.height) / 2
            view.isUserInteractionEnabled = false
        }
        shapePreview.x = width - shapePreview.width
        nameLabel.font = .systemFont(ofSize: 17)
        nameLabel.textAlignment = .right
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
        container.translatesAutoresizingMaskIntoConstraints = true
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(container)
        
        let actions = allowShapes.map { shape in
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
        
        var width: CGFloat = 150
        if allowShapes.contains(.eraserObject) {
            width = 200
        }
        let initialFrame = CGRect(x: selfFrame.origin.x - 50, y: selfFrame.origin.y - 50, width: width, height: 10)
        
        let targetFrame = CGRect(
            x: container.width - width - 8,
            y: selfFrame.origin.y - CGFloat(actions.count * 44) - 8,
            width: width,
            height: CGFloat(actions.count) * 44
        )
        
        let menu = PopupMenu(
            actions: actions,
            frame: initialFrame
        )
        menu.alpha = 0
        menu.translatesAutoresizingMaskIntoConstraints = true
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


final class MenuOverlayView: UIView {
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
