//
//  EditToolbar.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 14/10/2022.
//

import UIKit

enum EditToolbarAction {
    case close
    case save
    case add
    case toolChanged(ToolType)
}

final class EditorToolbar: UIView {
    
    var actionHandler: ((EditToolbarAction) -> Void)?
    private var cancelButton = UIButton()
    private var saveButton = UIButton()
    private let topControlsContainer = UIView()
    private let bottomControlsContainer = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .black.withAlphaComponent(0.5)
        addSubview(topControlsContainer)
        addSubview(bottomControlsContainer)
        bottomControlsContainer.pinEdges(
            to: self,
            edges: [.leading, .trailing, .bottom],
            insets: .tm_insets(left: 8, bottom: -8, right: -8),
            respectSafeArea: true
        )
        topControlsContainer.pinEdges(
            to: self,
            edges: [.leading, .trailing],
            insets: .tm_insets(left: 8, right: -8)
        )
        
        topControlsContainer.bottomAnchor.constraint(equalTo: bottomControlsContainer.topAnchor, constant: -16).isActive = true
        setupButtons()
        
        let colorPickerControl = ColourPickerButton()
        topControlsContainer.addSubview(colorPickerControl)
        colorPickerControl.pinSize(to: .square(side: 33))
        colorPickerControl.pinEdges(
            to: topControlsContainer,
            edges: [.leading, .bottom]
        )

        let modeSwitcher = CorneredSegmentedControl()
        modeSwitcher.select(0, animated: false)
        bottomControlsContainer.addSubview(modeSwitcher)
        
        modeSwitcher.pinEdges(to: bottomControlsContainer, edges: [.bottom, .top])
        NSLayoutConstraint.activate([
            modeSwitcher.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 16),
            modeSwitcher.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -16),
        ])
        
        let pensContainer = ToolsContainer()
        pensContainer.delegate = self
        addSubview(pensContainer)
        pensContainer.pinEdges(
            to: self,
            edges: [.leading, .trailing, .top],
            insets: .tm_insets(top: 0, left: 75, right: -75)
        )

        pensContainer.pinHeight(to: 88)
        pensContainer.bottomAnchor.constraint(equalTo: bottomControlsContainer.topAnchor).isActive = true
    }
    
    private func setupButtons() {
        bottomControlsContainer.addSubview(cancelButton)
        bottomControlsContainer.addSubview(saveButton)
        let plusButton = UIButton()
        topControlsContainer.addSubview(plusButton)
        
        let btns = [cancelButton, saveButton, plusButton]
        let actions: [EditToolbarAction] = [.close, .save, .add]
        let images = ["edit_cancel", "edit_save", "edit_plus"]
        
        for (btn, action, image) in zip3(btns, actions, images) {
            btn.addAction { [weak self] in
                self?.actionHandler?(action)
            }
            btn.setImage(.init(named: image), for: .normal)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.pinSize(to: .square(side: 33))
        }
        
        cancelButton.pinEdges(
            to: bottomControlsContainer,
            edges: [.leading, .bottom, .top]
        )
        
        saveButton.pinEdges(
            to: bottomControlsContainer,
            edges: [.trailing, .bottom]
        )
        
        plusButton.pinEdges(
            to: topControlsContainer,
            edges: [.trailing, .bottom, .top]
        )
    }
}

extension EditorToolbar: ToolsContainerDelegate {
    var viewForPopups: UIView? {
        return self.superview
    }
    
    func toolsContainer(_ container: ToolsContainer, didTriggerToolEdit tool: ToolView) {
        // TODO: do the transition
    }
    
    func toolsContainer(_ container: ToolsContainer, didChangeActiveTool tool: ToolView) {
        actionHandler?(.toolChanged(tool.config.toolType))
    }
}

final class ColourPickerButton: UIView {
    private var ringView: UIView!
    private var centerView: ColourPickerCirlce!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        ringView = UIImageView(image: UIImage(named: "edit_colour_control_ring")!)
        centerView = ColourPickerCirlce()
        addSubview(ringView)
        addSubview(centerView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        ringView.frame = bounds
        centerView.frame = bounds.inset(by: .all(5))
    }
}

