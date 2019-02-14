//
//  LyricsPlayerView.swift
//  ZDPlayerDemo
//
//  Created by season on 2019/2/14.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit
import ZDPlayer

/// 这个view主要学习字幕的加载
class LyricsPlayerView: ZDPlayerView {
    var playRate : Float = 1.0
    
    let rateButton = UIButton(type: .custom)
    
    var bottomProgressView : UIProgressView = {
        let progress = UIProgressView()
        progress.tintColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        progress.isHidden = true
        return progress
    }()
    
    var subtitlesManager : SubtitlesManager?
    
    let subtitlesLabel = UILabel()
    
    let mirrorFlipButton = UIButton(type: .custom)
    
    override func setUpUI() {
        super.setUpUI()
        titleLabel.removeFromSuperview()
        timeSlider.minimumTrackTintColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
        topView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        bottomView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        closeButton.setImage(nil, for: .normal)
        
        rateButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        rateButton.setTitle("x1.0", for: .normal)
        rateButton.titleLabel?.font   = UIFont.boldSystemFont(ofSize: 14.0)
        rateButton.addTarget(self, action: #selector(onRateButton), for: .touchUpInside)
        topView.addSubview(rateButton)
        rateButton.snp.makeConstraints { (make) in
            make.right.equalTo(topView.snp.right).offset(-10)
            make.centerY.equalTo(closeButton)
        }

        addSubview(bottomProgressView)
        bottomProgressView.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left)
            make.right.equalTo(self.snp.right)
            make.bottom.equalTo(bottomView.snp.top)
            make.height.equalTo(3)
        }
        
        mirrorFlipButton.tintColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        mirrorFlipButton.setTitle("开启镜像", for: .normal)
        mirrorFlipButton.setTitle("关闭镜像", for: .selected)
        mirrorFlipButton.titleLabel?.font   = UIFont.boldSystemFont(ofSize: 14.0)
        mirrorFlipButton.addTarget(self, action: #selector(onMirrorFlipButton(_:)), for: .touchUpInside)
        topView.addSubview(mirrorFlipButton)
        mirrorFlipButton.snp.makeConstraints { (make) in
            make.right.equalTo(rateButton.snp.left).offset(-10)
            make.centerY.equalTo(closeButton)
        }
        
        
        subtitlesLabel.font = UIFont.boldSystemFont(ofSize: 12.0)
        subtitlesLabel.numberOfLines = 0
        subtitlesLabel.textAlignment = .center
        subtitlesLabel.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        subtitlesLabel.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5031571062)
        subtitlesLabel.adjustsFontSizeToFitWidth = true
        insertSubview(subtitlesLabel, belowSubview: self.bottomView)
        
        subtitlesLabel.snp.makeConstraints { (make) in
            make.right.equalTo(self).offset(-5)
            make.left.equalTo(self).offset(5)
            make.bottom.equalTo(snp.bottom).offset(-10)
            make.centerX.equalTo(self)
        }
    }
    
    override func playStateDidChange(state: PlayState) {
        super.playStateDidChange(state: state)
        if state == .playing {
            self.player?.player?.rate = playRate
        }
    }
    
    override func playControlViewShow(_ isShow: Bool) {
        super.playControlViewShow(isShow)
        bottomProgressView.isHidden = isShow
    }
    
    override func reloadView() {
        super.reloadView()
        self.playRate = 1.0
        self.rateButton.setTitle("x1.0", for: .normal)
    }
    
    override func playerDurationDidChange(currentDuration: TimeInterval, totalDuration: TimeInterval) {
        super.playerDurationDidChange(currentDuration: currentDuration, totalDuration: totalDuration)
        if let sub = subtitlesManager?.search(for: currentDuration) {
            self.subtitlesLabel.isHidden = false
            self.subtitlesLabel.text = sub.content
        } else {
            self.subtitlesLabel.isHidden = true
        }
        self.bottomProgressView.setProgress(Float(currentDuration/totalDuration), animated: true)
    }
    
    open func setSubtitlesManager(_ subtitlesManager: SubtitlesManager) {
        self.subtitlesManager = subtitlesManager
    }
    
    @objc
    func onRateButton() {
        switch playRate {
        case 1.0:
            playRate = 1.5
        case 1.5:
            playRate = 0.5
        default:
            playRate = 1.0
        }
        rateButton.setTitle("x\(playRate)", for: .normal)
        player?.player?.rate = playRate
    }
    
    @objc
    func onMirrorFlipButton(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            self.playerLayer?.transform = CATransform3DScale(CATransform3DMakeRotation(0, 0, 0, 0), -1, 1, 1)
        } else {
            self.playerLayer?.transform = CATransform3DScale(CATransform3DMakeRotation(0, 0, 0, 0), 1, 1, 1)
        }
        updatePlayerView(frame: self.bounds)
    }
}

