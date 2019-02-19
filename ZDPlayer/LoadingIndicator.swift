//
//  LoadingIndicator.swift
//  ZDPlayer
//
//  Created by season on 2019/2/12.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit

public class LoadingIndicator: UIView {
    
    public var lineWidth: CGFloat {
        get {
            return indicatorLayer.lineWidth
        }
        set {
            indicatorLayer.lineWidth = newValue
            updateIndicatorLayerPath()
        }
    }
    
    public var strokeColor: UIColor {
        get {
            return UIColor(cgColor: indicatorLayer.strokeColor!)
        }
        set {
            indicatorLayer.strokeColor = newValue.cgColor
        }
    }
    
    var timingFunction: CAMediaTimingFunction!
    var isAnimating = false
    
    private let kRotationAnimationKey = "kRotationAnimationKey.rotation"
    private let indicatorLayer = CAShapeLayer()
    
    public override init(frame : CGRect) {
        super.init(frame : frame)
        commonInit()
    }
    
    public convenience init() {
        self.init(frame:CGRect.zero)
        commonInit()
    }
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override open func layoutSubviews() {
        indicatorLayer.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height);
        updateIndicatorLayerPath()
    }
    
    func commonInit(){
        timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        setupIndicatorLayer()
    }
    
    func setupIndicatorLayer() {
        indicatorLayer.strokeColor = UIColor.white.cgColor
        indicatorLayer.fillColor = nil
        indicatorLayer.lineWidth = 2.0
        indicatorLayer.lineJoin = .round;
        indicatorLayer.lineCap = .round;
        layer.addSublayer(indicatorLayer)
        updateIndicatorLayerPath()
    }
    
    func updateIndicatorLayerPath() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width / 2, bounds.height / 2) - indicatorLayer.lineWidth / 2
        let startAngle: CGFloat = 0
        let endAngle: CGFloat = 2 * CGFloat(Double.pi)
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        indicatorLayer.path = path.cgPath
        indicatorLayer.strokeStart = 0.1
        indicatorLayer.strokeEnd = 1.0
    }
    
    public func startAnimating() {
        if isAnimating {
            return
        }
        
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = 1
        animation.fromValue = 0
        animation.toValue = (2 * Double.pi)
        animation.repeatCount = Float.infinity
        animation.isRemovedOnCompletion = false
        indicatorLayer.add(animation, forKey: kRotationAnimationKey)
        isAnimating = true
    }
    
    public func stopAnimating() {
        if !isAnimating {
            return
        }
        
        indicatorLayer.removeAnimation(forKey: kRotationAnimationKey)
        isAnimating = false
    }
    
}
