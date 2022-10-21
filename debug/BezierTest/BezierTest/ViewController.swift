//
//  ViewController.swift
//  BezierTest
//
//  Created by Alexander Graschenkov on 17.10.2022.
//

import UIKit

class ViewController: UIViewController {

    var movePointIdx: Int?
    var prevPoint: CGPoint?
    @IBOutlet weak var bezierView: ManualBezierView!
    @IBOutlet weak var offset1Slider: UISlider!
    @IBOutlet weak var offset2Slider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        bezierView.addGestureRecognizer(pan)
    }

    @objc func onPan(_ pan: UIPanGestureRecognizer) {
        let p = pan.location(in: pan.view)
        defer {
            prevPoint = p
        }
        switch pan.state {
        case .began:
            let dists = bezierView.points.map({$0.distance(p: p)})
            let (minIdx, minDist) = dists.enumerated().min(by: {$0.element < $1.element})!
            if minDist < 40 {
                movePointIdx = minIdx
            } else {
                movePointIdx = nil
            }
            
        default:
            guard let idx = movePointIdx, let prev = prevPoint else {
                return
            }
            bezierView.points[idx] = bezierView.points[idx].add(p.substract(prev))
        }
    }
    
    @IBAction func onOffsetChange(_ slider: UISlider) {
        if slider == offset1Slider {
            bezierView.offset1 = CGFloat(slider.value)
        } else {
            bezierView.offset2 = CGFloat(slider.value)
        }
    }
    
    @IBAction func optimizedVersionChanged(_ control: UISegmentedControl) {
        bezierView.algo = ManualBezierView.Algo(rawValue: control.selectedSegmentIndex)!
    }
    
    @IBAction func drawPointsChanged(_ control: UISwitch) {
        bezierView.drawPoints = control.isOn
    }
    @IBAction func drawResultChanged(_ control: UISwitch) {
        bezierView.drawResult = control.isOn
    }
}

