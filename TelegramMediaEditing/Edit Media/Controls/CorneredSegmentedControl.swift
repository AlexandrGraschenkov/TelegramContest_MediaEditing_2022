//
//  CorneredSegmentedControl.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 15/10/2022.
//

import UIKit

final class CorneredSegmentedControl: UIView {
    private var selectionView = UIView()
    private var segmentViews: [UIView] = []
    private var selectedIndex: Int?
    private var isAnimating = false
    
    var onSelect: ((Int) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func select(_ index: Int, animated: Bool) {
        guard index < segmentViews.count else { return }
        let change = {
            self.selectionView.frame = self.segmentViews[index].frameIn(view: self).inset(by: .all(2))
        }
        selectedIndex = index
        if !animated {
            change()
            isAnimating = false
            setNeedsLayout()
            return
        }
        isAnimating = true
        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: [.beginFromCurrentState],
            animations: change,
            completion: { _ in
                self.isAnimating = false
        })
    }
    
    private func setup() {
        
        backgroundColor = .white.withAlphaComponent(0.1)
        
        let stackView = UIStackView()
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        addSubview(stackView)
        stackView.pinEdges(to: self)
        
        addSubview(selectionView)
        
        let texts = ["Draw", "Text"]
        for text in texts {
            let label = UILabel()
            label.text = text
            label.textColor = .white
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 13, weight: .semibold)
            stackView.addArrangedSubview(label)
            segmentViews.append(label)
        }
        
        selectionView.backgroundColor = .white.withAlphaComponent(0.3)
        
        let tagGR = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(tagGR)
    }
    
    @objc
    private func onTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        for (idx, view) in segmentViews.enumerated() {
            guard view.bounds.contains(recognizer.location(in: view)) else {
                continue
            }
            select(idx, animated: true)
            onSelect?(idx)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if let index = self.selectedIndex, index < segmentViews.count, !isAnimating {
            selectionView.frame = segmentViews[index].frameIn(view: self).inset(by: .all(2))
        }
        selectionView.layer.cornerRadius = selectionView.height / 2
        layer.cornerRadius = height / 2
    }
    
}
