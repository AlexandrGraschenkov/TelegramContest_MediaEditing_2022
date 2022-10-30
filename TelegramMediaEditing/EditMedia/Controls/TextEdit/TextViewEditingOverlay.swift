//
//  TextEditViewController.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 19/10/2022.
//

import UIKit

final class TextEditingResultView: UIView {
    
    private final class BorderView: UIView {
        override class var layerClass: AnyClass {
            CAShapeLayer.self
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            let borderLayer = self.layer as! CAShapeLayer
            borderLayer.strokeColor = UIColor.white.cgColor
            borderLayer.fillColor = nil
            borderLayer.lineWidth = 2
            borderLayer.lineCap = .round
            borderLayer.lineDashPattern = [12, 8]
            borderLayer.frame = self.bounds.inset(by: .tm_insets(top: -7, left: -15, bottom: -7, right: -15   ))
            borderLayer.path = UIBezierPath(roundedRect: borderLayer.bounds, cornerRadius: 12).cgPath
        }
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    var resultId: UUID?
    var moveState: OverlayOperationState?
    private var dashedBorder: BorderView?
    
    func setDashedBorderHidden(_ isHidden: Bool) {
        if (dashedBorder == nil) {
            let borderView = BorderView(frame: bounds)
            addSubview(borderView)
            borderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.dashedBorder = borderView
        }
        dashedBorder?.isHidden = isHidden
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
//        guard let dashedBorderLayer = dashedBorderLayer else { return }
//        dashedBorderLayer.frame = self.bounds
//        var boundingRect = bounds
//        for layer in (layer.sublayers ?? []) {
//            boundingRect = boundingRect.union(layer.frame)
//        }
        
//        for view in subviews {
//            for layer in (view.layer.sublayers ?? []) {
//                var rectInSelf = layer.frame
//                rectInSelf.origin.x += view.x
//                rectInSelf.origin.y += view.y
//                boundingRect = boundingRect.union(rectInSelf)
//            }
//        }
//        dashedBorderLayer.frame = boundingRect.inset(top: -10, left: -10, bottom: -10, right: -10)
    }
}

struct ImageEditingTextState: Equatable {
    let text: String?
    let font: UIFont
    let color: UIColor
    let style: TextStyle
    let alignment: NSTextAlignment
    
    static let defaultState = ImageEditingTextState(
        text: "",
        font: .systemFont(ofSize: 32),
        color: .white,
        style: .regular,
        alignment: .center
    )
}

final class TextEditingResult: Equatable {
    static func == (lhs: TextEditingResult, rhs: TextEditingResult) -> Bool {
        lhs.id == rhs.id
    }
    
    internal init(
        id: UUID = UUID(),
        view: TextEditingResultView,
        state: ImageEditingTextState,
        editingFrameInWindow: CGRect,
        changeHandler: TextStyleChangeHandler
    ) {
        self.id = id
        self.view = view
        self.state = state
        self.editingFrameInWindow = editingFrameInWindow
        self.changeHandler = changeHandler
        view.resultId = id
    }
    
    let id: UUID
    let view: TextEditingResultView
    let state: ImageEditingTextState
    let editingFrameInWindow: CGRect
    var changeHandler: TextStyleChangeHandler
}
    
protocol TextViewEditingOverlayDelegate: AnyObject {
    func textEditingOverlayDidCancel(_ overlay: TextViewEditingOverlay)
    func textEditingOverlay(_ overlay: TextViewEditingOverlay, doneEditingText: TextEditingResult)
}

final class TextViewEditingOverlay: UIView {
    private let cancelButton = UIButton()
    private let doneButton = UIButton()
    private var textViewCenteringContainer: TextEditingResultView!
    private let contentContainer = UIView()
    private let blurView = UIVisualEffectView()
    private var slider: ToolSlider!
    private var textStyleChangeHandler: TextStyleChangeHandler!
    
    weak var delegate: TextViewEditingOverlayDelegate?
    
    private let state: ImageEditingTextState?
        
    private let panelView: TextPanel
    private let colourPicker: ColourPickerButton
    private var panelContainer: UIView!
    private var textView: OutlineableTextView!
    private let history: History
    
