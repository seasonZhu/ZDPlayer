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
    
    var player: ZDPlayer!
    var localURL: URL!
    var remotURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = String(describing: type(of: self))
        view.backgroundColor = UIColor.white
        
        player = ZDPlayer()
        
        localURL = URL(fileURLWithPath: Bundle.main.path(forResource: "2", ofType: "mp4")!)
        remotURL = URL(string: "http://lxdqncdn.miaopai.com/stream/6IqHc-OnSMBIt-LQjPJjmA__.mp4?ssig=a81b90fdeca58e8ea15c892a49bce53f&time_stamp=1508166491488")!
        let path = PlayerCacheManager.cacheFilePath(for: remotURL)
        print(path)
        
        view.addSubview(player.playerView)

        player.loadVideo(url: remotURL)
        player.backgroundMode = .proceed
        
        /*
         可以将两个代理二合一
         */
        player.delegate = self
        //self.player.playerView.delegate = self
        player.setVideoTitle("在线视频 测试测吐了 内容太沉重了")
        player.playerView.snp.makeConstraints { (make) in
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
        player.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //self.navigationController?.setNavigationBarHidden(false, animated: true)
        UIApplication.shared.setStatusBarHidden(false, with: .none)
        player.pause()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    //    @IBAction func changeMedia(_ sender: Any) {
    //        player.loadVideo(url: url1!)
    //        player.play()
    //    }
    
    deinit {
        print("NormalPlayController销毁了")
    }
}

extension NormalPlayController: ZDPlayerDelegate {
    
    func player(_ player: ZDPlayer, stateDidChange state: PlayState) {
        
    }
    
    func player(_ player: ZDPlayer, playerDurationDidChange currentDuration: TimeInterval, totalDuration: TimeInterval) {
        
    }
    
    func player(_ player: ZDPlayer, bufferStateDidChange state: BufferState) {
        
    }
    
    func player(_ player: ZDPlayer, bufferDidChange bufferedDuration: TimeInterval, totalDuration: TimeInterval) {
        
    }
    
    func player(_ player: ZDPlayer, playerFailed error: PlayerError) {
        
    }
    
    func player(_ player: ZDPlayer, playerView: ZDPlayerView, willFullscreen isFullscreen: Bool) {
        isFullscreen ? print("ZDPlayerDelegate进入全屏") : print("ZDPlayerDelegate退出全屏")
    }
    
    func player(_ player: ZDPlayer, playerView: ZDPlayerView, didPressCloseButton button: UIButton) {
        print("ZDPlayerDelegate点击了关闭按钮")
    }
    
    func player(_ player: ZDPlayer, playerView: ZDPlayerView, showPlayerControl isShowPlayControl: Bool) {
        isShowPlayControl ? print("ZDPlayerDelegate显示播放组件") : print("ZDPlayerDelegate隐藏播放组件")
    }
}

extension NormalPlayController: ZDPlayerViewDelegate {
    func playerView(_ playerView: ZDPlayerView, willFullscreen isFullscreen: Bool) {
        isFullscreen ? print("ZDPlayerViewDelegate进入全屏") : print("ZDPlayerViewDelegate退出全屏")
    }
    
    func playerView(_ playerView: ZDPlayerView, didPressCloseButton button: UIButton) {
        print("ZDPlayerViewDelegate点击了关闭按钮")
    }
    
    func playerView(_ playerView: ZDPlayerView, showPlayerControl isShowPlayControl: Bool) {
        isShowPlayControl ? print("ZDPlayerViewDelegate显示播放组件") : print("ZDPlayerViewDelegate隐藏播放组件")
    }
    
}
