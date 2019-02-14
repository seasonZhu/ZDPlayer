//
//  NormalPlayController.swift
//  ZDPlayerDemo
//
//  Created by season on 2019/2/14.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit
import ZDPlayer

class NormalPlayController: UIViewController {
    
    var player = ZDPlayer()
    var url1 : URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = String(describing: type(of: self))
        view.backgroundColor = UIColor.white
        
        self.url1 = URL(fileURLWithPath: Bundle.main.path(forResource: "2", ofType: "mp4")!)
        let url = URL(string: "http://lxdqncdn.miaopai.com/stream/6IqHc-OnSMBIt-LQjPJjmA__.mp4?ssig=a81b90fdeca58e8ea15c892a49bce53f&time_stamp=1508166491488")!
        self.player.replaceVideo(url: url)
        view.addSubview(self.player.playerView)
        
        let path = PlayerCacheManager.cacheFilePath(for: url)
        print(path)
        
        self.player.play()
        self.player.backgroundMode = .proceed
        self.player.delegate = self
        self.player.playerView.delegate = self
        self.player.playerView.titleLabel.text = "China NO.1"
        self.player.playerView.snp.makeConstraints { (make) in
            make.top.equalTo(view.snp.top).offset(UIApplication.shared.statusBarFrame.height + 44)
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
            make.height.equalTo(view.snp.width).multipliedBy(9.0/16.0)
            
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //self.navigationController?.setNavigationBarHidden(true, animated: true)
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: false)
        self.player.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //self.navigationController?.setNavigationBarHidden(false, animated: true)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        self.player.pause()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    //    @IBAction func changeMedia(_ sender: Any) {
    //        player.replaceVideo(url: url1!)
    //        player.play()
    //    }
    
    deinit {
        print("NormalPlayController销毁了")
    }
}

extension NormalPlayController: ZDPlayerDelegate {
    func player(_ player: ZDPlayer, stateDidChange state: PlayerState) {
        
    }
    
    func player(_ player: ZDPlayer, playerDurationDidChange currentDuration: TimeInterval, totalDuration: TimeInterval) {
        
    }
    
    func player(_ player: ZDPlayer, bufferStateDidChange state: PlayerBufferState) {
        
    }
    
    func player(_ player: ZDPlayer, bufferDidChange bufferedDuration: TimeInterval, totalDuration: TimeInterval) {
        
    }
    
    func player(_ player: ZDPlayer, playerFailed error: PlayerError) {
        
    }
}

extension NormalPlayController: ZDPlayerViewDelegate {
    func playerView(_ playerView: ZDPlayerView, willFullscreen isFullscreen: Bool) {
        
    }
    
    func playerView(_ playerView: ZDPlayerView, error: PlayerError) {
        
    }
    
    func playerView(_ playerView: ZDPlayerView, didPressCloseButton button: UIButton) {
        
    }
    
    func playerView(_ playerView: ZDPlayerView, showPlayerControl isShowPlayControl: Bool) {
        
    }
    
}
