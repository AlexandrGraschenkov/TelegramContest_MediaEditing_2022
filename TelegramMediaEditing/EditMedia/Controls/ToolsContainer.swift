//
//  ToolsView.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 14/10/2022.
//

import UIKit

private final class ToolViewContainer: UIView {
    var toolView: ToolView!
}

protocol ToolsContainerDelegate: AnyObject {
    var viewForPopups: UIView? { get }
    func toolsContainer(_ container: ToolsContainer, didTriggerToolEdit: ToolView, animationDuration: Double)
    func toolsContainer(_ container: ToolsContainer, didChangeActiveTool: ToolView)
}

final class ToolsContainer: UIView {
    
    weak var delegate: ToolsContainerDelegate?
    
    private var tools: [ToolViewContainer] = []
    private var selectedIndex: Int?
    private var stack: ToolsStack!
    private var gradientMaskView: UIView!
    private let activeOffset: CGFloat = 0
    private let normalOffset: CGFloat = 14
    
    var selectedTool: ToolView? {
        selectedIndex.flatMap { tools[$0].toolView }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        clipsToBounds = true
        let pen = ToolView(config: .pen)
        let marker = ToolView(config: .marker)
        let neon = ToolView(config: .neon)
        let pencil = ToolView(config: .pencil)
        let lasso = ToolView(config: .lasso)
        let eraser = ToolView(config: .eraser)
        
        self.tools = [pen, marker, neon, pencil, lasso, eraser].map { tool in
            tool.translatesAutoresizingMaskIntoConstraints = true
            let container = ToolViewContainer()
            container.frame.size = CGSize(width: 20, height: 88)

            container.translatesAutoresizingMaskIntoConstraints = true
            container.addSubview(tool)
            container.toolView = tool
            tool.setInitialSize(size: container.bounds.size)
            tool.frame = container.bounds

            container.toolView.autoresizingMask = [.flexibleRightMargin, .flexibleLeftMargin]
            return container
        }
        
        for container in tools {
            container.toolView.transform = .init(translationX: 0, y: normalOffset)
        }
        
        let stackView = ToolsStack(views: self.tools)
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = true
        stackView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        stackView.frame = bounds
        stackView.insets = .init(top: 33, left: 75, bottom: 0, right: 75)
        self.stack = stackView
        
        let gradientMask = GradientView(frame: .zero)
        gradientMask.colors = [.black, .black, .clear]
        gradientMask.locations = [0, NSNumber(value: (bounds.height - 16) / bounds.height), 1]
        gradientMask.isUserInteractionEnabled = false
        gradientMask.frame = .init(x: 75, y: 0, width: bounds.width - 150, height: bounds.height)
        gradientMask.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        mask = gradientMask
        self.gradientMaskView = gradientMask
        
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(tapGR)
        
        let longPressGR = UILongPressGestureRecognizer(target: self, action: #selector(onLongPress))
        addGestureRecognizer(longPressGR)
        
        select(0, animated: false)
    }
    
    func select(_ index: Int, animated: Bool) {
        guard index < tools.count else { return }
        let currentSelection = selectedIndex
        let change = {
            if let currentSelection = currentSelection {
                self.tools[currentSelection].toolView.transform = .init(translationX: 0, y: self.normalOffset)
            }
            self.tools[index].toolView.transform = .init(translationX: 0, y: self.activeOffset)
        }
        
        selectedIndex = index
        
        if !animated {
            change()
            return
        }
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.55,
            initialSpringVelocity: 0,
            options: [.beginFromCurrentState],
            animations: change,
            completion: nil
        )
    }
    
    func finishEditing(animationDuration: Double) {
        stack.isHidden = false
        isUserInteractionEnabled = false
        stack.collapse(animationDuration: animationDuration, completion: {
            self.isUserInteractionEnabled = true
        })
        UIView.animate(withDuration: animationDuration) {
            self.gradientMaskView.height -= 16
            self.gradientMaskView.y += 16
        }
    }
    
    private func indedOfViewTouched(by gesture: UIGestureRecognizer) -> Int? {
        return tools.firstIndex(where: { $0.bounds.contains(gesture.location(in: $0)) })
    }
    
    private func triggerNavigaion(to tool: ToolViewContainer, index: Int) {
        isUserInteractionEnabled = false
        stack.expand(
            index: index,
            insertAction: { [weak self] view in
                guard let self = self else { return }
                self.insertSubview(view, belowSubview: self.gradientMaskView)
            },
            outsideAnimations: { [weak self] toolView, duration in
                guard let self = self else { return }
                self.gradientMaskView.height += 16
                self.gradientMaskView.y -= 16
                self.delegate?.toolsContainer(self, didTriggerToolEdit: toolView, animationDuration: duration)
            }, animationCompletion: {
                self.isUserInteractionEnabled = true
            }
        )
    }
    
    @objc
    private func onTap(_ gesture: UITapGestureRecognizer) {
        guard let toolIndex = indedOfViewTouched(by: gesture), toolIndex != selectedIndex else { return }
        
        select(toolIndex, animated: true)
        delegate?.toolsContainer(self, didChangeActiveTool: tools[toolIndex].toolView)
    }
    
