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
    var tools: [ToolType: ToolDrawer] = [:]
    var activeTool: ToolType = .pen
    
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
        
        // Setup default active tool properties
        activateTool(type: activeTool)
        tools[activeTool]!.toolSize = ToolDefaults.getSize(type: activeTool)
        tools[activeTool]!.color = ToolDefaults.getColor(type: activeTool) ?? .white
        toolbar.colorChangeOutside(color: tools[activeTool]!.color)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    fileprivate func activateTool(type toolType: ToolType) {
        activeTool = toolType
        
        if tools[toolType] == nil {
            if let t = ToolDrawer.generate(toolType: toolType) {
                t.setup(content: mediaContainer, history: history)
                tools[toolType] = t
            }
        }
        
        for (_, tool) in tools {
            tool.active = (toolType == tool.toolType)
        }
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
                self.activateTool(type: type)
                
            case .colorChange(let color):
                self.tools[self.activeTool]?.color = color
                ToolDefaults.set(color: color, type: activeTool)
                
            case .lineWidthChanged(let width):
                self.tools[self.activeTool]?.toolSize = width
                ToolDefaults.set(size: width, type: activeTool)
                
            case .toolShapeChanged(let toolShape):
                self.tools[self.activeTool]?.toolShape = toolShape
                
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
            let contentSize = self.mediaContainer.bounds.size.multiply(zoom)
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

private extension ToolDrawer {
    static func generate(toolType: ToolType) -> ToolDrawer? {
        switch toolType {
        case .pen: return PenDrawer()
        case .marker: return MarkerDrawer()
        case .neon: return NeonDrawer()
        case .pencil: return PencilDrawer()
        case .lasso: return nil
        case .eraser: return EraserDrawer()
        case .objectEraser: return nil
        case .blurEraser: return nil
        }
    }
}
