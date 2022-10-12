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
    
    private lazy var allPhotos: PHFetchResult<PHAsset> = {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate",ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d || mediaType = %d", PHAssetMediaType.image.rawValue, PHAssetMediaType.video.rawValue)
        
        return PHAsset.fetchAssets(with: fetchOptions)
    }()

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            setupCollection()
            collection.reloadData()
        } else {
            insertOverlayIfNeeded()
        }
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
        collectionView.pinEdges(to: view)
        collectionView.backgroundColor = .black
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseId)
    }
    
    private func insertOverlayIfNeeded() {
        let overlay = PhotoPermissionOverlay()
        view.addSubview(overlay)
        overlay.pinEdges(to: view)
        overlay.onPermissionGranted = { [weak overlay, weak self] in
            overlay?.dismiss {
                overlay?.removeFromSuperview()
            }
            self?.setupCollection()
            self?.collection?.reloadData()
        }
        overlay.onNavigationIntent = { [weak self] viewController in
            self?.present(viewController, animated: true)
        }
        self.overlay = overlay
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
            let side = floor(UIScreen.main.bounds.width / 3)
            let imageSize = CGSize(width: side, height: side)
            let loadCancel = fetchPreviewOfAsset(asset, size: imageSize) { [weak self] image, isFullyLoaded in
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
        guard let image = imagesCache[asset.localIdentifier]?.image else { return }
        let edit = EditVC()
        edit.media = .image(img: image)
        edit.modalPresentationStyle = .fullScreen
        present(edit, animated: true)
    }
    
    private func fetchPreviewOfAsset(
        _ asset: PHAsset,
        size: CGSize,
        completion: @escaping (UIImage?, Bool) -> Void
    ) -> Cancelable {
        let size = size.mulitply(UIScreen.main.scale)
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        
        let id = imageManager.requestImage(for: asset,
                                           targetSize: size,
                                           contentMode: .aspectFill,
                                           options: options,
                                           resultHandler:
                                            { image, info in
            let isDegraded = info?[PHImageResultIsDegradedKey] as? NSNumber
            let isFullyLoadded = isDegraded?.boolValue == false
            completion(image, isFullyLoadded)
        })
        return { [manager = self.imageManager] in manager.cancelImageRequest(id) }
    }
}

