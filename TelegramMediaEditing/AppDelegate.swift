//
//  AppDelegate.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 11.10.2022.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window?.rootViewController = GalleryViewController()//TestViewController()
        window?.makeKeyAndVisible()
        return true
    }

}