    init(
        panelView: TextPanel,
        colourPicker: ColourPickerButton,
        panelContainer: UIView,
        state: ImageEditingTextState,
        previousResultId: UUID?,
        frame: CGRect,
        history: History
    ) {
        self.panelView = panelView
        self.colourPicker = colourPicker
        self.state = state
        self.history = history
        super.init(frame: frame)
        setup(panelOriginalContainer: panelContainer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup(panelOriginalContainer: UIView) {
        backgroundColor = .black.withAlphaComponent(0.2)
        
        panelContainer = panelOriginalContainer
        let safeArea = UIApplication.shared.tm_keyWindow.safeAreaInsets
        panelOriginalContainer.removeFromSuperview()
        panelContainer.frame = .init(
            x: 0,
            y: bounds.height - 48 - safeArea.bottom,
            width: bounds.width,
            height: 48
        )
        panelContainer.backgroundColor = UIColor(white: 0.4, alpha: 0.15)

        addSubview(panelContainer)
        panelContainer.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        if #available(iOS 13.0, *) {
            blurView.effect = UIBlurEffect(style: .systemThickMaterial)
        } else {
            blurView.effect = UIBlurEffect(style: .dark)
        }
        blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        blurView.frame = panelContainer.bounds
        panelContainer.insertSubview(blurView, at: 0)
        
        addSubview(contentContainer)
        contentContainer.frame = .init(x: 0, y: safeArea.top + 45, width: width, height: panelContainer.y - safeArea.top)
        contentContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        textViewCenteringContainer = TextEditingResultView()
        contentContainer.addSubview(textViewCenteringContainer)
        textViewCenteringContainer.frame = .init(
            x: 36,
            y: (contentContainer.height - 55) / 2,
            width: bounds.width - 72,
            height: 55
        )
        textViewCenteringContainer.autoresizingMask = [.flexibleWidth, .flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        
        configureButtons()
        
        let textView = OutlineableTextView(frame: textViewCenteringContainer.bounds)
        textView.tintColor = .white
        textView.isScrollEnabled = false
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textViewCenteringContainer.addSubview(textView)
        textView.delegate = self
        self.textView = textView
        textView.textColor = state?.color
        textView.backgroundColor = .clear
        textView.spellCheckingType = .no
        textView.autocorrectionType = .no
        
        self.slider = ToolSlider(frame: CGRect(origin: .zero, size: CGSize(width: 256, height: 56)))
        slider.valuesRange = 20...60
        slider.currentValue = state!.font.pointSize
        addSubview(slider)
        slider.center.y = textViewCenteringContainer.center.y - textViewCenteringContainer.height / 2
        slider.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        slider.center.x = 0
        slider.onChange = { [weak self] _ in
            guard let self = self else { return }
            self.sliderHideAnimationId = nil
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn], animations: {
                self.slider.center.x = 28
            }, completion: nil)

            self.textStyleChangeHandler.updateTextViewAttributes(fontSize: self.slider.currentValue)
            self.textViewDidChange(self.textView)
            self.scheduleSliderHide()
        }
        slider.onEndInteraction = { [weak self] in
            self?.scheduleSliderHide()
        }
        
        textStyleChangeHandler = TextStyleChangeHandler(textView: textView, history: history)
        textStyleChangeHandler.assignControls(textPanel: panelView, colourPicker: colourPicker)
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.keyboardWillShowNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            self?.animateWithKeyboard(notification: notification) { keyboardFrame in
                guard let self = self else { return }
                let shift = self.height - max(0, self.convert(keyboardFrame, from: self.window).origin.y)
                self.panelContainer.y = self.bounds.height - shift - self.panelContainer.height
                self.contentContainer.height = self.panelContainer.y - safeArea.top - 45
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.keyboardWillHideNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            self?.animateWithKeyboard(notification: notification) { _ in
                guard let self = self else { return }
                self.panelContainer.y = self.bounds.height - self.panelContainer.height - safeArea.bottom
                self.contentContainer.height = self.panelContainer.y - safeArea.top - 45
            }
        }
        
        guard let state = state else {
            return
        }
        
        performAsyncIn(.main, closure: {
            self.textStyleChangeHandler.applyState(state)
            self.textStyleChangeHandler.updateTextViewAttributes()
            if let text = state.text {
                self.textView.text = text
                self.textViewDidChange(self.textView)
            }
        })
    }
    
