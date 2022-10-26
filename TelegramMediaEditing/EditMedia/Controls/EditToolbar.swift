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
    case lineWidthChanged(CGFloat)
    case toolShapeChanged(ToolShape)
    case colorChange(UIColor)
    case textEditBegan(TextViewEditingOverlay)
    case textEditEnded(TextEditingResult)
}

enum EditMode {
    case base
    case toolEdit
    case textEdit
}

final class EditorToolbar: UIView {
    
    var actionHandler: ((EditToolbarAction) -> Void)?
    private var cancelButton = BackOrCancelButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
    private var saveButton = UIButton()
    private var plusButton = UIButton()
    private let topControlsContainer = PassthroughView()
    private let bottomControlsContainer = PassthroughView()
    private let colorPickerControl = ColourPickerButton()
    private let modeSwitcher = CorneredSegmentedControl()
    private var toolsContainer: ToolsContainer!
    private var editingResult: TextEditingResult?
        
    private lazy var slider: ToolSlider = {
        let slider = ToolSlider(frame: CGRect(x: 46.5, y: 0, width: bounds.width - 150, height: bottomControlsContainer.height))
        slider.translatesAutoresizingMaskIntoConstraints = true
        slider.autoresizingMask = [.flexibleWidth]
        slider.valuesRange = 2...20
        slider.currentValue = 10
        return slider
    }()
    
    private lazy var shapeSelector: ToolShapeSelector = {
        let selector = ToolShapeSelector(frame: CGRect(x: self.bottomControlsContainer.width - 75, y: 0, width: 75, height: bottomControlsContainer.height))
        selector.autoresizingMask = [.flexibleLeftMargin]
        selector.shape = .circle
        return selector
    }()
    
    private lazy var textPanel: TextPanel = {
        let panel = TextPanel(frame: CGRect(x: colorPickerControl.frame.maxX, y: 0, width: plusButton.x - colorPickerControl.frame.maxX, height: topControlsContainer.height))
        panel.autoresizingMask = [.flexibleWidth, .flexibleTopMargin, .flexibleBottomMargin]
        return panel
    }()
    
    private var mode: EditMode = .base

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
        
