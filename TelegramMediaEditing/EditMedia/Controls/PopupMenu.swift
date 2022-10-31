//
//  PopupMenu.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 16/10/2022.
//

import UIKit

final class PopupMenu: UIView {
    struct Action {
        let title: String
        let image: UIImage?
        let action: VoidBlock
    }
    
    init(actions: [Action], frame: CGRect, imageSize: CGSize = .square(side: 17)) {
        super.init(frame: frame)
        setup(actions: actions, imageSize: imageSize)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup(actions: [Action], imageSize: CGSize) {
        for (idx, action) in actions.enumerated() {
            let item = PopupMenuRow(frame: CGRect(x: 0, y: idx * 44, width: Int(width), height: 44), imageSize: imageSize)
            item.translatesAutoresizingMaskIntoConstraints = true
            addSubview(item)
            item.autoresizingMask = [.flexibleWidth]
            item.action = action
            if idx == actions.count - 1 {
                item.hideSeparator()
            }
        }
        backgroundColor = UIColor(red: 29, green: 29, blue: 29, a: 0.94)
        layer.cornerRadius = 16
    }
}

final class PopupMenuRow: UIView {
    private let label = UIButton()
    private let imageView = UIImageView()
    private var separator: UIView!
    
    var action: PopupMenu.Action? {
        didSet {
            imageView.image = action?.image
            label.setTitle(action?.title, for: .normal)
            label.addAction(action?.action ?? {})
        }
    }
    
    init(frame: CGRect, imageSize: CGSize) {
        super.init(frame: frame)
        setup(imageSize: imageSize)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hideSeparator() {
        separator.isHidden = true
    }
    
    private func setup(imageSize: CGSize) {
        label.translatesAutoresizingMaskIntoConstraints = true
        addSubview(label)
        label.frame = bounds.inset(by: .tm_insets(top: 0, left: 16, bottom: 0, right: 16))
        label.autoresizingMask = [.flexibleWidth, .flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin]
        label.titleLabel?.font = .systemFont(ofSize: 17)
        label.contentHorizontalAlignment = .left;

        label.setTitleColor(.white, for: .normal)
        
        imageView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(imageView)
        let imgSize = imageSize.width
        imageView.frame = .init(x: width - 16 - imgSize, y: (height - imgSize) / 2, width: imgSize, height: imgSize)
        imageView.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
        
        let px = 1 / UIScreen.main.scale
        let separator = UIView(frame: CGRect(x: 0, y: height - px, width: width, height: px))
        separator.backgroundColor = .white
        separator.translatesAutoresizingMaskIntoConstraints = true
        separator.autoresizingMask = [.flexibleWidth]
        separator.alpha = 0.3
        addSubview(separator)
        self.separator = separator
    }
}
