//
//  TextEditViewController.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 19/10/2022.
//

import UIKit

struct ImageEditingTextState {
    let text: String?
    let font: UIFont
    let color: UIColor
    let style: TextStyle
    let alignment: NSTextAlignment
}
    
protocol TextViewEditingOverlayDelegate: AnyObject {
}

final class TextViewEditingOverlay: UIView {
    private let cancelButton = UIButton()
    private let doneButton = UIButton()
    private var textViewCenteringContainer: UIView!
    private let contentContainer = UIView()
    
    weak var delegate: TextViewEditingOverlayDelegate?
    
    private var state: ImageEditingTextState?
    
    private var currentColor: UIColor? {
        didSet {
            updateTextViewAttributes()
        }
    }
        
    private let panelView: TextPanel
    private let colourPicker: ColourPickerButton
    private var panelContainer: UIView!
    private var textView: UITextView!
    
    init(
        panelView: TextPanel,
        colourPicker: ColourPickerButton,
        panelContainer: UIView,
        state: ImageEditingTextState,
        frame: CGRect
    ) {
        self.panelView = panelView
        self.colourPicker = colourPicker
        self.state = state
        self.currentColor = state.color
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
        let blurView = UIVisualEffectView()
        blurView.effect = UIBlurEffect(style: .systemThickMaterial)
        blurView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        blurView.frame = panelContainer.bounds
        panelContainer.insertSubview(blurView, at: 0)
        
        addSubview(contentContainer)
        contentContainer.frame = .init(x: 0, y: safeArea.top, width: width, height: panelContainer.y - safeArea.top)
        contentContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        colourPicker.onColourChange = { [weak self] color in
            self?.currentColor = color
        }
        
        textViewCenteringContainer = UIView()
        contentContainer.addSubview(textViewCenteringContainer)
        textViewCenteringContainer.frame = .init(
            x: 36,
            y: (contentContainer.height - 55) / 2,
            width: bounds.width - 72,
            height: 55
        )
        textViewCenteringContainer.autoresizingMask = [.flexibleWidth, .flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        
        let textView = UITextView(frame: textViewCenteringContainer.bounds)
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        textViewCenteringContainer.addSubview(textView)
        textView.delegate = self
        self.textView = textView
        textView.textColor = state?.color
        textView.backgroundColor = .clear
        textView.spellCheckingType = .no
        textView.autocorrectionType = .no
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.keyboardWillShowNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            self?.animateWithKeyboard(notification: notification) { keyboardFrame in
                guard let self = self else { return }
                let shift = self.height - max(0, self.convert(keyboardFrame, from: self.window).origin.y)
                self.panelContainer.y = self.bounds.height - shift - self.panelContainer.height
                self.contentContainer.height = self.panelContainer.y - safeArea.top
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
                self.contentContainer.height = self.panelContainer.y - safeArea.top
            }
        }
        
        guard let state = state else {
            return
        }
        
        performAsyncIn(.main, closure: {
            if let text = state.text {
                self.textView.text = text
            }
            self.panelView.alignmentButton.textAlignment = state.alignment
            self.panelView.styleButton.textStyle = state.style
            self.panelView.selectedFont = state.font
            self.updateTextViewAttributes()
            self.colourPicker.selectedColour = state.color
        })
    }
    
    @objc private func tapGRDidFire(_ sender: UITapGestureRecognizer) {
        done()
    }
    
    override func didMoveToWindow() {
        guard window != nil else { return }
        textView.becomeFirstResponder()
    }
    
    private func done() {
        guard !textView.text.isEmpty else { return }
        textView.resignFirstResponder()
        delay(0.35, closure: actualDone)
    }
    
    private func actualDone() {
        guard !textView.text.isEmpty else { return }
        removeFromSuperview()
    }
    
    fileprivate func currentAttributes() -> [NSAttributedString.Key : Any] {
        let attributes: [NSAttributedString.Key : Any]
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = panelView.alignmentButton.textAlignment
    
        let color = currentColor ?? .black
        
        switch panelView.styleButton.textStyle {
        case .regular, .framed:
            attributes = [.font : panelView.selectedFont.withSize(32),
                          .foregroundColor : color,
                          .paragraphStyle: paragraphStyle]
        case .outlined:
            // TODO: implement this
            attributes = [.font : panelView.selectedFont.withSize(32),
                          .foregroundColor : UIColor.white,
                          .paragraphStyle : paragraphStyle]
        }
        return attributes
    }

    private func updateTextViewAttributes() {
        let attributes = currentAttributes()
        textView.textAlignment = self.panelView.alignmentButton.textAlignment
        textView.attributedText = NSAttributedString(string: textView.text, attributes: attributes)
        textView.typingAttributes = attributes
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
}

extension TextViewEditingOverlay: TextPanelDelegate {
    func textPanel(_ textPanel: TextPanel, didChangeFont: UIFont) {
        updateTextViewAttributes()
    }
    
    func textPanel(_ textPanel: TextPanel, didChangeAlignment: NSTextAlignment) {
        updateTextViewAttributes()
    }
    
    func textPanel(_ textPanel: TextPanel, didChangeTextStyle: TextStyle) {
        updateTextViewAttributes()
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
    }
}
