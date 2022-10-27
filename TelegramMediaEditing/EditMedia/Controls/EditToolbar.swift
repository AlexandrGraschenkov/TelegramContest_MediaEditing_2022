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
    case openColorPicker(startColor: UIColor)
    case textEditBegan(TextViewEditingOverlay)
    case textEditEnded(TextEditingResult)
}

enum EditMode {
    case base
    case toolEdit
    case textEdit
}

final class EditorToolbar: UIView {
    
    static func createAndAdd(toView view: UIView) -> EditorToolbar {
        let botInset = UIApplication.shared.tm_keyWindow.safeAreaInsets.bottom
        let height = botInset + 162
        let toolbar = EditorToolbar(frame: CGRect(x: 0, y: view.bounds.height - height, width: view.bounds.width, height: height), bottomInset: botInset)
        toolbar.translatesAutoresizingMaskIntoConstraints = true
        toolbar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        view.addSubview(toolbar)
        return toolbar
    }
    
    func colorChangeOutside(color: UIColor) {
        toolsContainer.selectedTool?.tintColor = color
        colorPickerControl.selectedColour = color
        colorPickerControl.onColourChange?(color)
    }
    
    var actionHandler: ((EditToolbarAction) -> Void)?
    private var cancelButton = BackOrCancelButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
    private var saveButton = UIButton()
    private var plusButton = UIButton()
    private let topControlsContainer = PassthroughView()
    private let bottomControlsContainer = PassthroughView()
    private let colorPickerControl = ColourPickerButton()
    private let modeSwitcher = CorneredSegmentedControl()
    private var toolsContainer: ToolsContainer!
    private var textEditingResults: [UUID: TextEditingResult] = [:]
    private var focusedResult: TextEditingResult?
    private var backgroundBlurMask: UIView!
    private var backgroundBlur: UIView!
    private var bottomSafeInset: CGFloat = 0
    
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

    init(frame: CGRect, bottomInset: CGFloat) {
        super.init(frame: frame)
        bottomSafeInset = bottomInset
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        bottomSafeInset = superview?.safeInsets.bottom ?? 0
        setup()
    }
    
    private func setup() {
        setupContainers()
        setupButtons()
        setupColourPicker()
        setupModeSwitcher()
        setupToolsContainer()
        setupBackgroundBlur()
    }
    
