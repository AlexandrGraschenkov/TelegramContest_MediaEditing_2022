//
//  LayerContainer.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 26.10.2022.
//

import UIKit

class LayerContainer {
    var layers: [String: CALayer] = [:]
    var views: [String: UIView] = [:] // for handle UIView manually
    var mediaView: UIView?
    
    func generateUniqueName(prefix: String? = nil) -> String { // use prefix to distinguish object type
        generatedCount += 1
        return (prefix ?? "") + "_id_\(generatedCount)"
//        var name: String
//        repeat {
//            name = (prefix ?? "") + "_" + .random(length: 5)
//        } while (usedNames.contains(name))
//        usedNames.insert(name)
//        return name
    }
    
    /// to generate unique names during launch
    fileprivate var generatedCount: Int = 0
//    fileprivate var usedNames: Set<String> = .init()
}
