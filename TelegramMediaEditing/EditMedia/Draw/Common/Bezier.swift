//
//  BezierHelper.swift
//  TelegramMediaEditing
//
//  Created by Alexander Graschenkov on 27.10.2022.
//

import UIKit

struct Bezier {
    let from: CGPoint
    let to: CGPoint
    let control: CGPoint
    
    func generateNormals(tArr: [CGFloat], toRight: Bool) -> [CGPoint] {
        // based on https://pomax.github.io/bezierinfo/chapters/pointvectors/pointvectors.js
        // https://pomax.github.io/bezierinfo/#pointvectors
        let d0 = CGPoint(x: 2 * (control.x - from.x), y: 2 * (control.y - from.y))
        let d1 = CGPoint(x: 2 * (to.x - control.x), y: 2 * (to.y - control.y))
        var normalArr: [CGPoint] = []
        normalArr.reserveCapacity(tArr.count)
        for t in tArr {
            let mt = (1 - t)
            let d = CGPoint(x: mt * d0.x + t * d1.x,
                            y: mt * d0.y + t * d1.y)
            
            let q = sqrt(d.x * d.x + d.y * d.y)
            let normal: CGPoint
            if q == 0 {
                let n = to.substract(from).norm
                normal = toRight ? n.rot90 : n.rot270
            } else if toRight {
                normal = CGPoint(x: d.y / q, y: -d.x / q)
            } else {
                normal = CGPoint(x: -d.y / q, y: d.x / q)
            }
            normalArr.append(normal)
        }
        return normalArr
    }
    
    func getPoint(t: CGFloat) -> CGPoint {
        let t1 = pow(1 - t, 2)
        let t2 = 2.0 * (1 - t) * t
        let t3 = pow(t, 2)
        let p = from.multiply(t1).add(control.multiply(t2)).add(to.multiply(t3))
        return p
    }
    
    func closestTtoControlSimple() -> CGFloat {
        /// FAST NOT SAME BUT SIMILAR
        let d1 = from.distance(p: control)
        let d2 = to.distance(p: control)
        if (d1+d2>0) {
            return d1/(d1+d2)
        } else {
            return 0.5
        }
    }
    
    func closestTtoControl() -> CGFloat {
        // implementation took from here
        // https://github.com/microbians/bezier/blob/main/sktch/math/bezier.js#L34
        // math behind
        // https://microbians.com/math/Gabriel_Suchowolski_Quadratic_bezier_offsetting_with_selective_subdivision.pdf
        var tToReturn: CGFloat = 0.5
        let v0 = control.substract(from)
        let v1 = to.substract(control)
        
        let c0 = -v0.dot(v0)
        let c1 = 3*v0.dot(v0)-v1.dot(v0)
        let c2 = 3*(v1.dot(v0)-v0.dot(v0))
        let c3 = (v1.substract(v0)).dot(v1.substract(v0))
        
        var roots: [CGFloat] = []
        
        let a1 = c2 / c3
        let a2 = c1 / c3
        let a3 = c0 / c3
        
        let Q = (a1 * a1 - 3 * a2) / 9
        let R = (2 * a1 * a1 * a1 - 9 * a1 * a2 + 27 * a3) / 54
        let Qcubed = Q * Q * Q
        let d = Qcubed - R * R
        
        // Three real roots
        if (d >= 0) {
            let theta = acos(R / sqrt(Qcubed))
            let sqrtQ = sqrt(Q)
            roots.append(-2 * sqrtQ * cos( theta            / 3) - a1 / 3)
            roots.append(-2 * sqrtQ * cos((theta + 2 * .pi) / 3) - a1 / 3)
            roots.append(-2 * sqrtQ * cos((theta + 4 * .pi) / 3) - a1 / 3)
        }
        
        // One real root
        else {
            var e = pow(sqrt(-d) + abs(R), 1/3)
            if (R>0) { e = -e }
            roots.append((e + Q / e) - a1 / 3.0)
        }
        
        for t in roots {
            if ( 0 <= t && t <= 1 ) {
                if (!t.isNaN) {
                    tToReturn = t
                    break
                } else {
                    let d1 = from.distance(p: control)
                    let d2 = to.distance(p: control)
                    if (d1+d2>0) {
                        tToReturn = d1/(d1+d2)
                        break
                    }
                    else {
                        tToReturn = 0.5
                        break
                    }
                }
            }
        }
        return tToReturn
    }
    