        setupContainers()
        setupButtons()
        setupColourPicker()
        setupModeSwitcher()
        setupToolsContainer()
    }
    
    private func setupContainers() {
        addSubview(bottomControlsContainer)
        
        bottomControlsContainer.frame = .init(
            x: 0,
            y: 0,
            width: self.width,
            height: 44
        )
        bottomControlsContainer.y = self.height - bottomControlsContainer.height - 2.5 - UIApplication.shared.tm_keyWindow.safeAreaInsets.bottom
        bottomControlsContainer.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        
        addSubview(topControlsContainer)
        topControlsContainer.frame = .init(
            x: 0,
            y: 0,
            width: self.width,
            height: 44
        )
        topControlsContainer.y = bottomControlsContainer.y - 4 - topControlsContainer.height
        topControlsContainer.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
    }
    
    private func setupButtons() {
        let btns = [cancelButton, saveButton, plusButton]
        let actions: [EditToolbarAction] = [.close, .save, .add]
        let images = ["cancel_empty", "edit_save", "edit_plus"]
        
        for (btn, action, image) in zip3(btns, actions, images) {
            btn.addAction { [weak self] in
                self?.actionHandler?(action)
            }
            btn.setImage(.init(named: image), for: .normal)
            btn.translatesAutoresizingMaskIntoConstraints = true
            btn.frame.size = .square(side: 44)
        }
        
        cancelButton.removeTarget(nil, action: nil, for: .allEvents)
        cancelButton.addAction { [weak self] in
            guard let self = self else { return }
            if self.mode == .toolEdit {
                self.animateFromEditMode(animationDuration: 0.3)
            } else {
                self.actionHandler?(.close)
            }
        }
        
        bottomControlsContainer.addSubview(cancelButton)
        bottomControlsContainer.addSubview(saveButton)
        topControlsContainer.addSubview(plusButton)
        
        cancelButton.x = 2.5
        cancelButton.autoresizingMask = [.flexibleRightMargin]
        
        saveButton.x = bottomControlsContainer.width - saveButton.width - 2.5
        saveButton.autoresizingMask = [.flexibleLeftMargin]
        
        plusButton.x = topControlsContainer.width - plusButton.width - 2.5
        plusButton.autoresizingMask = [.flexibleLeftMargin]
        plusButton.addAction { [weak self] in
            guard let self = self else { return }
            switch self.mode {
            case .textEdit:
                if let editingResult = self.editingResult {
                    self.editingResult = nil
                    self.unfocus(on: editingResult)
                }
                self.animateToTextMode()
            case .base:
                // TODO: add shapes popup
                break
            case .toolEdit:
                break
            }
        }
    }
    
    private func setupColourPicker() {
        colorPickerControl.translatesAutoresizingMaskIntoConstraints = true
        topControlsContainer.addSubview(colorPickerControl)
        colorPickerControl.x = 2.5
        colorPickerControl.frame.size = .square(side: 44)
        colorPickerControl.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        colorPickerControl.onColourChange = { [weak self] color in
            self?.actionHandler?(.colorChange(color))
            self?.toolsContainer.selectedTool?.tintColor = color
        }
    }

    private func setupModeSwitcher() {
        modeSwitcher.select(0, animated: false)
        modeSwitcher.translatesAutoresizingMaskIntoConstraints = true
        bottomControlsContainer.addSubview(modeSwitcher)
        modeSwitcher.height = 33
        modeSwitcher.width = width - cancelButton.width - saveButton.width - 10
        modeSwitcher.center = .init(x: bottomControlsContainer.width / 2, y: bottomControlsContainer.height / 2)
        modeSwitcher.autoresizingMask = [.flexibleWidth]
        modeSwitcher.onSelect = { [weak self] index in
            if index == 0 {
                self?.moveToDraw()
            } else {
                self?.mode = .textEdit
                self?.animateToTextMode()
            }
        }
    }
    
    private func setupToolsContainer() {
        let toolsContainer = ToolsContainer(frame: .init(x: 0, y: 0, width: width, height: bottomControlsContainer.y + 5.5))
        toolsContainer.translatesAutoresizingMaskIntoConstraints = true
        toolsContainer.delegate = self
        addSubview(toolsContainer)
        toolsContainer.autoresizingMask = [.flexibleWidth]
        self.toolsContainer = toolsContainer
        bringSubviewToFront(topControlsContainer)
    }
    
    private func animateToEditMode(animationDuration: TimeInterval, toolView: ToolView) {
        guard self.mode == .base else { return }

        self.mode = .toolEdit
        let buttonsToScale: [UIView] = [colorPickerControl, plusButton]

        UIView.performWithoutAnimation {
            cancelButton.setMode(.back, animationDuration: animationDuration)
            
            bottomControlsContainer.addSubview(slider)
            slider.alpha = 0
            slider.currentValue = toolView.lineWidth ?? 0
            slider.onChange = { [weak self, weak toolView] value in
                toolView?.lineWidth = value
                self?.actionHandler?(.lineWidthChanged(value))
            }
            
            bottomControlsContainer.addSubview(shapeSelector)
            shapeSelector.shape = toolView.shape
            shapeSelector.alpha = 0
            shapeSelector.onShapeChange = { [weak self, weak toolView] shape in
                self?.actionHandler?(.toolShapeChanged(shape))
                toolView?.shape = shape
            }
        }
        
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: [],
            animations: {
                buttonsToScale.forEach { $0.transform = .init(scaleX: 0.1, y: 0.1) }
                self.modeSwitcher.alpha = 0
                self.slider.alpha = 1
                self.shapeSelector.alpha = 1
                self.saveButton.frame = .init(x: self.bottomControlsContainer.width, y: self.bottomControlsContainer.height / 2, width: 0, height: 0)
            },
            completion: { _ in
                buttonsToScale.forEach { $0.isHidden = true }
        })
    }
    
    private func animateFromEditMode(animationDuration: TimeInterval) {
        guard self.mode == .toolEdit else { return }
        self.mode = .base
        let buttonsToScale: [UIView] = [colorPickerControl, plusButton]
        cancelButton.setMode(.cancel, animationDuration: animationDuration)
        self.toolsContainer.finishEditing(animationDuration: animationDuration)
        buttonsToScale.forEach { $0.isHidden = false }
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: [],
            animations: {
                buttonsToScale.forEach { $0.transform = .identity }
                self.modeSwitcher.alpha = 1
                self.slider.alpha = 0
                self.shapeSelector.alpha = 0
                self.saveButton.frame = .init(x: self.bottomControlsContainer.width - 33, y: 0, width: 33, height: 33)
            },
            completion: { _ in
                self.slider.removeFromSuperview()
        })
    }
    
    private var lastOverlay: TextViewEditingOverlay? // retain to propogate actions when the keyboard is hidden
    private func animateToTextMode(state: ImageEditingTextState? = nil) {
        plusButton.isHidden = true
        topControlsContainer.addSubview(textPanel)
        textPanel.isGradientVisible = false
        textPanel.width = topControlsContainer.width - textPanel.x
        
        let overlay = TextViewEditingOverlay(
            panelView: textPanel,
            colourPicker: colorPickerControl,
            panelContainer: topControlsContainer,
            state: state ?? .init(
                text: "",
                font: textPanel.selectedFont,
                color: .white,
                style: .regular,
                alignment: .center
            ),
            frame: UIScreen.main.bounds
        )
        lastOverlay = overlay
        overlay.delegate = self
        
        textPanel.onAnyAttributeChange = { [weak overlay] in
            overlay?.updateText()
        }
        
        self.actionHandler?(.textEditBegan(overlay))

        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [],
            animations: {
                self.toolsContainer.alpha = 0
            },
            completion: { _ in
                self.toolsContainer.removeFromSuperview()
            }
        )
    }
    
    private func textModeHiddenKeyboard(overlay: TextViewEditingOverlay, isCancel: Bool) {
        textPanel.isGradientVisible = true
        plusButton.isHidden = false
        plusButton.alpha = 0
        topControlsContainer.removeFromSuperview()
        addSubview(topControlsContainer)
        self.topControlsContainer.frame = .init(
            x: 0,
            y: 0,
            width: self.width,
            height: 44
        )
        self.topControlsContainer.y = self.bottomControlsContainer.y - 4 - self.topControlsContainer.height
        topControlsContainer.alpha = 0
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [], animations: {
            self.topControlsContainer.backgroundColor = .black
            self.topControlsContainer.alpha = 1

            self.plusButton.alpha = 1
            self.textPanel.width = self.plusButton.x - self.textPanel.x
            overlay.backgroundColor = .clear
        }, completion: { _ in
            if isCancel {
                self.editingResult?.view.isHidden = false
            }
            overlay.removeFromSuperview()
        })
        
    }
    
    private func moveToDraw() {
        self.mode = .base
        toolsContainer.alpha = 0
        addSubview(toolsContainer)
        self.modeSwitcher.select(0, animated: true)
        if let editingResult = editingResult {
            unfocus(on: editingResult)
        }

        UIView.animate(
            withDuration: 0.2,
            delay: 0,
            options: [],
            animations: {
                self.textPanel.alpha = 0
                self.toolsContainer.alpha = 1
            },
            completion: { _ in
                self.textPanel.removeFromSuperview()
                self.textPanel.alpha = 1
            }
        )
    }
}

