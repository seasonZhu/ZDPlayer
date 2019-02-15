//
//  VerticalFullScreenPlayController.swift
//  ZDPlayerDemo
//
//  Created by season on 2019/2/14.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit
import ZDPlayer
import AVFoundation

class VerticalFullScreenPlayController: UIViewController {
    
    var player: ZDPlayer!
    var localURL: URL!
    var remoteURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = String(describing: type(of: self))
        view.backgroundColor = UIColor.white
        
        player = ZDPlayer()
        
        let buttonItem = UIBarButtonItem.init(title: "切视频", style: .plain, target: self, action: #selector(changeMp4(_:)))
        navigationItem.rightBarButtonItem = buttonItem
        
        
        
        localURL = URL(fileURLWithPath: Bundle.main.path(forResource: "ad_douyin", ofType: "mp4")!)
        remoteURL = URL(string: "https://github.com/seasonZhu/ZDLaunchAdKit/blob/master/ZDLaunchAdDemo/Source/video1.mp4?raw=true")!
        let path = PlayerCacheManager.cacheFilePath(for: remoteURL)
        print(path)
        
        view.addSubview(player.playerView)
        
        player.loadVideo(url: remoteURL)
        player.backgroundMode = .proceed
 
        player.delegate = self
        player.setVideoTitle(remoteURL.lastPathComponent)
        player.playerView.closeButton.isHidden = true
        player.playerView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    deinit {
        print("VerticalFullScreenPlayController销毁了")
    }
}

extension VerticalFullScreenPlayController {
    @objc
    private func changeMp4(_ button: UIButton) {
        button.tag = button.tag + 1
        let url: URL
        if button.tag % 2 == 0 {
            url = localURL
        }else {
            url = remoteURL
        }
        player.setVideoTitle(url.lastPathComponent)
        player.loadVideo(url: url)
        player.play()
    }
}

extension VerticalFullScreenPlayController: ZDPlayerDelegate {
    
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
