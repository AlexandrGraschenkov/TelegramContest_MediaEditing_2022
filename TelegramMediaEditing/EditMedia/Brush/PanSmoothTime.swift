//
//  PanSmoothTime.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 15.10.2022.
//

import UIKit

class PanSmoothTime {
    var skipTime: Double = 0.2
    fileprivate(set) var points: [PanPoint] = []
    
    func start() {
        points.removeAll()
    }
    
    func end() {
        
    }
    
    func update(point: PanPoint) {
//        if points.count > 1 && points[points.count-1].time - points[points.count-2].time < skipTime {
//            _ = points.popLast()
//        }
        points.append(point)
    }
}
