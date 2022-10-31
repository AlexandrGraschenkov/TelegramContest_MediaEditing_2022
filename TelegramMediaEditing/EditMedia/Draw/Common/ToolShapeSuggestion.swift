//
//  ToolShapeSuggestion.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 31.10.2022.
//

import UIKit

class ToolShapeSuggestion {
    
    var onShape: ((UIBezierPath?)->())?
    
    func onPanClassify(_ pan: UIPanGestureRecognizer, drawPath: [PanPoint]) {
        lastPoints = drawPath
        let p = pan.location(in: pan.view?.window)
        // just for handle how far finger is moving
        
        switch pan.state {
        case .began:
            lastClassifyPanPoint = p
            
        case .changed:
            let dist = p.distance(p: lastClassifyPanPoint!)
            if dist > 8 {
                cancelProcessSuggestion?()
                lastClassifyPanPoint = p
                classifyTimerTrigger?.invalidate()
                classifyTimerTrigger = nil
                if suggestedPath != nil {
                    suggestedPath = nil
                    onShape?(nil)
                }
            }
            
            if drawPath.count > minPointsCount, classifyTimerTrigger == nil {
                classifyTimerTrigger = Timer(timeInterval: 0.6, target: self, selector: #selector(triggerShapeClassify), userInfo: nil, repeats: false)
                RunLoop.current.add(classifyTimerTrigger!, forMode: .common)
            }
            
        case .ended, .cancelled, .failed:
            classifyTimerTrigger?.invalidate()
            classifyTimerTrigger = nil
            lastClassifyPanPoint = nil
            suggestedPath = nil
            cancelProcessSuggestion?()
            
        default:
            break
        }
    }
    
    // MARK: fileprivate
    fileprivate var lastClassifyPanPoint: CGPoint? // in window coordinates
    fileprivate var classifyTimerTrigger: Timer?
    fileprivate var suggestedPath: UIBezierPath?
    fileprivate var cancelProcessSuggestion: Cancelable?
    fileprivate var lastPoints: [PanPoint] = []
    fileprivate let minPointsCount = 15
    fileprivate let maxPointsCount = 1000
    @objc
    private func triggerShapeClassify() {
        cancelProcessSuggestion = classifyShape {[weak self] path in
            if self?.suggestedPath == nil && path == nil { return }
            self?.suggestedPath = path
            self?.onShape?(path)
        }
    }
    
    var processing: Bool = false
    private func classifyShape(completion: @escaping (UIBezierPath?)->()) -> Cancelable {
        if lastPoints.count < minPointsCount || lastPoints.count > maxPointsCount {
            completion(nil)
            return {}
        }
        
        if processing {
            print("WTF")
        }
        processing = true
        var canceled = false
        let points = lastPoints.map { $0.point }
        performInBackground {
            let shape = ShapeClassifier.shared.detect(points: points)
            if canceled {
                self.processing = false
                return
            }
            let path = shape?.generate()
            performInMain {
                self.processing = false
                if canceled { return }
                completion(path)
            }
        }
        
        return { canceled = true }
    }
}
