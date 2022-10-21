//
//  EditVC.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 12.10.2022.
//

import UIKit
import Photos


final class EditVC: UIViewController {

    enum Media {
        case image(img: UIImage)
        case video(path: String)
    }
    var cacheImg: UIImage?
    var asset: PHAsset!
    var scroll: ZoomScrollView!
    var mediaContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(asset != nil)
        setupMediaContainer()
        setupUI()
    }
    
    fileprivate func setupUI() {
        view.backgroundColor = .black
        scroll = ZoomScrollView(frame: view.bounds)
        scroll.translatesAutoresizingMaskIntoConstraints = true
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scroll)
        scroll.setup(content: mediaContainer)
        addCloseButton()
        
        let toolbar = EditorToolbar(frame: CGRect(x: 0, y: view.bounds.height - 196, width: view.bounds.width, height: 196))
        toolbar.translatesAutoresizingMaskIntoConstraints = true
        toolbar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        view.addSubview(toolbar)
        toolbar.actionHandler = { [weak self] action in
            switch action {
            case .textEditBegan(let overlay):
                self?.addTextView(overlay: overlay)
            default:
                print("Toolbar did trigger action \(action)")
            }
        }
    }
    
    private func addCloseButton() {
        let button = UIButton()
        button.setTitle("Close", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = true
        view.addSubview(button)
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        button.x = 15
        button.y = 32
        button.sizeToFit()
        button.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
    }
    
    private func addTextView(overlay: TextViewEditingOverlay) {
        view.addSubview(overlay)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
