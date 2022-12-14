//
//  FontsSelector.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 21/10/2022.
//

import UIKit

final class FontsSelector: UIView {
    
    var onFontSelect: ((UIFont?, UIFont) -> Void)?
    var insets: UIEdgeInsets {
        get {
            layout.sectionInset
        }
        set {
            layout.sectionInset = newValue
        }
    }

    private var previouslySelectedFont: UIFont?
    var selectedFont: UIFont? {
        get {
            guard let indexPath = collectionView.indexPathsForSelectedItems?.first, allFonts.indices.contains(indexPath.item) else {
                return nil
            }
            return allFonts[indexPath.item]
        }
        set {
            guard let font = newValue, let index = allFonts.firstIndex(of: font) else { return }
            previouslySelectedFont = selectedFont
            collectionView.selectItem(
                at: IndexPath(item: index, section: 0),
                animated: false,
                scrollPosition: .centeredHorizontally
            )
        }
    }
    
    private var collectionView: UICollectionView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static let defaultFonts: [UIFont] = [
        .init(name: "Helvetica-Bold", size: 32),
        .init(name: "Menlo-Bold", size: 32),
        .init(name: "SnellRoundhand-Black", size: 32),
        .init(name: "Noteworthy-Bold ", size: 32),
        .init(name: "CourierNewPS-BoldMT", size: 32),
    ].compactMap { $0 }
    
    private let allFonts: [UIFont] = FontsSelector.defaultFonts
    
    private let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        return layout
    }()
    
    private(set) var maskGradient: GradientView!
    
    var isGradientVisible: Bool = true {
        didSet {
            if isGradientVisible {
                UIView.animate(
                    withDuration: 0.2,
                    delay: 0,
                    options: [],
                    animations: {
                        self.insets = .tm_insets(top: 0, left: self.bounds.width * 0.05, bottom: 0, right: self.bounds.width * 0.05)
                        self.maskGradient.layer.frame = self.bounds
                        self.layer.mask = self.maskGradient.layer
                    },
                    completion: nil
                )
            } else {
                UIView.animate(
                    withDuration: 0.2,
                    delay: 0,
                    options: [],
                    animations: {
                        self.insets = .zero
                        self.layer.mask = nil
                    },
                    completion: nil
                )
            }
        }
    }
    
    private func setup() {
        let collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        if #available(iOS 13.0, *) {
            collectionView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        collectionView.autoresizingMask = [.flexibleWidth]
        self.collectionView = collectionView
        collectionView.register(FontCell.self, forCellWithReuseIdentifier: FontCell.reuseIdentifier)
        
        addSubview(collectionView)
        collectionView.reloadData()
        collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .left)
        
        let gradientView = GradientView(frame: bounds)
        gradientView.colors = [.clear, .black, .black, .clear]
        gradientView.startPoint = CGPoint(x: 0, y: 0.5)
        gradientView.endPoint = CGPoint(x: 1, y: 0.5)
        gradientView.locations = [0, 0.05, 0.95, 1].map { NSNumber(value: $0) }
        layer.mask = gradientView.layer
        maskGradient = gradientView
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        maskGradient.layer.frame = bounds
    }
}

extension FontsSelector: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        allFonts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let font = self.selectedFont else { return }
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        onFontSelect?(previouslySelectedFont, font)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FontCell.reuseIdentifier, for: indexPath) as? FontCell else { return UICollectionViewCell() }
        let font = allFonts[indexPath.row]
        cell.label.font = font.withSize(13)
        cell.label.text = font.familyName
        return cell
    }
}

private final class FontCell: UICollectionViewCell {
    static let reuseIdentifier = "FontCell"
    
    let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override var isSelected: Bool {
        didSet {
            contentView.layer.borderColor = UIColor(white: 1, alpha: isSelected ? 1 : 0.3).cgColor
        }
    }
    
    private func setup() {
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        label.pinEdges(to: contentView, insets: .tm_insets(top: 0, left: 8, bottom: 0, right: -8))
        label.pinHeight(to: 30)
        label.textAlignment = .center
        label.textColor = .white
        contentView.layer.cornerRadius = 9
        contentView.layer.borderWidth = 2 / UIScreen.main.scale
        contentView.layer.borderColor = UIColor(white: 1, alpha: 0.3).cgColor
    }
}
