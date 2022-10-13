//
//  PHPhotoLibrary+Ex.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 11.10.2022.
//

import UIKit
import Photos

extension UIApplication {
    public static func openSettings(onReturnToApplication: (()->())? = nil) {
        if let completion = onReturnToApplication {
            
            var token: NSObjectProtocol?
            token = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification,
                                                           object: nil,
                                                           queue: OperationQueue.main,
                                                           using: { (_) in
                if let token = token {
                    NotificationCenter.default.removeObserver(token)
                }
                completion()
            })
        }
        UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
    }
}

public extension PHPhotoLibrary {
    
    static var accessAllowed: Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    static var accessDenied: Bool {
        return PHPhotoLibrary.authorizationStatus() == .denied
    }
    
    static var accessUndefined: Bool {
        return PHPhotoLibrary.authorizationStatus() == .notDetermined
    }
    
    static func requestAccess(completion: ((Bool)->())? = nil) {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .denied, .restricted:
            completion?(false)
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                let success = (newStatus == PHAuthorizationStatus.authorized)
                performInMain {
                    completion?(success)
                }
            })
        
        case .authorized, .limited:
            completion?(true)
            
        default:
            break;
        }
    }
}