    private func configureButtons() {
        let safeArea = UIApplication.shared.tm_keyWindow.safeAreaInsets

        for btn in [cancelButton, doneButton] {
            addSubview(btn)
            btn.y = 10 + safeArea.top
            btn.setTitleColor(.white, for: .normal)
        }
        
        cancelButton.addAction { [weak self] in
            self?.textView.resignFirstResponder()
            self?.blurView.removeFromSuperview()
            delay(0.1) {
                guard let self = self else { return }
                self.delegate?.textEditingOverlayDidCancel(self)
            }
        }
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17)
        cancelButton.sizeToFit()
        cancelButton.x = 12
        cancelButton.autoresizingMask = [.flexibleRightMargin]
        
        doneButton.addAction { [weak self] in
            self?.done()
        }
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        doneButton.sizeToFit()
        doneButton.x = bounds.width - doneButton.width - 12
        doneButton.autoresizingMask = [.flexibleLeftMargin]
    }
    
    override func didMoveToWindow() {
        guard window != nil else { return }
        textView.becomeFirstResponder()
    }
    
    private func done() {
        guard !textView.text.isEmpty else { return }
        textView.resignFirstResponder()
        delay(0.1, closure: actualDone)
    }
    
    private func actualDone() {
        guard !textView.text.isEmpty else { return }
        blurView.removeFromSuperview()
        prepareViewToBePlacedOnCanvas()
        
        let result = TextEditingResult(
            view: textViewCenteringContainer,
            state: textStyleChangeHandler.currentState,
            editingFrameInWindow: textViewCenteringContainer.frameIn(view: window),
            changeHandler: self.textStyleChangeHandler
        )
        delegate?.textEditingOverlay(self, doneEditingText: result)
    }
    
    private var sliderHideAnimationId: UUID?
    private func scheduleSliderHide() {
        let id = UUID()
        self.sliderHideAnimationId = id
        delay(0.5) {
            if self.sliderHideAnimationId == id {
                UIView.animate(
                    withDuration: 0.2,
                    delay: 0,
                    options: [.curveEaseOut],
                    animations: {
                        self.slider.center.x = 0
                    },
                    completion: nil
                )
            }
        }
    }

    private func animateWithKeyboard(
        notification: Notification,
        animations: ((_ keyboardFrame: CGRect) -> Void)?
    ) {
        // Extract the duration of the keyboard animation
        let durationKey = UIResponder.keyboardAnimationDurationUserInfoKey
        let duration = notification.userInfo![durationKey] as! Double
        
        // Extract the final frame of the keyboard
        let frameKey = UIResponder.keyboardFrameEndUserInfoKey
        let keyboardFrameValue = notification.userInfo![frameKey] as! NSValue
        
        // Extract the curve of the iOS keyboard animation
        let curveKey = UIResponder.keyboardAnimationCurveUserInfoKey
        let curveValue = notification.userInfo![curveKey] as! Int
        let curve = UIView.AnimationCurve(rawValue: curveValue)!
        
        // Create a property animator to manage the animation
        let animator = UIViewPropertyAnimator(
            duration: duration,
            curve: curve
        ) {
            // Perform the necessary animation layout updates
            animations?(keyboardFrameValue.cgRectValue)
            
            // Required to trigger NSLayoutConstraint changes
            // to animate
            self.layoutIfNeeded()
        }
        
        // Start the animation
        animator.startAnimation()
    }
    
    private func prepareViewToBePlacedOnCanvas() {
        textView.isUserInteractionEnabled = false
        let scaleX = textViewCenteringContainer.transform.a
        let scaleY = textViewCenteringContainer.transform.d
        var textSize = textView.systemLayoutSizeFitting(
            .init(width: (contentContainer.width - 72),
                  height: contentContainer.height
                 ),
            withHorizontalFittingPriority: .defaultHigh,
            verticalFittingPriority: .fittingSizeLevel
        )
        textSize.width *= scaleX
        textSize.height *= scaleY

        textView.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
        let oldSize = textViewCenteringContainer.frame.size

        switch panelView.alignmentButton.textAlignment {
        case .center:
            textViewCenteringContainer.frame = CGRect(
                origin: CGPoint(
                    x: textViewCenteringContainer.x + (oldSize.width - textSize.width) / 2,
                    y: textViewCenteringContainer.y + (oldSize.height - textSize.height) / 2
                ),
                size: textSize)
        case .left:
            textViewCenteringContainer.frame.size = textSize
        case .right:
            textViewCenteringContainer.frame = CGRect(
                origin: CGPoint(
                    x: textViewCenteringContainer.x + textViewCenteringContainer.width - textSize.width,
                    y: textViewCenteringContainer.y + (oldSize.height - textSize.height) / 2
                ),
                size: textSize)
        default:
            break
        }
        textView.frame = textViewCenteringContainer.bounds
        if let textHighlightLayer = textStyleChangeHandler.textHighlightLayer {
            textHighlightLayer.frame = bounds
            textStyleChangeHandler.drawTextHighlight()
        }
        if panelView.styleButton.textStyle == .outlined {
            textView.outline()
        }
    }
}
    