    @objc
    private func onLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let toolIndex = indedOfViewTouched(by: gesture) else { return }
        if toolIndex == selectedIndex, gesture.state == .began {
            let isEditable = tools[toolIndex].toolView.config.invariants != nil
            guard isEditable else { return }
            triggerNavigaion(to: tools[toolIndex], index: toolIndex)
            gesture.isEnabled = false
            gesture.isEnabled = true
        } else if gesture.state == .ended {
            select(toolIndex, animated: true)
            delegate?.toolsContainer(self, didChangeActiveTool: tools[toolIndex].toolView)
        }
    }
}

private final class ToolsStack: UIView {
    private let views: [ToolViewContainer]
    private var expandedIndex: Int?
    
    // TODO: do properly
    private var savedFrame: CGRect?
    
    var insets: UIEdgeInsets = .zero
    
    init(views: [ToolViewContainer]) {
        self.views = views
        super.init(frame: .zero)
        for view in views {
            addSubview(view)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func expand(
        index: Int,
        insertAction: @escaping (UIView) -> Void,
        outsideAnimations: @escaping (ToolView, TimeInterval) -> Void,
        animationCompletion: @escaping VoidBlock
    ) {
        expandedIndex = index
        let expandedView = self.views[index]
        
        let duration: TimeInterval = 0.3
        let toolView = expandedView.toolView!
        let newContainer = superview!
        let frame = toolView.frameIn(view: newContainer)
        toolView.removeFromSuperview()
        insertAction(toolView)
        toolView.frame = frame
        self.savedFrame = frame

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: [],
            animations: {
                expandedView.frame = self.bounds
                outsideAnimations(toolView, duration)
            },
            completion: { _ in
                animationCompletion()
            })
        
        UIView.animate(
            withDuration: duration * 3.5,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0,
            options: [.curveEaseIn],
            animations: {
                toolView.frame = CGRect(x: (newContainer.width - 40) / 2, y: 0, width: 40, height: 88 * 2)
            },
            completion: { _ in }
        )

        var distances: [CGFloat] = []
        for i in 0..<views.count {
            distances.append(CGFloat(abs(index - i)))
        }
        let maxDist = distances.max()!

        for (idx, view) in views.enumerated() {
            let ratio = distances[idx] / maxDist
            let delay = (duration * 0.3) * (1 - ratio)
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.curveEaseOut],
                animations: {
                    if idx < index {
                        view.x -= 50 + (ratio * 100)
                    } else if idx > index {
                        view.x += 30 + (ratio * 100)
                    }
                    view.alpha = 0
                },
                completion: { _ in
                    
                })
            UIView.animate(withDuration: duration, delay: delay, options: [], animations: {
                if idx != index {
                    view.y = view.bounds.height * 2
                }
            }, completion: nil)
        }
    }
    
    func collapse(animationDuration: Double, completion: @escaping VoidBlock) {
        guard let expandedIndex = expandedIndex else { return }
        let containerView = views[expandedIndex]
        let toolView = containerView.toolView!
        
        let completion = {
            toolView.removeFromSuperview()
            toolView.frame = .init(x: (containerView.width - toolView.width) / 2, y: 0, width: toolView.frame.width, height: toolView.frame.height)
            containerView.addSubview(toolView)
            self.expandedIndex = nil
            completion()
        }
        
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: [],
            animations: {
                containerView.frame = self.desiredFrame(for: expandedIndex)
            },
            completion: nil)
        
        UIView.animate(
            withDuration: animationDuration * 3.5,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0,
            options: [.curveEaseIn],
            animations: {
                toolView.frame = self.savedFrame ?? .zero
            },
            completion: { _ in
                completion()
            }
        )
        
        var distances: [CGFloat] = []
        for i in 0..<views.count {
            distances.append(CGFloat(abs(expandedIndex - i)))
        }
        let maxDist = distances.max()!
        
        
        for (idx, view) in views.enumerated() {
            let frame = desiredFrame(for: idx)
            let ratio = distances[idx] / maxDist
            let delay = (animationDuration * 0.3) * ratio
            UIView.animate(
                withDuration: animationDuration,
                delay: delay,
                options: [.curveEaseIn],
                animations: {
                    view.alpha = 1
                    view.x = frame.minX
                },
                completion: { _ in
                })
            
            UIView.animate(withDuration: animationDuration, delay: delay, options: [.curveEaseOut], animations: {
                if idx != expandedIndex {
                    view.y = frame.minY
                }
            }, completion: { _ in
            })
        }
    }
    
    private var processedSize: CGSize?
    
    private func desiredFrame(for index: Int) -> CGRect {
        let contentWidth = width - insets.left - insets.right
        let containerWidth = contentWidth / CGFloat(views.count)
        return CGRect(x: containerWidth * CGFloat(index) + insets.left, y: insets.top, width: containerWidth, height: height - insets.top - insets.bottom)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard expandedIndex == nil else { return }
        for (idx, view) in views.enumerated() {
            view.frame = desiredFrame(for: idx)
        }
    }
}


