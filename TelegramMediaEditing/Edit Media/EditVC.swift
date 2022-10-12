//
//  EditVC.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 12.10.2022.
//

import UIKit


class EditVC: UIViewController {

    enum Media {
        case image(img: UIImage)
        case video(path: String)
    }
    var media: Media!
    var scroll: ZoomScrollView!
    var mediaContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(media != nil)
        setupMediaContainer()
        setupUI()
    }
    
    fileprivate func setupUI() {
        scroll = ZoomScrollView(frame: view.bounds)
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scroll)
        scroll.setup(content: mediaContainer)
    }
    
    fileprivate func setupMediaContainer() {
        switch media! {
        case .image(img: let img):
            let imgView = UIImageView(frame: CGRect(origin: .zero, size: img.pixelSize))
            imgView.image = img
            mediaContainer = imgView
        case .video(path: let videoPath):
            // TODO
            break
        }
    }
    
    // MARK: -
    

}
