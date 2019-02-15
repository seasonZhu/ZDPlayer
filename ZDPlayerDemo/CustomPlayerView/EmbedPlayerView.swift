//
//  EmbedPlayerView.swift
//  ZDPlayerDemo
//
//  Created by season on 2019/2/15.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit
import ZDPlayer

class EmbedPlayerView: ZDPlayerView {
    var playRate : Float = 1.0
    
    lazy var bottomProgressView : UIProgressView = {
        let progress = UIProgressView()
        progress.tintColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        progress.isHidden = true
        return progress
    }()
    
    var isSmallMode = false {
        didSet{
            configureGesture()
            updateView()
        }
    }
    
    override func setUpUI() {
        super.setUpUI()
        titleLabel.removeFromSuperview()
        timeSlider.minimumTrackTintColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        topView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        bottomView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        closeButton.setImage(#imageLiteral(resourceName: "nav_back"), for: .normal)
        closeButton.isHidden = true
        
        addSubview(bottomProgressView)
        bottomProgressView.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left)
            make.right.equalTo(self.snp.right)
            make.bottom.equalTo(self.snp.bottom)
            make.height.equalTo(3)
        }
        
    }
    
    func configureGesture() {
        doubleTapGesture.isEnabled = !isSmallMode
        singleTapGesture.isEnabled = !isSmallMode
        panGesture.isEnabled = !isSmallMode
    }
    
    
    override func reloadView() {
        super.reloadView()
        bottomProgressView.setProgress(0, animated: false)
    }
    
    override func playerDurationDidChange(currentDuration: TimeInterval, totalDuration: TimeInterval) {
        super.playerDurationDidChange(currentDuration: currentDuration, totalDuration: totalDuration)
        bottomProgressView.setProgress(Float(currentDuration/totalDuration), animated: true)
    }
    
    func updateView() {
        playControlViewShow(!isSmallMode)
        if isSmallMode {
            self.bottomProgressView.isHidden = false
            self.topView.isHidden = true
            self.bottomView.isHidden = true
        } else {
            self.bottomProgressView.isHidden = false
            self.topView.isHidden = false
            self.bottomView.isHidden = false
        }
    }
}
