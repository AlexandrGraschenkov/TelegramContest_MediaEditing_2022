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
    case textEditCanceled
    case switchedToDraw
    case switchedToText
}

enum EditMode {
    case base
    case toolEdit
    case textEdit
}

final class EditorToolbar: UIView {
    
    static func createAndAdd(toView view: UIView, history: History) -> EditorToolbar {
        let botInset = UIApplication.shared.tm_keyWindow.safeAreaInsets.bottom
        let height = botInset + 162
        let toolbar = EditorToolbar(frame: CGRect(x: 0, y: view.bounds.height - height, width: view.bounds.width, height: height), bottomInset: botInset, history: history)
        toolbar.translatesAutoresizingMaskIntoConstraints = true
        toolbar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        view.addSubview(toolbar)
        return toolbar
    }
    
    func colorChangeOutside(color: UIColor) {
        toolsContainer.selectedTool?.tintColor = color.withAlphaComponent(1)
        let oldColor = colorPickerControl.selectedColour
        colorPickerControl.selectedColour = color
        colorPickerControl.onColourChange?(.init(oldValue: oldColor, newValue: color), true)
    }
    
    /// this view will be used for displaying tool size on
    weak var toolSizeDemoContainer: UIView?
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
    private var demoToolSizeView: DemoToolSizeView?
    
    private lazy var slider: ToolSlider = {
        let slider = ToolSlider(frame: CGRect(x: 46.5, y: 0, width: bounds.width - 158, height: bottomControlsContainer.height))
        slider.translatesAutoresizingMaskIntoConstraints = true
        slider.autoresizingMask = [.flexibleWidth]
        slider.valuesRange = 2...20
        slider.currentValue = 10
        return slider
    }()
    
    private lazy var shapeSelector: ToolShapeSelector = {
        let selector = ToolShapeSelector(frame: CGRect(x: self.bottomControlsContainer.width - 103, y: 0, width: 95, height: bottomControlsContainer.height))
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
    
    private let history: History

    init(frame: CGRect, bottomInset: CGFloat, history: History) {
        self.history = history
        super.init(frame: frame)
        bottomSafeInset = bottomInset
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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

        colorPickerControl.translatesAutoresizingMaskIntoConstraints = true
        topControlsContainer.addSubview(colorPickerControl)
        colorPickerControl.frame.size = .square(side: 33)
        colorPickerControl.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        colorPickerControl.onColourChange = { [weak self] change, _ in
            self?.actionHandler?(.colorChange(change.newValue))
            self?.toolsContainer.selectedTool?.tintColor = change.newValue.withAlphaComponent(1)
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
        colorPickerControl.onColourChange = { [weak self] change, _ in
            self?.actionHandler?(.colorChange(change.newValue))
            self?.toolsContainer.selectedTool?.tintColor = change.newValue.withAlphaComponent(1)
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
            guard let self = self else { return }
            if index == 0 {
                self.actionHandler?(.switchedToDraw)
                self.moveToDraw()
            } else {
                self.actionHandler?(.switchedToText)
                self.mode = .textEdit
                self.animateToTextMode()
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
                guard let self = self else { return }
                toolView?.lineWidth = value
                self.actionHandler?(.lineWidthChanged(value))
                if self.demoToolSizeView == nil, let demoSizeContainer = self.toolSizeDemoContainer {
                    self.demoToolSizeView = DemoToolSizeView(frame: CGRect(mid: demoSizeContainer.bounds.mid, size: .square(side: value*2)))
                    self.demoToolSizeView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    demoSizeContainer.addSubview(self.demoToolSizeView!)
                    self.demoToolSizeView?.animateAppear()
                }
                if let demoSize = self.demoToolSizeView {
                    demoSize.frame = CGRect(mid: demoSize.frame.mid, size: .square(side: value*2))
                }
            }
            slider.onEndInteraction = { [weak self] in
                self?.demoToolSizeView?.animateDisappearAndRemove()
                self?.demoToolSizeView = nil
            }
            
            bottomControlsContainer.addSubview(shapeSelector)
            if toolView.config.toolType == .eraser {
                shapeSelector.allowShapes = ToolShape.eraser
            } else {
                shapeSelector.allowShapes = ToolShape.brush
            }
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
                self.saveButton.frame = .init(x: self.bottomControlsContainer.width - 44 - 2.5, y: 0, width: 44, height: 44)
            },
            completion: { _ in
                self.slider.removeFromSuperview()
        })
    }
    
    private func animateToTextMode(state: ImageEditingTextState? = nil) {
        plusButton.isHidden = true
        topControlsContainer.addSubview(textPanel)
        textPanel.isGradientVisible = false
        textPanel.width = topControlsContainer.width - textPanel.x
        actionHandler?(.switchedToText)
        modeSwitcher.select(1, animated: true)
        
        let overlay = TextViewEditingOverlay(
            panelView: textPanel,
            colourPicker: colorPickerControl,
            panelContainer: topControlsContainer,
            state: state ?? .defaultState(),
            previousResultId: nil,
            frame: UIScreen.main.bounds,
            history: history
        )
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
            self.topControlsContainer.backgroundColor = .clear
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
                    focusedResult.changeHandler.assignControls(
                        textPanel: self.textPanel,
                        colourPicker: self.colorPickerControl,
                        state: focusedResult.state
                    )
                }
                self.actionHandler?(.textEditCanceled)
            }
            overlay.removeFromSuperview()
        })
        
    }
    
    private func moveToDraw() {
        self.mode = .base
        toolsContainer.alpha = 0
        insertSubview(toolsContainer, belowSubview: topControlsContainer)
        modeSwitcher.select(0, animated: true)
        if let focusedResult = focusedResult {
            unfocus(from: focusedResult)
        }
        assignColourPickerActionToDrawing()

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
        let lineWidth = tool.lineWidth ?? 10
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
        handlePreviouslySelectedViewIfNeeded(newResult: result)
        textEditingResults[result.id] = result
        actionHandler?(.textEditEnded(result))
        focus(on: result)
    }
    
    func handleTap(on view: TextEditingResultView) {
        guard let id = view.resultId, let result = textEditingResults[id] else { return }
        if let focused = self.focusedResult, focused != result {
            self.unfocus(from: focused)
        }
        self.focusedResult = result
        // hide tappedd view from the drawing canvas
        result.view.isHidden = true
        // open keyboard
        self.animateToTextMode(state: result.state)
    }
    
    func textEditingOverlayDidCancel(_ overlay: TextViewEditingOverlay) {
        textModeHiddenKeyboard(overlay: overlay, isCancel: true)
    }
    
    private func handlePreviouslySelectedViewIfNeeded(newResult: TextEditingResult) {
        guard let focusedResult = focusedResult else { return }
        let transform = focusedResult.view.transform
        let center = focusedResult.view.center
        if let mutation = focusedResult.view.moveState {
            newResult.view.moveState = mutation
        }
        focusedResult.view.removeFromSuperview()
        newResult.view.transform = transform
        newResult.view.center = center
        textEditingResults[focusedResult.id] = nil
    }

    private func focus(on textResult: TextEditingResult) {
        if let focused = self.focusedResult, focused != textResult {
            unfocus(from: focused)
        }
        self.focusedResult = textResult
        textResult.view.setDashedBorderHidden(false)
        textResult.changeHandler.assignControls(textPanel: textPanel, colourPicker: colorPickerControl, state: textResult.state)
    }
    
    private func unfocus(from textResult: TextEditingResult) {
        textResult.view.setDashedBorderHidden(true)
        if textResult == focusedResult {
            self.focusedResult = nil
        }
    }
}