extension EditorToolbar: ToolsContainerDelegate {
    var viewForPopups: UIView? {
        return self.superview
    }
    
    func toolsContainer(_ container: ToolsContainer, didTriggerToolEdit tool: ToolView, animationDuration: TimeInterval) {
        animateToEditMode(animationDuration: animationDuration, toolView: tool)
    }
    
    func toolsContainer(_ container: ToolsContainer, didChangeActiveTool tool: ToolView) {
        actionHandler?(.toolChanged(tool.config.toolType))
    }
}

extension EditorToolbar: TextViewEditingOverlayDelegate {
    
    func textEditingOverlay(_ overlay: TextViewEditingOverlay, doneEditingText result: TextEditingResult) {
        textModeHiddenKeyboard(overlay: overlay, isCancel: false)
        _ = UITapGestureRecognizer(addingTo: result.view) { [weak self] _ in
            guard let self = self else { return }
            if let editingResult = self.editingResult, result != editingResult {
                self.unfocus(on: editingResult)
            }
            self.editingResult = result
            result.view.isHidden = true
            self.animateToTextMode(state: result.state)
            self.focus(on: result)
        }
        editingResult?.view.isHidden = false
        editingResult?.view.removeFromSuperview()
        actionHandler?(.textEditEnded(result))
        focus(on: result)
    }
    
    func textEditingOverlayDidCancel(_ overlay: TextViewEditingOverlay) {
        textModeHiddenKeyboard(overlay: overlay, isCancel: true)
    }
    
    private func focus(on textResult: TextEditingResult) {
        self.editingResult = textResult
        let borderLayer = CAShapeLayer()
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.fillColor = nil
        borderLayer.lineWidth = 2
        borderLayer.lineCap = .round
        borderLayer.lineDashPattern = [12, 8]
        borderLayer.frame = textResult.view.bounds
        borderLayer.path = UIBezierPath(roundedRect: textResult.view.bounds, cornerRadius: 12).cgPath
        textResult.view.layer.insertSublayer(borderLayer, at: 0)
        textResult.borderLayer = borderLayer
    }
    
    private func unfocus(on textResult: TextEditingResult) {
        textResult.borderLayer?.removeFromSuperlayer()
    }
}
