//
//  ImageCell.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 12/10/2022.
//

import UIKit
import Photos

typealias ImageCompletion = (UIImage) -> Void

final class ImageCell: UICollectionViewCell {
    static let reuseId = "ImageCell"
    
    private var imageView: UIImageView!
    private var lastFetchToken: Int?
//    private let fetchService = AssetPreviewFetcher()
    private var lastRequestId: PHImageRequestID?

    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        let imageView = UIImageView()
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        self.imageView = imageView
        contentView.addSubview(imageView)
        imageView.pinEdges(to: contentView)
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        if let lastRequestId = lastRequestId {
            PHImageManager.default().cancelImageRequest(lastRequestId)
        }
        self.lastRequestId = nil
    }
    
    func configure(index: Int, photos: PHFetchResult<PHAsset>, completion: @escaping ImageCompletion) {
        let imageManager = PHImageManager.default()
        let targetSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        
        
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = photos.object(at: index)
            var requestId: PHImageRequestID?
            requestId = imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options,
                resultHandler: { [weak self] (image, info) in
                    guard let image = image else { return }
                    DispatchQueue.main.async {
                        if requestId == self?.lastRequestId {
                            self?.imageView.image = image
                        }
                        if let flag = info?[PHImageResultIsDegradedKey] as? NSNumber, flag.boolValue == false {
                            completion(image)
                        }
                    }
                }
            )
            self.lastRequestId = requestId
        }
    }

    func configure(image: UIImage) {
        imageView.image = image
    }
}

//final class AssetPreviewFetcher {
//    private static let queue = DispatchQueue(label: "com.telegram.mi", qos: .userInitiated, attributes: .concurrent)
//    let imageManager = PHImageManager.default()
//    let targetSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
//
//    func fetchPreview(for asset: PHAsset, tokenCallback: @escaping (Int?) -> Void, loadCallback: @escaping (UIImage?, Bool, Int?) -> Void) {
//        DispatchQueue.global(qos: .userInitiated).async {
//            var requestId: PHImageRequestID?
//            requestId = self.imageManager.requestImage(
//                for: asset,
//                targetSize: self.targetSize,
//                contentMode: .aspectFill,
//                options: .init(),
//                resultHandler: { (image, info) in
//                    guard let image = image else { return }
//                    DispatchQueue.main.async {
//                        loadCallback(image, (info?[PHImageResultIsDegradedKey] as? NSNumber)?.boolValue == false, requestId.flatMap(Int.init))
//                    }
//                }
//            )
//            tokenCallback(requestId.flatMap(Int.init))
//        }
//    }
//
//    func cancelLoad(token: Int?) {
//        guard let requestId = token.flatMap(Int32.init) else {
//            return
//        }
//        imageManager.cancelImageRequest(requestId)
//    }
//}
