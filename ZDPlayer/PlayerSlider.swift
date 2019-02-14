//
//  PlayerSlider.swift
//  ZDPlayer
//
//  Created by season on 2019/2/12.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit

public class PlayerSlider: UISlider {
    public var progressView: UIProgressView
    
    public override init(frame: CGRect) {
        progressView = UIProgressView()
        super.init(frame: frame)
        setUpUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    public override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let rect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        let newRect = CGRect(x: rect.origin.x, y: rect.origin.y + 1, width: rect.width, height: rect.height)
        return newRect
    }
    
    public override func trackRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.trackRect(forBounds: bounds)
        let newRect = CGRect(origin: rect.origin, size: CGSize(width: rect.size.width, height: 2.0))
        setUpProgressView(frame: newRect)
        return newRect
    }
    
    public func setProgress(_ progress: Float, animated: Bool) {
        progressView.setProgress(progress, animated: animated)
    }
}

extension PlayerSlider {
    private func setUpUI() {
        maximumValue = 1.0
        minimumValue = 0.0
        value = 0.0
        maximumTrackTintColor = UIColor.clear
        minimumTrackTintColor = UIColor.white
        
        let normalImage = BundleManager.image(named: "VGPlayer_ic_slider_thumb")?.scaledToSize(CGSize(width: 15, height: 15))
        setThumbImage(normalImage, for: .normal)
        let highlightedImage = BundleManager.image(named: "VGPlayer_ic_slider_thumb")?.scaledToSize(CGSize(width: 20, height: 20))
        setThumbImage(highlightedImage, for: .highlighted)
        
        backgroundColor = UIColor.clear
        progressView.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.7988548801)
        progressView.trackTintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.2964201627)

    }
    
    private func setUpProgressView(frame: CGRect) {
        progressView.frame = frame
        insertSubview(progressView, at: 0)
    }
}

