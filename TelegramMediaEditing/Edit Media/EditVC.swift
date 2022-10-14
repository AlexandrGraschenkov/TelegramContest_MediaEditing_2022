//
//  EditVC.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 12.10.2022.
//

import UIKit
import Photos


class EditVC: UIViewController {

    enum Media {
        case image(img: UIImage)
        case video(path: String)
    }
    var cacheImg: UIImage?
    var asset: PHAsset!
    var scroll: ZoomScrollView!
    var mediaContainer: UIView!
    var brush: BrushDrawer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(asset != nil)
        setupMediaContainer()
        setupUI()
    }
    
    fileprivate func setupUI() {
        view.backgroundColor = .black
        scroll = ZoomScrollView(frame: view.bounds)
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scroll)
        scroll.setup(content: mediaContainer)
        addCloseButton()
        addBrushAndTempControlls()
    }
    
    private func addCloseButton() {
        let button = UIButton()
        button.setTitle("Close", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            button.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15)
        ])
    }
    
    private func addBrushAndTempControlls() {
        brush = BrushDrawer()
        brush.setup(content: mediaContainer)
        
        let brushButt = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        brushButt.setImage(UIImage(systemName: "paintbrush.pointed"), for: .normal)
        brushButt.tintColor = .white
        brushButt.backgroundColor = UIColor(white: 0.2, alpha: 0.4)
        brushButt.layer.cornerRadius = 5
        brushButt.layer.masksToBounds = true
        brushButt.layer.borderColor = UIColor.white.cgColor
        brushButt.layer.borderWidth = 1
        brushButt.bottom = view.bounds.maxY
        brushButt.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        brushButt.addAction { [brush] butt in
            butt.isSelected = !butt.isSelected
            let imgName = butt.isSelected ? "paintbrush.pointed.fill" : "paintbrush.pointed"
            (butt as? UIButton)?.setImage(UIImage(systemName: imgName), for: .normal)
            brush?.active = butt.isSelected
        }
        view.addSubview(brushButt)
        
        
//        let forward = UIButton(frame: CGRect(x: 40, y: 0, width: 40, height: 40))
//        forward.
//        brushButt.bottom = view.bounds.maxY
//        brushButt.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
//        brushButt.addAction { butt in
//            butt.isSelected = !butt.isSelected
//            let imgName = butt.isSelected ? "paintbrush.pointed.fill" : "paintbrush.pointed"
//            (butt as? UIButton)?.setImage(UIImage(systemName: imgName), for: .normal)
//        }
    }
    
    @objc
    private func close() {
        dismiss(animated: true)
    }
    fileprivate func setupMediaContainer() {
        let size = CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))
        switch asset.mediaType {
        case .image:
            let imgView = UIImageView(frame: CGRect(origin: .zero, size: size))
            imgView.image = cacheImg
            imgView.clipsToBounds = true
            PHImageManager.default().fetchFullImage(asset: asset) { img in
                imgView.image = img
            }
            mediaContainer = imgView
        case .video:
            // TODO
            break
        default:
            // TODO not supported
            break
        }
    }
    
    // MARK: -
    

}