    /*
    private static func cubicSolve(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, threshold: CGFloat = 0.0001) -> [CGFloat] {
        // if not a cubic fall back to quadratic
        if a == 0 { return quadraticSolve(a: b, b: c, c: d) }
        
        var roots: [CGFloat] = []
        
        let a_1 = b/a
        let a_2 = c/a
        let a_3 = d/a
        
        let q = (3*a_2 - pow(a_1, 2))/9
        let r = (9*a_1*a_2 - 27*a_3 - 2*pow(a_1, 3))/54
        
        let s = cbrt(r + sqrt(pow(q, 3)+pow(r, 2)))
        let t = cbrt(r - sqrt(pow(q, 3)+pow(r, 2)))
        
        var d = pow(q, 3) + pow(r, 2) // discriminant
        
        // Check if d is within the zero threshold
        if -threshold < d && d < threshold { d = 0 }
        
        if d > 0 {
            
            let x_1 = s + t - (1/3)*a_1
//            let x_1 = ComplexNumber(s + t - (1/3)*a_1)
//            let x_2 = ComplexNumber(-(1/2)*(s+t) - (1/3)*a_1,  (1/2)*sqrt(3)*(s - t))
//            let x_3 = ComplexNumber(-(1/2)*(s+t) - (1/3)*a_1,  -(1/2)*sqrt(3)*(s - t))
            roots = [x_1]//, x_2, x_3]
            
        } else if d <= 0 {
            
            let theta = acos(r/sqrt(-pow(q, 3)))
            let x_1 = 2*sqrt(-q)*cos((1/3)*theta) - (1/3)*a_1
            let x_2 = 2*sqrt(-q)*cos((1/3)*theta + 2*Double.pi/3) - (1/3)*a_1
            let x_3 = 2*sqrt(-q)*cos((1/3)*theta + 4*Double.pi/3) - (1/3)*a_1
//            let x_1 = ComplexNumber(2*sqrt(-q)*cos((1/3)*theta) - (1/3)*a_1)
//            let x_2 = ComplexNumber(2*sqrt(-q)*cos((1/3)*theta + 2*Double.pi/3) - (1/3)*a_1)
//            let x_3 = ComplexNumber(2*sqrt(-q)*cos((1/3)*theta + 4*Double.pi/3) - (1/3)*a_1)
            roots = [x_1, x_2, x_3]
            
        }
        
        return roots
    }
    
    private static func quadraticSolve(a: CGFloat, b: CGFloat, c: CGFloat, threshold: CGFloat = 0.0001) -> [CGFloat] {
        if a == 0 { return linearSolve(a: b, b: c) }
        
        var roots = [CGFloat]()
        
        var d = pow(b, 2) - 4*a*c // discriminant
        
        // Check if discriminate is within the 0 threshold
        if -threshold < d && d < threshold { d = 0 }
        
        if d > 0 {
            
            let x_1 = CGFloat((-b + sqrt(d))/(2*a))
            let x_2 = CGFloat((-b - sqrt(d))/(2*a))
            roots = [x_1, x_2]
            
        } else if d == 0 {
            
            let x = CGFloat(-b/(2*a))
            roots = [x]
            
        } else if d < 0 {
            
//            let x_1 = ComplexNumber(-b/(2*a), sqrt(-d)/(2*a))
//            let x_2 = ComplexNumber(-b/(2*a), -sqrt(-d)/(2*a))
//            roots = [x_1, x_2]
            
        }
        
        return roots
    }
    
    private static func linearSolve(a: Double, b: Double) -> [CGFloat] {
        if a == 0 {
            return []
        }
        
        return [CGFloat(-b/a)]
    }
     */
}
