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
        view.backgroundColor = .black
        scroll = ZoomScrollView(frame: view.bounds)
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scroll)
        scroll.setup(content: mediaContainer)
        addCloseButton()
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
    
    @objc
    private func close() {
        dismiss(animated: true)
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