extension TextViewEditingOverlay: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        let textSize = textView.systemLayoutSizeFitting(
            .init(width: contentContainer.width - 72,
                  height: contentContainer.height
                 ),
            withHorizontalFittingPriority: .defaultHigh,
            verticalFittingPriority: .fittingSizeLevel
        )
        if textSize.height <= contentContainer.height {
            textViewCenteringContainer.height = textSize.height
            textViewCenteringContainer.center.x = contentContainer.width / 2
            textViewCenteringContainer.center.y = contentContainer.height / 2
        } else {
            let scale = contentContainer.height / textSize.height
            textViewCenteringContainer.height = textSize.height
            textViewCenteringContainer.transform = .init(scaleX: scale, y: scale)
            textViewCenteringContainer.y = 0
        }
        if panelView.styleButton.textStyle == .framed {
            textStyleChangeHandler.drawTextHighlight()
        } else if panelView.styleButton.textStyle == .outlined {
            self.textView.outline()
        }
    }
}


final class TextStyleChangeHandler {
    private let historyId = UUID().uuidString
    private let textView: OutlineableTextView
    fileprivate(set) var textHighlightLayer: CAShapeLayer?
    private(set) var currentColor: UIColor! {
        didSet {
            updateTextViewAttributes()
        }
    }
    private var textPanel: TextPanel?
    private var colourPicker: ColourPickerButton?
    private let history: History
    
    var currentState: ImageEditingTextState {
        .init(
            text: textView.text,
            font: textView.font!,
            color: currentColor,
            style: textPanel?.styleButton.textStyle ?? .regular,
            alignment: textPanel?.alignmentButton.textAlignment ?? .center
        )
    }
    
    init(textView: OutlineableTextView, history: History) {
        self.textView = textView
        self.history = history
    }
    
    func assignControls(textPanel: TextPanel, colourPicker: ColourPickerButton) {
        self.textPanel = textPanel
        self.colourPicker = colourPicker
        
        colourPicker.onColourChange = { [weak self] color in
            guard let self = self else { return }
            let oldColor = self.currentColor
            self.currentColor = color
            guard !self.textView.isFirstResponder else { return }
            let forward = History.Element(objectId: self.historyId, action: .closure) { _, _, _ in
                self.colourPicker?.selectedColour = color
                self.currentColor = color
            }
            let back = History.Element(objectId: self.historyId, action: .closure) { _, _, _ in
                self.colourPicker?.selectedColour = oldColor ?? .white
                self.currentColor = oldColor
            }
            self.history.add(element: History.ElementGroup(forward: [forward], backward: [back]))
        }
        textPanel.onAttributeChange = { [weak self] change in
            guard let self = self else { return }
            let forward: History.Element
            let back: History.Element
            switch change {
            case .font(let change):
                forward = History.Element(objectId: self.historyId, action: .closure) { _, _, _ in
                    self.textPanel?.selectedFont = change.newValue
                    self.updateTextViewAttributes()
                }
                back = History.Element(objectId: self.historyId, action: .closure) { _, _, _ in
                    self.textPanel?.selectedFont = change.oldValue ?? ImageEditingTextState.defaultState.font
                    self.updateTextViewAttributes()
                }
            case .alignment(let change):
                forward = History.Element(objectId: self.historyId, action: .closure) { _, _, _ in
                    self.textPanel?.alignmentButton.textAlignment = change.newValue
                    self.updateTextViewAttributes()
                }
                back = History.Element(objectId: self.historyId, action: .closure) { _, _, _ in
                    self.textPanel?.alignmentButton.textAlignment = change.oldValue ?? ImageEditingTextState.defaultState.alignment
                    self.updateTextViewAttributes()
                }
            case .style(let change):
                forward = History.Element(objectId: self.historyId, action: .closure) { _, _, _ in
                    self.textPanel?.styleButton.setStyle(change.newValue, animated: true)
                    self.updateTextViewAttributes()
                }
                back = History.Element(objectId: self.historyId, action: .closure) { _, _, _ in
                    let style = change.oldValue ?? ImageEditingTextState.defaultState.style
                    self.textPanel?.styleButton.setStyle(style, animated: true)
                    self.updateTextViewAttributes()
                }
            }
            self.history.add(element: History.ElementGroup(forward: [forward], backward: [back]))
            self.updateTextViewAttributes()
        }
    }
    
