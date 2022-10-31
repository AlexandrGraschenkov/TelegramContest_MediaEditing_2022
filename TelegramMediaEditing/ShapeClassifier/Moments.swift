//
//  Moments.swift
//  BezierHitTest
//
//  Created by Alexander Graschenkov on 31.10.2022.
//

import UIKit

struct Moments {
    init(m00: CGFloat = 0, m10: CGFloat = 0, m01: CGFloat = 0, m20: CGFloat = 0, m11: CGFloat = 0, m02: CGFloat = 0, m30: CGFloat = 0, m21: CGFloat = 0, m12: CGFloat = 0, m03: CGFloat = 0) {
        self.m00 = m00
        self.m10 = m10
        self.m01 = m01
        self.m20 = m20
        self.m11 = m11
        self.m02 = m02
        self.m30 = m30
        self.m21 = m21
        self.m12 = m12
        self.m03 = m03
    }
    
    var m00, m10, m01, m20, m11, m02, m30, m21, m12, m03: CGFloat
    
    static func calculate(points: [CGPoint]) -> Moments {
        if points.isEmpty {
            return Moments()
        }
        let lpt = points.count
        var m = Moments()
        var xi, yi, xi2, yi2, xi_1, yi_1, xi_12, yi_12, dxy, xii_1, yii_1: CGFloat;

        xi_1 = points[lpt-1].x;
        yi_1 = points[lpt-1].y;
        xi_12 = xi_1 * xi_1;
        yi_12 = yi_1 * yi_1;

        for i in 0..<lpt {
            xi = points[i].x;
            yi = points[i].y;
            
            xi2 = xi * xi;
            yi2 = yi * yi;
            dxy = xi_1 * yi - xi * yi_1;
            xii_1 = xi_1 + xi;
            yii_1 = yi_1 + yi;

            m.m00 += dxy;
            m.m10 += dxy * xii_1;
            m.m01 += dxy * yii_1;
            m.m20 += dxy * (xi_1 * xii_1 + xi2);
            m.m11 += dxy * (xi_1 * (yii_1 + yi_1) + xi * (yii_1 + yi));
            m.m02 += dxy * (yi_1 * yii_1 + yi2);
            m.m30 += dxy * xii_1 * (xi_12 + xi2);
            m.m03 += dxy * yii_1 * (yi_12 + yi2);
            m.m21 += dxy * (xi_12 * (3 * yi_1 + yi) + 2 * xi * xi_1 * yii_1 +
                            xi2 * (yi_1 + 3 * yi));
            m.m12 += dxy * (yi_12 * (3 * xi_1 + xi) + 2 * yi * yi_1 * xii_1 +
                            yi2 * (xi_1 + 3 * xi));
            xi_1 = xi;
            yi_1 = yi;
            xi_12 = xi2;
            yi_12 = yi2;
        }
        
        if abs(m.m00) < .ulpOfOne {
            return Moments()
        }
        
        let sign: CGFloat = m.m00 > 0 ? 1 : -1
        let db1_2: CGFloat = 0.5
        let db1_6: CGFloat = 0.16666666666666666666666666666667
        let db1_12: CGFloat = 0.083333333333333333333333333333333
        let db1_24: CGFloat = 0.041666666666666666666666666666667
        let db1_20: CGFloat = 0.05
        let db1_60: CGFloat = 0.016666666666666666666666666666667
        m.m00 *= sign * db1_2;
        m.m10 *= sign * db1_6;
        m.m01 *= sign * db1_6;
        m.m20 *= sign * db1_12;
        m.m11 *= sign * db1_24;
        m.m02 *= sign * db1_12;
        m.m30 *= sign * db1_20;
        m.m21 *= sign * db1_60;
        m.m12 *= sign * db1_60;
        m.m03 *= sign * db1_20;
        
        return m
    }
//
//        static func completeState(moments: inout Moments) {
//            var cx: CGFloat = 0, cy: CGFloat = 0;
//            var mu20, mu11, mu02: CGFloat
//            var inv_m00: CGFloat = 0.0;
//
//            if (fabs(moments.m00) > .ulpOfOne) {
//                inv_m00 = 1.0 / moments.m00;
//                cx = moments.m10 * inv_m00;
//                cy = moments.m01 * inv_m00;
//            }
//
//            // mu20 = m20 - m10*cx
//            mu20 = moments.m20 - moments.m10 * cx;
//            // mu11 = m11 - m10*cy
//            mu11 = moments.m11 - moments.m10 * cy;
//            // mu02 = m02 - m01*cy
//            mu02 = moments.m02 - moments.m01 * cy;
//
//            moments.mu20 = mu20;
//            moments.mu11 = mu11;
//            moments.mu02 = mu02;
//
//            // mu30 = m30 - cx*(3*mu20 + cx*m10)
//            moments.mu30 = moments.m30 - cx * (3 * mu20 + cx * moments.m10);
//            mu11 += mu11;
//            // mu21 = m21 - cx*(2*mu11 + cx*m01) - cy*mu20
//            moments.mu21 = moments.m21 - cx * (mu11 + cx * moments.m01) - cy * mu20;
//            // mu12 = m12 - cy*(2*mu11 + cy*m10) - cx*mu02
//            moments.mu12 = moments.m12 - cy * (mu11 + cy * moments.m10) - cx * mu02;
//            // mu03 = m03 - cy*(3*mu02 + cy*m01)
//            moments.mu03 = moments.m03 - cy * (3 * mu02 + cy * moments.m01);
//
//
//            double inv_sqrt_m00 = std::sqrt(std::abs(inv_m00));
//            double s2 = inv_m00*inv_m00, s3 = s2*inv_sqrt_m00;
//
//            moments.nu20 = moments.mu20*s2; moments.nu11 = moments.mu11*s2; moments.nu02 = moments.mu02*s2;
//            moments.nu30 = moments.mu30*s3; moments.nu21 = moments.mu21*s3; moments.nu12 = moments.mu12*s3; moments.nu03 = moments.mu03*s3;
//        }
}

