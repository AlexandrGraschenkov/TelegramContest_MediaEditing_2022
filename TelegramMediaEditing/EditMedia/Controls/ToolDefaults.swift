//
//  ToolDefaults.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 28.10.2022.
//

import UIKit

class ToolDefaults {
    static func getSize(type: ToolType) -> CGFloat {
        let size = UserDefaults.standard.float(forKey: type.rawValue+"_size")
        if size > 0 {
            return CGFloat(size)
        }
        
        // default values
        switch type {
        case .pen: return 4
        case .marker: return 8
        case .neon: return 12
        case .pencil: return 7
        case .lasso: return 1
        case .eraser: return 12
        case .objectEraser: return 12
        case .blurEraser: return 12
        }
    }
    
    static func getColor(type: ToolType) -> UIColor? {
        if let color = UserDefaults.standard.color(forKey: type.rawValue+"_color") {
            return color
        }
        
        // default values
        switch type {
        case .pen: return .white
        case .marker: return UIColor(red: 255, green: 230, blue: 32, a: 1)
        case .neon: return UIColor(red: 50, green: 254, blue: 186, a: 1)
        case .pencil: return UIColor(red: 45, green: 136, blue: 243, a: 1)
        default: return nil
        }
    }
    
    static func set(size: CGFloat, type: ToolType) {
        UserDefaults.standard.set(Float(size), forKey: type.rawValue+"_size")
        UserDefaults.standard.synchronize()
    }
    
    static func set(color: UIColor, type: ToolType) {
        UserDefaults.standard.set(color, forKey: type.rawValue+"_color")
        UserDefaults.standard.synchronize()
    }
}

fileprivate extension UserDefaults {
    func set(_ color: UIColor?, forKey defaultName: String) {
        guard let comp = color?.components else {
            removeObject(forKey: defaultName)
            return
        }
        set([comp.r, comp.g, comp.b, comp.a], forKey: defaultName)
    }
    
    func color(forKey defaultName: String) -> UIColor? {
        if let arr = object(forKey: defaultName) as? [CGFloat], arr.count == 4 {
            return UIColor(red: arr[0], green: arr[1], blue: arr[2], alpha: arr[3])
        }
        return nil
    }
}