    func applyState(_ state: ImageEditingTextState) {
        self.currentColor = state.color
        guard let textPanel = textPanel, let colourPicker = colourPicker else {
            return
        }

        textPanel.selectedFont = state.font
        textPanel.styleButton.setStyle(state.style, animated: false)
        colourPicker.selectedColour = state.color
        textPanel.alignmentButton.textAlignment = state.alignment
    }
    
    fileprivate func drawTextHighlight() {
        let textLayer = textView.layer
        textView.clipsToBounds = false
        let textContainerInset = textView.textContainerInset
        let uiInset: CGFloat = -10
        let radius: CGFloat = 6 * UIScreen.main.scale
        let highlightLayer: CAShapeLayer
        if let textHighlightLayer = textHighlightLayer {
            highlightLayer = textHighlightLayer
        } else {
            let layer = CAShapeLayer()
            layer.frame = textView.bounds
            layer.fillColor = currentColor.bestBackgroundColor.cgColor
            textView.layer.insertSublayer(layer, at: 0)
            textHighlightLayer = layer
            highlightLayer = layer
        }
        let layout = textView.layoutManager
        let range = NSMakeRange(0, layout.numberOfGlyphs)
        var rects: [CGRect] = []
        layout.enumerateLineFragments(forGlyphRange: range) { (_, usedRect, _, _, _) in
            if usedRect.width > 0 && usedRect.height > 0 {
                var rect = usedRect
                rect.origin.x += textContainerInset.left
                rect.origin.y += textContainerInset.top
                rect = highlightLayer.convert(rect, from: textLayer)
                rect = rect.insetBy(dx: uiInset, dy: uiInset)
                rects.append(rect)
            }
        }
        highlightLayer.path = CGPath.makeUnion(of: rects, cornerRadius: radius)
    }
    
    fileprivate func updateTextViewAttributes(fontSize: CGFloat? = nil) {
        guard let textPanel = textPanel else {
            return
        }

        let attributes = currentAttributes(fontSize: fontSize)
        textView.textAlignment = textPanel.alignmentButton.textAlignment
        textView.attributedText = NSAttributedString(string: textView.text, attributes: attributes)
        textView.typingAttributes = attributes
        switch textPanel.styleButton.textStyle {
        case .regular:
            textView.removeOutline()
            textHighlightLayer?.isHidden = true
        case .outlined:
            textView.outline()
            textView.outlineColor = currentColor.bestBackgroundColor
        case .framed:
            textView.removeOutline()
            textHighlightLayer?.fillColor = currentColor.bestBackgroundColor.cgColor
            textHighlightLayer?.isHidden = false
            drawTextHighlight()
        }
    }
    
    fileprivate func currentAttributes(fontSize: CGFloat? = nil) -> [NSAttributedString.Key : Any] {
        guard let textPanel = textPanel else {
            return [:]
        }

        let fontSize = fontSize ?? textView.font?.pointSize ?? 32
        let attributes: [NSAttributedString.Key : Any]
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textPanel.alignmentButton.textAlignment
    
        let color = currentColor ?? .white
        
        switch textPanel.styleButton.textStyle {
        case .regular, .framed:
            attributes = [.font : textPanel.selectedFont.withSize(fontSize),
                          .foregroundColor : color,
                          .paragraphStyle: paragraphStyle]
        case .outlined:
            attributes = [.font : textPanel.selectedFont.withSize(fontSize),
                          .foregroundColor : color,
                          .paragraphStyle: paragraphStyle,
            ]
        }
        return attributes
    }
}
