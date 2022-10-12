//
//  GalleryViewController.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 12/10/2022.
//

import UIKit
import Photos

// TODO: Support observation of changes and insertion of saved medias
final class GalleryViewController: UIViewController {
    private var images: [UIImage?] = []
    private var collection: UICollectionView!
    
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
        setupCollection()
        fetchPhotos()
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
        
        view.addSubview(collectionView)
        collectionView.pinEdges(to: view)
        collectionView.backgroundColor = .black
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: ImageCell.reuseId)
    }
    
    private func fetchPhotos() {
        images = .init(repeating: nil, count: allPhotos.count)
        reload()
    }
    
    private func reload() {
        collection.reloadData()
    }
}

extension GalleryViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageCell.reuseId, for: indexPath) as? ImageCell else {
            return UICollectionViewCell()
        }
        if let image = images[indexPath.item] {
            cell.configure(image: image)
        } else {
            cell.configure(index: indexPath.item, photos: allPhotos) { [weak self] image in
                if self?.images[indexPath.item] == nil {
                    self?.images[indexPath.item] = image
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let image = images[indexPath.item] else { return }
        let edit = EditVC()
        edit.media = .image(img: image)
        edit.modalPresentationStyle = .fullScreen
        present(edit, animated: true)
    }
}

