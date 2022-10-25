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
    var toolbar: EditorToolbar!
    weak var colorContentPicker: ColorContentPicker? // destroys by itself
    lazy var pen: PenDrawer = {
        let brush = PenDrawer()
        brush.setup(content: mediaContainer)
        return brush
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(asset != nil)
        setupMediaContainer()
        setupUI()
        pen.active = true
    }
    
    fileprivate func setupUI() {
        view.backgroundColor = .black
        scroll = ZoomScrollView(frame: view.bounds)
        scroll.translatesAutoresizingMaskIntoConstraints = true
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scroll)
        scroll.setup(content: mediaContainer)
        
        toolbar = EditorToolbar(frame: CGRect(x: 0, y: view.bounds.height - 196, width: view.bounds.width, height: 196))
        toolbar.translatesAutoresizingMaskIntoConstraints = true
        toolbar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        view.addSubview(toolbar)
        toolbar.actionHandler = { [unowned self] action in
            switch action {
            case .toolChanged(let type):
                self.pen.active = type == .pen
            case .colorChange(let color):
                if self.pen.active {
                    self.pen.color = color
                }
            case .lineWidthChanged(let width):
                self.pen.penSize = width
            case .openColorPicker:
                self.openColorPicker()
            case .textEditBegan(let overlay):
                self.addTextView(overlay: overlay)
            case .close:
                dismiss(animated: true)
            default:
                // TODO:
                break
            }
        }
    }
    
//    private func addCloseButton() {
//        let button = UIButton()
//        button.setTitle("Close", for: .normal)
//        button.translatesAutoresizingMaskIntoConstraints = true
//        view.addSubview(button)
//        button.addTarget(self, action: #selector(close), for: .touchUpInside)
//        button.x = 15
//        button.y = 32
//        button.sizeToFit()
//        button.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
//    }
    
    private func openColorPicker() {
        let picker = ColorPickerVC()
        picker.color = pen.color
        let onColorUpdate: (UIColor)->() = { [weak self] color in
            guard let self = self else { return }
            self.pen.color = color
            self.toolbar.selectedColor = color
        }
        picker.onPickColorFromContent = { [weak self] in
            guard let self = self else { return }
            
            let bounds = self.getMediaContainerContentFrame()
            self.colorContentPicker = ColorContentPicker.createOn(content: self.scroll, bounds: bounds, completion: onColorUpdate)
        }
        picker.onDismiss = onColorUpdate
//        present(nav, animated: true, completion: nil)
        present(picker, animated: false)
    }
    
    private func getMediaContainerContentFrame() -> CGRect {
        // intersection of counte
        let bounds = mediaContainer.convert(mediaContainer.bounds, to: view)
            .offsetBy(dx: scroll.x, dy: scroll.y)
        let scrollBounds = CGRect(origin: .zero, size: scroll.bounds.size)
        let tl = CGPoint(x: max(bounds.minX, scrollBounds.minX),
                         y: max(bounds.minY, scrollBounds.minY))
        let br = CGPoint(x: min(bounds.maxX, scrollBounds.maxX),
                         y: min(bounds.maxY, scrollBounds.maxY))
        return CGRect(origin: tl, size: br.substract(tl).size)
    }
    
    @objc
    private func close() {
        dismiss(animated: true)
    }
    private func addTextView(overlay: TextViewEditingOverlay) {
        view.addSubview(overlay)
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
