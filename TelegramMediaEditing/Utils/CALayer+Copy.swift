//
//  CALayer+Copy.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 31.10.2022.
//

import UIKit


extension CAShapeLayer {
    override func customCopy() -> CAShapeLayer {
        let res = CAShapeLayer()
        res.opacity = opacity
        res.fillColor = fillColor
        res.strokeColor = strokeColor
        res.lineWidth = lineWidth
        res.lineCap = .round
        res.lineJoin = .round
        res.transform = transform
        res.shadowColor = shadowColor
        res.shadowOffset = shadowOffset
        res.shadowRadius = shadowRadius
        res.shadowOpacity = shadowOpacity
        return res
    }
}

extension CALayer {
    @objc func customCopy() -> CALayer {
        let res = CALayer()
        res.opacity = opacity
        res.transform = transform
        res.shadowColor = shadowColor
        res.shadowOffset = shadowOffset
        res.shadowRadius = shadowRadius
        res.shadowOpacity = shadowOpacity
        return res
    }
    
    func apply(keys: [String: Any?]) {
        for (key, val) in keys {
            setValue(val, forKey: key)
        }
    }
    
    func getKeys(override: [String: Any?]? = nil) -> [String: Any?] {
        var res: [String: Any?] = [:]
        res["opacity"] = opacity
        res["transform"] = transform
        res["shadowColor"] = shadowColor
        res["shadowOffset"] = shadowOffset
        res["shadowRadius"] = shadowRadius
        res["shadowOpacity"] = shadowOpacity
        res["frame"] = frame
        res["contents"] = contents
        
        if let shape = self as? CAShapeLayer {
            res["path"] = shape.path
            res["fillColor"] = shape.fillColor
            res["strokeColor"] = shape.strokeColor
            res["lineWidth"] = shape.lineWidth
            res["lineJoin"] = shape.lineJoin
            res["lineCap"] = shape.lineCap
        }
        if let rep = self as? CAReplicatorLayer {
            res["instanceCount"] = rep.instanceCount
            res["instanceTransform"] = rep.instanceTransform
        }
        for (k, v) in override ?? [:] {
            res[k] = v
        }
        
        return res
    }
}


