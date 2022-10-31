//
//  GalleryViewController.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 12/10/2022.
//

import UIKit
import Photos

struct LoadedImageInfo {
    let image: UIImage?
    let isFullyLoaded: Bool
}

// TODO: Support observation of changes and insertion of saved medias
final class GalleryViewController: UIViewController {
    private var collection: UICollectionView!
    private var overlay: PhotoPermissionOverlay?
    private var imagesCache: [String: LoadedImageInfo] = [:]
    private let imageManager = PHImageManager.default()
    private var selectedIndexPath: IndexPath?
    private var transitionController: ImageDetailTransitionController?

    
    private static func generateResults() -> PHFetchResult<PHAsset> {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate",ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        
        return PHAsset.fetchAssets(with: fetchOptions)
    }
    
    private lazy var allPhotos: PHFetchResult<PHAsset> = Self.generateResults()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .dark
        } else {
            // Don't care
        }
        
        view.backgroundColor = .black
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            showPhotos()
        } else {
            insertOverlayIfNeeded()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        overlay?.startAnimation()
    }
    
    private func setupCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let side = floor(UIScreen.main.bounds.width / 3)
        layout.itemSize = CGSize(width: side, height: side)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collection = collectionView
        
        if let overlay = overlay {
            view.insertSubview(collection, belowSubview: overlay)
        } else {
            view.addSubview(collectionView)
        }
        collectionView.frame = view.bounds
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .black
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseId)
        
        let safeArea = UIApplication.shared.tm_keyWindow.safeAreaInsets
        let topContainer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: safeArea.top + 20))
        topContainer.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        
        let blur = UIVisualEffectView(frame: topContainer.bounds)
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blur.effect = UIBlurEffect(style: .regular)
        topContainer.addSubview(blur)
        
        let gradientView = GradientView(frame: topContainer.bounds)
        gradientView.colors = [.black, .clear]
        topContainer.layer.mask = gradientView.layer
        
        view.addSubview(topContainer)
    }
    
    private func insertOverlayIfNeeded() {
        let overlay = PhotoPermissionOverlay()
        view.addSubview(overlay)
        overlay.pinEdges(to: view)
        overlay.onPermissionGranted = { [weak overlay, weak self] in
            overlay?.dismiss {
                overlay?.removeFromSuperview()
            }
            self?.showPhotos()
        }
        overlay.onNavigationIntent = { [weak self] viewController in
            self?.present(viewController, animated: true)
        }
        self.overlay = overlay
    }
    
    private func showPhotos() {
        PHPhotoLibrary.shared().register(self)
        setupCollection()
        collection?.reloadData()
    }
}

extension GalleryViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        allPhotos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseId, for: indexPath) as? ImageCell else {
            return UICollectionViewCell()
        }
        let asset = allPhotos[indexPath.item]
        cell.assetId = asset.localIdentifier
        
        let cached = imagesCache[asset.localIdentifier]
        
        if let image = cached?.image {
            configureCell(cell, preview: image, asset: asset)
        }
        if cached?.isFullyLoaded != true {
            let side = floor(UIScreen.main.bounds.width / 3) * UIScreen.main.scale
            let imageSize = CGSize(width: side, height: side)
            let loadCancel = imageManager.fetchPreview(asset: asset, size: imageSize) { [weak self] image, isFullyLoaded in
                guard let self = self, cell.assetId == asset.localIdentifier else { return }
                self.imagesCache[asset.localIdentifier] = .init(image: image, isFullyLoaded: isFullyLoaded)
                self.configureCell(cell, preview: image, asset: asset)
            }
            cell.onReuse = loadCancel
        }
        return cell
    }
    
    private func configureCell(_ cell: ImageCell, preview: UIImage?, asset: PHAsset) {
        switch asset.mediaType {
        case .image:
            cell.configure(content: .image(preview))
        case .video:
            cell.configure(content: .video(preview, asset.duration))
        case .unknown,  .audio:
            break
        @unknown default:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = allPhotos[indexPath.item]
        guard asset.mediaType == .image else {
            let alert = UIAlertController(title: "Not Supported Yet", message: "Sorry, only images supported for now", preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default, handler: nil))
            present(alert, animated: true)
            return
        }
        selectedIndexPath = indexPath
        
        let edit = EditVC()
        let transitionController = ImageDetailTransitionController()
        transitionController.fromDelegate = self
        transitionController.toDelegate = edit
        edit.modalPresentationStyle = .custom
        edit.transitioningDelegate = transitionController
        edit.cacheImg = imagesCache[asset.localIdentifier]?.image
        edit.asset = asset
        self.transitionController = transitionController
//        edit.modalPresentationStyle = .fullScreen
        present(edit, animated: true)
    }
    
    private var defaultImage: UIImageView {
        UIImageView(frame: CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 100.0, height: 100.0))
    }
    
    private func getCell(for indexPath: IndexPath) -> ImageCell? {
        let visibleCells = collection.indexPathsForVisibleItems
        
        if !visibleCells.contains(indexPath) {
            collection.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
            collection.reloadItems(at: collection.indexPathsForVisibleItems)
            collection.layoutIfNeeded()
            return collection.cellForItem(at: indexPath) as? ImageCell
        } else {
            return collection.cellForItem(at: indexPath) as? ImageCell
        }
    }

    private func getImageViewFromCollectionViewCell(for indexPath: IndexPath) -> UIImageView {
        getCell(for: indexPath)?.imageView ?? defaultImage
    }
    
    func getFrameFromCollectionViewCell(for indexPath: IndexPath) -> CGRect {
        let defaultFrame = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 100.0, height: 100.0)
        return getCell(for: indexPath)?.frame ?? defaultFrame
    }
}

extension GalleryViewController: PHPhotoLibraryChangeObserver {
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        allPhotos = Self.generateResults()
        DispatchQueue.main.async {
            self.collection.reloadData()
        }
    }
}

extension GalleryViewController: ImageDetailAnimatorDelegate {
    
    func transitionWillStartWith(imageDetailAnimator: ImageDetailAnimator) {}
    
    func transitionDidEndWith(imageDetailAnimator: ImageDetailAnimator) {
        guard let indexPath = selectedIndexPath else { return }
        let cell = collection.cellForItem(at: indexPath) as! ImageCell
        
        let cellFrame = collection.convert(cell.frame, to: self.view)
        
        if cellFrame.minY < collection.contentInset.top {
            collection.scrollToItem(at: indexPath, at: .top, animated: false)
        } else if cellFrame.maxY > self.view.frame.height - collection.contentInset.bottom {
            collection.scrollToItem(at: indexPath, at: .bottom, animated: false)
        }
    }
    
    func referenceImageView(for imageDetailAnimator: ImageDetailAnimator) -> UIImageView? {
        guard let indexPath = selectedIndexPath else { return nil }
        let referenceImageView = getImageViewFromCollectionViewCell(for: indexPath)
        return referenceImageView
    }
    
    func referenceImageViewFrameInTransitioningView(for imageDetailAnimator: ImageDetailAnimator) -> CGRect? {
        guard let selectedIndexPath = selectedIndexPath else { return nil }

        let unconvertedFrame = getFrameFromCollectionViewCell(for: selectedIndexPath)
        
        let cellFrame = collection.convert(unconvertedFrame, to: self.view)
        
        if cellFrame.minY < collection.contentInset.top {
            return CGRect(
                x: cellFrame.minX,
                y: collection.contentInset.top,
                width: cellFrame.width,
                height: cellFrame.height - (collection.contentInset.top - cellFrame.minY)
            )
        }
        
        return cellFrame
    }
    
}