    private func setupContainers() {
        addSubview(bottomControlsContainer)
        
        bottomControlsContainer.frame = .init(
            x: 0,
            y: 0,
            width: self.width,
            height: 44
        )
        bottomControlsContainer.y = self.height - bottomControlsContainer.height - 2.5 - bottomSafeInset
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

        
        setupButtons()
        colorPickerControl.translatesAutoresizingMaskIntoConstraints = true
        topControlsContainer.addSubview(colorPickerControl)
        colorPickerControl.frame.size = .square(side: 33)
        colorPickerControl.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        colorPickerControl.onColourChange = { [weak self] color in
            self?.actionHandler?(.colorChange(color))
            self?.toolsContainer.selectedTool?.tintColor = color
        }
        colorPickerControl.onPress = { [weak self] butt in
            self?.actionHandler?(.openColorPicker(startColor: butt.selectedColour))
        }

        modeSwitcher.select(0, animated: false)
        modeSwitcher.translatesAutoresizingMaskIntoConstraints = true
        bottomControlsContainer.addSubview(modeSwitcher)
        modeSwitcher.height = 33
        modeSwitcher.width = width - cancelButton.width - saveButton.width - 32
        modeSwitcher.center = .init(x: bottomControlsContainer.width / 2, y: 33 / 2)
        modeSwitcher.autoresizingMask = [.flexibleWidth]
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
                if let focusedResult = self.focusedResult {
                    self.unfocus(from: focusedResult)
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
        assignColourPickerActionToDrawing()
    }
    
    private func assignColourPickerActionToDrawing() {
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
    
    private func setupBackgroundBlur() {
        let blur = UIVisualEffectView(frame: bounds.inset(top: 30))
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blur.effect = UIBlurEffect(style: .regular)
        for sub in blur.subviews {
            let className = NSStringFromClass(type(of: sub))
            if className == "_UIVisualEffectSubview" {
                sub.backgroundColor = UIColor(white: 0, alpha: 0.3)
            }
//            print(NSStringFromClass(type(of: sub)))
        }
        
        let mask = GradientView(frame: blur.frame)
        mask.startPoint = CGPoint(x: 0.5, y: 0)
        mask.endPoint = CGPoint(x: 0.5, y: 1)
        mask.colors = [UIColor(white: 0, alpha: 0), UIColor.black, UIColor.black]
        mask.locations = [0, NSNumber(value: 50 / blur.height), 1]
        mask.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blur.mask = mask
//        blurMask = mask
        
        insertSubview(blur, at: 0)
        backgroundBlur = blur
        backgroundBlurMask = mask
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
            options: [.beginFromCurrentState],
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
            options: [.beginFromCurrentState],
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
        modeSwitcher.select(1, animated: true)
        
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
                // in case of tap to text and cancel
                if let focusedResult = self.focusedResult {
                    // show it back in canvas
                    focusedResult.view.isHidden = false
                    focusedResult.changeHandler.assignControls(textPanel: self.textPanel, colourPicker: self.colorPickerControl)
                }
            }
            overlay.removeFromSuperview()
        })
        
    }
    
    private func moveToDraw() {
        self.mode = .base
        toolsContainer.alpha = 0
        addSubview(toolsContainer)
        modeSwitcher.select(0, animated: true)
        assignColourPickerActionToDrawing()
        if let focusedResult = focusedResult {
            unfocus(from: focusedResult)
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//         it's not in view hierarchy
        backgroundBlurMask.frame = backgroundBlur.frame
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
        let lineWidth = tool.lineWidth ?? tool.config.invariants?.initialLineWidth ?? 10
        actionHandler?(.lineWidthChanged(lineWidth))
        actionHandler?(.colorChange(tool.tintColor))
        UIView.animate(withDuration: 0.2) {
            self.colorPickerControl.selectedColour = tool.tintColor
        }
    }
    
    func toolsContainer(_ container: ToolsContainer, didFinishToolEdit tool: ToolView) {
        animateFromEditMode(animationDuration: 0.3)
    }
}

extension EditorToolbar: TextViewEditingOverlayDelegate {
    
    func textEditingOverlay(_ overlay: TextViewEditingOverlay, doneEditingText result: TextEditingResult) {
        textModeHiddenKeyboard(overlay: overlay, isCancel: false)
        self.textEditingResults[result.id] = result
        _ = UITapGestureRecognizer(addingTo: result.view) { [weak self] _ in
            guard let self = self else { return }
            // unfocus from any selected text
            if let focused = self.focusedResult, focused != result {
                self.unfocus(from: focused)
            }
            self.focusedResult = result
            // hide tappedd view from the drawing canvas
            result.view.isHidden = true
            // open keyboard
            self.animateToTextMode(state: result.state)
        }
        focusedResult?.view.isHidden = false
        focusedResult?.view.removeFromSuperview()
        actionHandler?(.textEditEnded(result))
        focus(on: result)
    }
    
    func textEditingOverlayDidCancel(_ overlay: TextViewEditingOverlay) {
        textModeHiddenKeyboard(overlay: overlay, isCancel: true)
    }
    
    private func focus(on textResult: TextEditingResult) {
        if let focused = self.focusedResult, focused != textResult {
            unfocus(from: focused)
        }
        self.focusedResult = textResult
        let borderLayer = CAShapeLayer()
        borderLayer.strokeColor = UIColor.white.cgColor
        borderLayer.fillColor = nil
        borderLayer.lineWidth = 2
        borderLayer.lineCap = .round
        borderLayer.lineDashPattern = [12, 8]
        borderLayer.frame = textResult.view.bounds.inset(by: UIEdgeInsets(top: -3, left: -10, bottom: -3, right: -10))
        borderLayer.path = UIBezierPath(roundedRect: borderLayer.bounds, cornerRadius: 12).cgPath
        textResult.view.layer.addSublayer(borderLayer)
        textResult.borderLayer = borderLayer
        textResult.changeHandler.assignControls(textPanel: textPanel, colourPicker: colorPickerControl)
    }
    
    private func unfocus(from textResult: TextEditingResult) {
        textResult.borderLayer?.removeFromSuperlayer()
        if textResult == focusedResult {
            self.focusedResult = nil
        }
    }
}
