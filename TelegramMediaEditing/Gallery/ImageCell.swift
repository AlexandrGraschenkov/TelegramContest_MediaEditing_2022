//
//  ImageCell.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 12/10/2022.
//

import UIKit

final class ImageCell: UICollectionViewCell {
    enum Content {
        case image(_ preview: UIImage?)
        case video(_ preview: UIImage?, _ duration: Double)
    }
    
    static let reuseId = "ImageCell"
    
    var assetId: String?
    var onReuse: Cancelable?
    
    private(set) var imageView: UIImageView!
    private var label: UILabel!
    private var gradientView: UIView!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        self.imageView = imageView
        contentView.addSubview(imageView)
        imageView.pinEdges(to: contentView)
        
        let gradient = UIImageView()
        gradient.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(gradient)
        NSLayoutConstraint.activate([
            gradient.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            gradient.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            gradient.heightAnchor.constraint(equalToConstant: 18),
            gradient.widthAnchor.constraint(equalToConstant: 35),
        ])
        gradient.isHidden = true
        gradient.image = UIImage(named: "gallery_cell_lbl_gradient")
        self.gradientView = gradient
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        label.textColor = .white
        label.font = .systemFont(ofSize: 13)
        NSLayoutConstraint.activate([
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3),
        ])
        label.isHidden = true
        self.label = label
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onReuse?()
        label.isHidden = true
        gradientView.isHidden = true
        self.assetId = nil
    }
    
    func configure(content: Content) {
        switch content {
        case .image(let preview):
            imageView.image = preview
        case .video(let preview, let duration):
            imageView.image = preview
            label.isHidden = false
            gradientView.isHidden = false
            label.text = durationString(duration)
        }
    }
    
    private func durationString(_ duration: Double) -> String {
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        let mins = Int(duration / 60)
        let hours = Int(duration / 3600)
        
        let withZeros = { (val: Int) -> String in
            return String(format: "%02d", val)
        }
        
        if hours == 0 {
            return "\(mins):" + withZeros(seconds)
        } else {
            return "\(hours)" + withZeros(mins) + ":" + withZeros(seconds)
        }
    }
}
