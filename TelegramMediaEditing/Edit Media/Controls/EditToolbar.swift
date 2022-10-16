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
    private var cancelButton = BackOrCancelButton(frame: CGRect(x: 0, y: 0, width: 33, height: 33))
    private var saveButton = UIButton()
    private var plusButton = UIButton()
    private let topControlsContainer = UIView()
    private let bottomControlsContainer = UIView()
    private let colorPickerControl = ColourPickerButton()
    private let modeSwitcher = CorneredSegmentedControl()
    private var toolsContainer: ToolsContainer!

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
        
        addSubview(bottomControlsContainer)
        bottomControlsContainer.translatesAutoresizingMaskIntoConstraints = false
        bottomControlsContainer.frame = .init(x: 8, y: height - 33 - 8 - 34, width: width - 16, height: 33)
        bottomControlsContainer.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        
        
        addSubview(topControlsContainer)
        topControlsContainer.translatesAutoresizingMaskIntoConstraints = false
        topControlsContainer.frame = .init(x: 8, y: bottomControlsContainer.y - 16 - 33, width: width - 16, height: 33)
        topControlsContainer.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        setupButtons()
        
        colorPickerControl.translatesAutoresizingMaskIntoConstraints = false
        topControlsContainer.addSubview(colorPickerControl)
        colorPickerControl.frame.size = .square(side: 33)
        colorPickerControl.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]

        modeSwitcher.select(0, animated: false)
        modeSwitcher.translatesAutoresizingMaskIntoConstraints = false
        bottomControlsContainer.addSubview(modeSwitcher)
        modeSwitcher.height = 33
        modeSwitcher.width = width - cancelButton.width - saveButton.width - 32
        modeSwitcher.center = .init(x: bottomControlsContainer.width / 2, y: 33 / 2)
        modeSwitcher.autoresizingMask = [.flexibleWidth]
//
        let pensContainer = ToolsContainer(frame: .init(x: 0, y: 0, width: width, height: bottomControlsContainer.y))
        pensContainer.translatesAutoresizingMaskIntoConstraints = false
        pensContainer.delegate = self
        addSubview(pensContainer)
        pensContainer.autoresizingMask = [.flexibleWidth]
        self.toolsContainer = pensContainer
    }
    
    private func setupButtons() {
        bottomControlsContainer.addSubview(cancelButton)
        bottomControlsContainer.addSubview(saveButton)
        topControlsContainer.addSubview(plusButton)
        
        let btns = [cancelButton, saveButton, plusButton]
        let actions: [EditToolbarAction] = [.close, .save, .add]
        let images = ["cancel_empty", "edit_save", "edit_plus"]
        
        for (btn, action, image) in zip3(btns, actions, images) {
            btn.addAction { [weak self] in
                self?.actionHandler?(action)
            }
            btn.setImage(.init(named: image), for: .normal)
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.frame.size = .square(side: 33)
        }
        
        cancelButton.removeTarget(nil, action: nil, for: .allEvents)
        cancelButton.addAction { [weak self] in
            guard let self = self else { return }
            if self.isInEditMode {
                self.animateFromEditMode()
            } else {
                self.actionHandler?(.close)
            }
        }
        
        cancelButton.autoresizingMask = [.flexibleRightMargin]
        
        saveButton.x = bottomControlsContainer.width - saveButton.width
        saveButton.autoresizingMask = [.flexibleLeftMargin]
        
        plusButton.x = topControlsContainer.width - plusButton.width
        plusButton.autoresizingMask = [.flexibleLeftMargin]
    }
    
    private var isInEditMode = false
    private lazy var slider: ToolSlider = {
        let slider = ToolSlider(frame: CGRect(x: 46.5, y: 0, width: bounds.width - 134, height: bottomControlsContainer.height))
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.autoresizingMask = [.flexibleWidth]
        slider.alpha = 0
        return slider
    }()
    
    private func animateToEditMode() {
        let buttonsToScale: [UIView] = [colorPickerControl, plusButton, saveButton]
//        saveButton.layer.anchorPoint = CGPoint(x: 1, y: 0.5)

        cancelButton.mode = .back
        
        bottomControlsContainer.addSubview(slider)
        slider.alpha = 0
        
        UIView.animate(
            withDuration: 3,
            delay: 0,
            options: [],
            animations: {
                buttonsToScale.forEach { $0.transform = .init(scaleX: 0.1, y: 0.1) }
                self.modeSwitcher.alpha = 0
                self.slider.alpha = 1
            },
            completion: { _ in
                buttonsToScale.forEach { $0.isHidden = true }
                self.isInEditMode = true
        })
    }
    
    private func animateFromEditMode() {
        let buttonsToScale: [UIView] = [colorPickerControl, plusButton, saveButton]
        cancelButton.mode = .cancel
        self.toolsContainer.finishEditing()
        buttonsToScale.forEach { $0.isHidden = false }
        UIView.animate(
            withDuration: 3,
            delay: 0,
            options: [],
            animations: {
                buttonsToScale.forEach { $0.transform = .identity }
                self.modeSwitcher.alpha = 1
                self.slider.alpha = 0
            },
            completion: { _ in
                
//                self.saveButton.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                self.slider.removeFromSuperview()
                self.isInEditMode = false
        })
    }
}

extension EditorToolbar: ToolsContainerDelegate {
    var viewForPopups: UIView? {
        return self.superview
    }
    
    func toolsContainer(_ container: ToolsContainer, didTriggerToolEdit tool: ToolView) {
        animateToEditMode()
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

