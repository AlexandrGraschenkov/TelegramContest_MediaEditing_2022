//
//  PenView.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 14/10/2022.
//

import UIKit

enum ToolType {
    case pen
    case marker
    case neon
    case pencil
    case lasso
    case eraser
    case objectEraser
    case blurEraser
}

final class ToolViewConfig {
    final class Invariants {
        init(tipImage: UIImage, lineView: UIView, initialColor: UIColor, initialLineWidth: CGFloat, shape: ToolShape = .circle) {
            self.tipImage = tipImage
            self.lineView = lineView
            self.initialColor = initialColor
            self.initialLineWidth = initialLineWidth
        }
        
        let tipImage: UIImage
        let lineView: UIView
        let initialColor: UIColor
        let initialLineWidth: CGFloat
    }
    
    init(baseImage: UIImage, toolType: ToolType, invariants: Invariants? = nil) {
        self.baseImage = baseImage
        self.toolType = toolType
        self.invariants = invariants
    }
    
    let baseImage: UIImage
    let toolType: ToolType
    let invariants: Invariants?
}

private final class ToolLineView: UIImageView {
    static func straight() -> ToolLineView {
        ToolLineView(image: UIImage(named: "pen_line_basic")!)
    }
    static func cornered() -> ToolLineView {
        ToolLineView(image: UIImage(named: "pen_line_corner")!)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 1
        clipsToBounds = true
    }
    
    init(image: UIImage) {
        super.init(image: image)
        layer.cornerRadius = 1
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ToolViewConfig {
    static let pen = ToolViewConfig(
        baseImage: UIImage(named: "pen_base")!,
        toolType: .pen,
        invariants: .init(
            tipImage: UIImage(named: "pen_tip")!,
            lineView: ToolLineView.straight(),
            initialColor: .white,
            initialLineWidth: 2
        )
    )
    
    static let marker = ToolViewConfig(
        baseImage: UIImage(named: "marker_base")!,
        toolType: .marker,
        invariants: .init(
            tipImage: UIImage(named: "marker_tip")!,
            lineView: ToolLineView.straight(),
            initialColor: UIColor(red: 255, green: 230, blue: 32, a: 1),
            initialLineWidth: 6
        )
    )
    
    static let neon = ToolViewConfig(
        baseImage: UIImage(named: "neon_base")!,
        toolType: .neon,
        invariants: .init(
            tipImage: UIImage(named: "neon_tip")!,
            lineView: ToolLineView.straight(),
            initialColor: UIColor(red: 50, green: 254, blue: 186, a: 1),
            initialLineWidth: 15
        )
    )
    
    static let pencil = ToolViewConfig(
        baseImage: UIImage(named: "pencil_base")!,
        toolType: .pencil,
        invariants: .init(
            tipImage: UIImage(named: "pencil_tip")!,
            lineView: ToolLineView.cornered(),
            initialColor: UIColor(red: 45, green: 136, blue: 243, a: 1),
            initialLineWidth: 8
        )
    )
    
    static let lasso = ToolViewConfig(baseImage: UIImage(named: "lasso_base")!, toolType: .lasso)
    
    static let eraser = ToolViewConfig(baseImage: UIImage(named: "eraser_base")!, toolType: .eraser)
    
    static let objectEraser = ToolViewConfig(baseImage: UIImage(named: "objectEraser_base")!, toolType: .objectEraser)
    
    static let blurEraser = ToolViewConfig(baseImage: UIImage(named: "blurEraser_base")!, toolType: .blurEraser)
}

final class ToolView: UIView {
    
    var lineWidth: CGFloat? {
        didSet {
            let ratio = bounds.width / 30
            lineView?.height = (lineWidth ?? 1) * ratio
        }
    }
    
    var shape: ToolShape = .circle
    
    override var frame: CGRect {
        didSet {
            let ratio = bounds.width / 20
            if let lineView = lineView, let lineWidth = lineWidth {
                lineView.frame = .init(x: 1.5 * ratio, y: bounds.height * 0.45, width: bounds.width - 1.5 * ratio * 2, height: lineWidth * ratio)
            }
        }
    }
    
    let config: ToolViewConfig
    
    override var tintColor: UIColor! {
        didSet {
            lineView?.backgroundColor = tintColor
        }
    }
    private var lineView: UIView?
    private var baseView: UIView?
    private var tipView: UIImageView?
    
    
    init(config: ToolViewConfig) {
        self.config = config
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // dirty but works
    func setInitialSize(size: CGSize) {
        frame.size = size
        baseView?.frame = bounds
        tipView?.frame = bounds
        let inset = 1.5 * bounds.width / 20
        if let lineView = lineView, let lineWidth = lineWidth {
            lineView.frame = .init(x: inset, y: bounds.height * 0.45, width: bounds.width - inset * 2, height: lineWidth)
        }
        
        baseView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tipView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func setup() {
        let base = UIImageView()
        base.translatesAutoresizingMaskIntoConstraints = true
        base.image = config.baseImage
        addSubview(base)
        base.frame = bounds
        base.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        guard let invariants = config.invariants else {
            return
        }

        tintColor = config.invariants?.initialColor.withAlphaComponent(1)
        let tipView = UIImageView()
        tipView.image = invariants.tipImage
        addSubview(tipView)
        tipView.translatesAutoresizingMaskIntoConstraints = true
        tipView.frame = bounds
        tipView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let lineView = invariants.lineView
        self.lineView = lineView
        addSubview(lineView)
        lineView.translatesAutoresizingMaskIntoConstraints = true
        self.lineWidth = invariants.initialLineWidth
        lineView.backgroundColor = invariants.initialColor
    }
}
