//
//  TestVC.swift
//  TelegramMediaEditing
//
//  Created by Azat Zulkarniaev on 15/10/2022.
//

import UIKit

final class TestViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
                
        let toolbar = EditorToolbar(frame: CGRect(x: 0, y: view.bounds.height - 196, width: view.bounds.width, height: 196))
        toolbar.translatesAutoresizingMaskIntoConstraints = true
        toolbar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        view.addSubview(toolbar)
        toolbar.actionHandler = { action in
            print("Toolbar did trigger action \(action)")
        }
    }
}

extension UIApplication {
    var tm_keyWindow: UIWindow {
        return delegate!.window!!
    }
}
