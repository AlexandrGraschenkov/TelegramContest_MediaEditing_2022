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
    func toolsContainer(_ container: ToolsContainer, didTriggerToolEdit: ToolView)
    func toolsContainer(_ container: ToolsContainer, didChangeActiveTool: ToolView)
}

final class ToolsContainer: UIView {
    
    weak var delegate: ToolsContainerDelegate?
    
    private var tools: [ToolViewContainer] = []
    private var selectedIndex: Int?
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        clipsToBounds = true
        let stackView = UIStackView()
        addSubview(stackView)
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 24
        stackView.pinEdges(to: self)
        
        let pen = ToolView(config: .pen)
        let brush = ToolView(config: .brush)
        let neon = ToolView(config: .neon)
        let pencil = ToolView(config: .pencil)
        let lasso = ToolView(config: .lasso)
        let eraser = ToolView(config: .eraser)
        
        self.tools = [pen, brush, neon, pencil, lasso, eraser].map { tool in
            let container = ToolViewContainer()
            container.addSubview(tool)
            container.toolView = tool
            tool.pinEdges(to: container, edges: [.top, .bottom])
            return container
        }
        
        for container in tools {
            stackView.addArrangedSubview(container)
            container.pinEdges(to: stackView, edges: [.top, .bottom])
            container.transform = .init(translationX: 0, y: 12)
        }
        
        let gradient = GradientView(frame: .zero)
        gradient.isUserInteractionEnabled = false
        addSubview(gradient)
        gradient.pinEdges(to: self, edges: [.leading, .trailing, .bottom])
        gradient.pinHeight(to: 16)
        
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
                self.tools[currentSelection].transform = .init(translationX: 0, y: 12)
            }
            self.tools[index].transform = .identity
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
    
    private func indedOfViewTouched(by gesture: UIGestureRecognizer) -> Int? {
        return tools.firstIndex(where: { $0.bounds.contains(gesture.location(in: $0)) })
    }
    
    private func triggerNavigaion(to tool: ToolViewContainer) {
        print("BOOM")
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
            triggerNavigaion(to: tools[toolIndex])
            gesture.isEnabled = false
            gesture.isEnabled = true
        } else if gesture.state == .ended {
            select(toolIndex, animated: true)
            delegate?.toolsContainer(self, didChangeActiveTool: tools[toolIndex].toolView)
        }
    }
}

private final class GradientView: UIView {
    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let layer = self.layer as! CAGradientLayer
        layer.colors = [UIColor.clear, UIColor.black].map(\.cgColor)
    }
}
