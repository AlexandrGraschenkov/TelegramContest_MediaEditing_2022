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
    var history = History()
    var layerContainer = LayerContainer()
    var nav: EditNavBar!
    weak var colorContentPicker: ColorContentPicker? // destroys by itself
    lazy var pen: PenDrawer = {
        let pen = PenDrawer()
        pen.setup(content: mediaContainer, history: history)
        return pen
    }()
    lazy var marker: MarkerDrawer = {
        let marker = MarkerDrawer()
        marker.setup(content: mediaContainer, history: history)
        return marker
    }()
    lazy var neon: NeonDrawer = {
        let neon = NeonDrawer()
        neon.setup(content: mediaContainer, history: history)
        return neon
    }()
    lazy var pencil: PencilDrawer = {
        let pencil = PencilDrawer()
        pencil.setup(content: mediaContainer, history: history)
        return pencil
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        } else {
            // Don't care
        }
        assert(asset != nil)
        setupMediaContainer()
        setupUI()
        pen.active = true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate func setupUI() {
        view.backgroundColor = .black
        scroll = ZoomScrollView(frame: view.bounds)
        scroll.translatesAutoresizingMaskIntoConstraints = true
        scroll.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scroll)
        scroll.setup(content: mediaContainer)
        
        toolbar = EditorToolbar.createAndAdd(toView: view)
        toolbar.actionHandler = { [unowned self] action in
            switch action {
            case .toolChanged(let type):
                self.pen.active = type == .pen
                self.marker.active = type == .marker
                self.neon.active = type == .neon
                self.pencil.active = type == .pencil
            case .colorChange(let color):
                if self.pen.active {
                    self.pen.color = color
                }
                if self.marker.active {
                    self.marker.color = color
                }
                if self.neon.active {
                    self.neon.color = color
                }
                if self.pencil.active {
                    self.pencil.color = color
                }
            case .lineWidthChanged(let width):
                if self.pen.active {
                    self.pen.toolSize = width
                }
                if self.marker.active {
                    self.marker.toolSize = width
                }
                if self.neon.active {
                    self.neon.toolSize = width
                }
                if self.pencil.active {
                    self.pencil.toolSize = width
                }
            case .openColorPicker(startColor: let startColor):
                self.openColorPicker(startColor: startColor)
            case .textEditBegan(let overlay):
                self.addTextView(overlay: overlay)
            case .textEditEnded(let result):
                self.view.addSubview(result.view)
                result.view.frame = self.view.convert(result.frameInWindow, from: view.window)
            case .close:
                dismiss(animated: true)
            default:
                // TODO:
                break
            }
        }
        
        layerContainer.mediaView = mediaContainer
        nav = EditNavBar.createAndAdd(toView: view)
        history.connect(forwardButton: nav.forward, backwardButton: nav.backward, clearAllButton: nav.clearAll)
        history.setup(container: layerContainer)
        
        setupZoomOutUI()
    }
    
    fileprivate func setupZoomOutUI() {
        scroll.onZoom = { [weak self] zoom in
            guard let self = self else { return }
            let contentSize = self.mediaContainer.bounds.size.mulitply(zoom)
            let scrollSize = self.scroll.bounds.size
            let zoomOutEnabled = contentSize.width > scrollSize.width && contentSize.height > scrollSize.height
            self.nav.setZoomOut(enabled: zoomOutEnabled, animated: true)
        }
        nav.setZoomOut(enabled: false, animated: false)
        nav.zoomOut.addTarget(scroll, action: #selector(ZoomScrollView.zoomOut), for: .touchUpInside)
    }

    
    private func openColorPicker(startColor: UIColor) {
        let picker = ColorPickerVC()
        picker.color = startColor
        let onColorUpdate: (UIColor)->() = { [weak self] color in
            guard let self = self else { return }
            self.toolbar.colorChangeOutside(color: color)
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
