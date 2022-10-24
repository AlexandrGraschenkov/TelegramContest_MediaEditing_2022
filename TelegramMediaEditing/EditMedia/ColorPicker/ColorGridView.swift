//
//  ColorGridView.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 21.10.2022.
//

import UIKit

final class ColorGridView: UIView, ColorSelectorProtocol {
    
    
    struct Index: Equatable {
        var row: Int
        var col: Int
    }
    var selectedIdx: Index? = nil {
        didSet {
            if oldValue == selectedIdx { return }
            if let idx = selectedIdx {
                colorPrivate = colors[idx.row][idx.col]
            }
            updateSelectedColor()
        }
    }
    var color: UIColor {
        get { colorPrivate }
        set { colorPrivate = newValue; trySelect(color: newValue) }
    }
    var onColorSelect: ((UIColor) -> ())?
    lazy var container: UIView = {
        let v = UIView(frame: bounds)
        v.layer.masksToBounds = true
        v.layer.cornerRadius = 8
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(v)
        return v
    }()
    let colors: [[UIColor]] = ColorGridView.generateColorsGrid()
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if colorViews.isEmpty {
            setup()
            updateSelectedColor()
        }
        
        let screenScale = UIScreen.main.scale
        for r in 0..<colorViews.count {
            let itemSize = CGSize(width: bounds.width / CGFloat(colorViews[r].count),
                                  height: bounds.height / CGFloat(colorViews.count))
            for c in 0..<colorViews[r].count {
                let v = colorViews[r][c]
                v.frame = CGRect(x: CGFloat(c) * itemSize.width,
                                 y: CGFloat(r) * itemSize.height,
                                 width: itemSize.width,
                                 height: itemSize.height).round(scale: screenScale)
            }
        }
        if let idx = selectedIdx {
            selectionView.frame = colorViews[idx.row][idx.col].frame.insetBy(dx: -1.5, dy: -1.5)
        }
    }

    // MARK: - private
    fileprivate var colorPrivate: UIColor = UIColor()
    fileprivate var selectionView: UIView!
    fileprivate var colorViews: [[UIView]] = []
    fileprivate func setup() {
        for r in 0..<colors.count {
            colorViews.append([])
            for c in 0..<colors[r].count {
                let v = UIView()
                v.backgroundColor = colors[r][c]
                container.addSubview(v)
                colorViews[colorViews.count-1].append(v)
            }
        }
        
        selectionView = UIView()
        selectionView.layer.cornerRadius = 2
        selectionView.layer.borderColor = UIColor.white.cgColor
        selectionView.layer.borderWidth = 3
        addSubview(selectionView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(onGesture(_:)))
        addGestureRecognizer(tap)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onGesture(_:)))
        addGestureRecognizer(pan)
    }
    fileprivate func trySelect(color: UIColor) {
        var idx: Index? = nil
        let comp = color.components
        for r in 0..<colors.count {
            for c in 0..<colors[r].count {
                let comp2 = colors[r][c].components
                if comp.equalRgb(other: comp2) {
                    idx = Index(row: r, col: c)
                    break
                }
            }
            if idx != nil {
                break
            }
        }
        selectedIdx = idx
    }
    fileprivate func updateSelectedColor() {
        guard let idx = selectedIdx else {
            selectionView.isHidden = true
            return
        }
        selectionView.isHidden = false
        selectionView.frame = colorViews[idx.row][idx.col].frame.insetBy(dx: -1.5, dy: -1.5)
    }
    
    @objc
    fileprivate func onGesture(_ gesture: UIGestureRecognizer) {
        let loc = gesture.location(in: self)
        switch gesture.state {
        case .began, .changed, .ended:
            var c = Int(CGFloat(colorViews[0].count) * (loc.x / bounds.width))
            var r = Int(CGFloat(colorViews.count) * (loc.y / bounds.height))
            r = r.clamp(0, colorViews.count-1)
            c = c.clamp(0, colorViews[r].count-1)
            selectedIdx = Index(row: r, col: c)
        default: break
        }
    }
}


fileprivate extension ColorGridView {
    static func generateColorsGrid() -> [[UIColor]] {
        let colorsVals = [0xFEFFFE, 0xEBEBEB, 0xD6D6D6, 0xC2C2C2, 0xADADAD, 0x999999, 0x858585, 0x707070, 0x5C5C5C, 0x474747, 0x333333, 0x000000,
                      0x00374A, 0x011D57, 0x11053B, 0x2E063D, 0x3C071B, 0x5C0701, 0x5A1C00, 0x583300, 0x563D00, 0x666100, 0x4F5504, 0x263E0F,
                      0x004D65, 0x012F7B, 0x1A0A52, 0x450D59, 0x551029, 0x831100, 0x7B2900, 0x7A4A00, 0x785800, 0x8D8602, 0x6F760A, 0x38571A,
                      0x016E8F, 0x0042A9, 0x2C0977, 0x61187C, 0x791A3D, 0xB51A00, 0xAD3E00, 0xA96800, 0xA67B01, 0xC4BC00, 0x9BA50E, 0x4E7A27,
                      0x008CB4, 0x0056D6, 0x371A94, 0x7A219E, 0x99244F, 0xE22400, 0xDA5100, 0xD38301, 0xD19D01, 0xF5EC00, 0xC3D117, 0x669D34,
                      0x00A1D8, 0x0061FD, 0x4D22B2, 0x982ABC, 0xB92D5D, 0xFF4015, 0xFF6A00, 0xFFAB01, 0xFCC700, 0xFEFB41, 0xD9EC37, 0x76BB40,
                      0x01C7FC, 0x3A87FD, 0x5E30EB, 0xBE38F3, 0xE63B7A, 0xFE6250, 0xFE8648, 0xFEB43F, 0xFECB3E, 0xFFF76B, 0xE4EF65, 0x96D35F,
                      0x52D6FC, 0x74A7FF, 0x864FFD, 0xD357FE, 0xEE719E, 0xFF8C82, 0xFEA57D, 0xFEC777, 0xFED977, 0xFFF994, 0xEAF28F, 0xB1DD8B,
                      0x93E3FC, 0xA7C6FF, 0xB18CFE, 0xE292FE, 0xF4A4C0, 0xFFB5AF, 0xFFC5AB, 0xFED9A8, 0xFDE4A8, 0xFFFBB9, 0xF1F7B7, 0xCDE8B5,
                      0xCBF0FF, 0xD2E2FE, 0xD8C9FE, 0xEFCAFE, 0xF9D3E0, 0xFFDAD8, 0xFFE2D6, 0xFEECD4, 0xFEF1D5, 0xFDFBDD, 0xF6FADB, 0xDEEED4]
        let colors = colorsVals.map {UIColor(rgb: $0)}
        return colors.chunked(into: 12)
    }
}

fileprivate extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
