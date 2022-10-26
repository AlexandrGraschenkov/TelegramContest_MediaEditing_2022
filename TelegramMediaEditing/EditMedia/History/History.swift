//
//  History.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 26.10.2022.
//

import UIKit


class History {
    private(set) var layerContainer: LayerContainer?
    private(set) var elems: [ElementGroup] = []
    private(set) var currentIdx: Int = 0
    
    var forwardEnabled: Bool { currentIdx < elems.count }
    var backwardEnabled: Bool { currentIdx > 0 }
    
    func setup(container: LayerContainer) {
        self.layerContainer = container
    }
    
    func connect(forwardButton: UIButton, backwardButton: UIButton, clearAllButton: UIButton) {
        self.forwardButton = forwardButton
        self.backwardButton = backwardButton
        self.clearAllButton = clearAllButton
        
        forwardButton.addTarget(self, action: #selector(forward), for: .touchUpInside)
        backwardButton.addTarget(self, action: #selector(backward), for: .touchUpInside)
        clearAllButton.addTarget(self, action: #selector(clearAll), for: .touchUpInside)
        historyUpdated(animated: false)
    }
    
    func add(element: ElementGroup) {
        while currentIdx < elems.count {
            _ = elems.popLast()
        }
        elems.append(element)
        currentIdx += 1
        historyUpdated(animated: true)
    }
    
    @objc func forward() {
        if !forwardEnabled { return }
        for elem in elems[currentIdx].forward {
            apply(element: elem)
        }
        currentIdx += 1
        historyUpdated(animated: true)
    }
    
    @objc func backward() {
        if !backwardEnabled { return }
        for elem in elems[currentIdx-1].backward {
            apply(element: elem)
        }
        currentIdx -= 1
        historyUpdated(animated: true)
    }
    
    @objc func clearAll() {
        if !backwardEnabled { return }
        guard let layerContainer = layerContainer else { return }
        
        elems.removeAll()
        for (_, l) in layerContainer.layers {
            l.removeFromSuperlayer()
        }
        for (_, v) in layerContainer.views {
            v.removeFromSuperview()
        }
        currentIdx = 0
        historyUpdated(animated: true)
    }
    
    // MARK: - private
    private weak var forwardButton: UIButton?
    private weak var backwardButton: UIButton?
    private weak var clearAllButton: UIButton?
    
    private func historyUpdated(animated: Bool) {
        if forwardButton?.isEnabled != forwardEnabled {
            forwardButton?.isEnabled = forwardEnabled
            if animated {
                forwardButton?.fadeAnimation(duration: 0.2)
            }
        }
        if backwardButton?.isEnabled != backwardEnabled {
            backwardButton?.isEnabled = backwardEnabled
            if animated {
                backwardButton?.fadeAnimation(duration: 0.2)
            }
        }
        
        if clearAllButton?.isEnabled != (currentIdx > 0) {
            clearAllButton?.isEnabled = currentIdx > 0
            if animated {
                clearAllButton?.fadeAnimation(duration: 0.2)
            }
        }
    }
    
    private func apply(element: Element) {
        guard let layers = layerContainer, let mediaView = layers.mediaView else {
            assert(false, "Don't forget initalize all values in `setup(container:)`")
            return
        }
        
        switch element.action {
        case .add(classType: let classType):
            if let layerClass = classType as? CALayer.Type {
                let layer = layerClass.init()
                layers.layers[element.objectId] = layer
                mediaView.layer.addSublayer(layer)
            } else if let viewClass = classType as? UIView.Type {
                let view = viewClass.init()
                layers.views[element.objectId] = view
                mediaView.addSubview(view)
            } else {
                assert(false, "Don't know what to do with '\(classType)' class. Expect UIView or CALayer")
            }
            
        case .remove:
            if let view = layers.views[element.objectId] {
                view.removeFromSuperview()
                layers.views.removeValue(forKey: element.objectId)
            } else if let layer = layers.layers[element.objectId] {
                layer.removeFromSuperlayer()
                layers.layers.removeValue(forKey: element.objectId)
            } else {
                assert(false, "Can't find \(element.objectId) in collection")
            }
            // we don't modify any properties, just remove
            return
            
        case .update:
            break // no update in hierarhy, continue
        }
        
        
        // Apply changes for view/layer
        if let zIndex = element.zIndex {
            if let v = layers.views[element.objectId] {
                v.removeFromSuperview()
                mediaView.insertSubview(v, at: zIndex)
            } else if let l = layers.layers[element.objectId] {
                l.removeFromSuperlayer()
                mediaView.layer.insertSublayer(l, at: UInt32(zIndex))
            } else {
                assert(false, "Can't find \(element.objectId) in collection")
            }
        }
        
        guard let obj: NSObject = layers.views[element.objectId] ?? layers.layers[element.objectId] else {
            assert(false, "Can't find \(element.objectId) in collection")
            return
        }
        
        for (key, val) in element.updateKeys ?? [:] {
            obj.setValue(val, forKeyPath: key)
        }
        element.closure?(element, layers)
    }
    
    
    // --------------------------------------------------------------------------
    // MARK: - History Element
    struct ElementGroup {
        var forward: [Element] // array for multiple actions (ex: eraser delete multiple objects)
        var backward: [Element]
    }
    struct Element {
        init(objectId: String, action: History.Element.LayerAction, zIndex: Int? = nil, closure: ((Element, LayerContainer) -> ())? = nil, updateKeys: [String : Any]? = nil, backgroundFill: UIColor? = nil) {
            self.objectId = objectId
            self.action = action
            self.zIndex = zIndex
            self.closure = closure
            self.updateKeys = updateKeys
            self.backgroundFill = backgroundFill
        }
        
        enum LayerAction {
            case add(classType: AnyClass), remove, update
        }
        
        let objectId: String
        let action: LayerAction
        
        var zIndex: Int?
        var closure: ((Element, LayerContainer)->())?
        var updateKeys: [String: Any?]?
        
        var backgroundFill: UIColor? // TODO: don't forget implement it
    }
}
