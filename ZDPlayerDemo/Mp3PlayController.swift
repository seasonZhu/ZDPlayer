//
//  Mp3PlayController.swift
//  ZDPlayerDemo
//
//  Created by season on 2019/2/15.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit
import ZDPlayer
import SnapKit
import AVFoundation

/// 其实封装的这个ZDPlayer目前对于Mp3等音乐播放的兼容并不是特别友好,特别是指进度条等,这里只是为了演示对于Mp3信息的获取上的一些例子
class Mp3PlayController: UIViewController {
    
    lazy var player = ZDPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        title = String(describing: type(of: self))
                
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "saber", ofType: "mp3")!)
        let mp3Info = ResourceLoaderManager.avURLAssetInfo(url: url)
        
        let buttonItem = UIBarButtonItem.init(title: "切歌", style: .plain, target: self, action: #selector(changeMusic(_:)))
        navigationItem.rightBarButtonItem = buttonItem
        
        view.addSubview(player.playerView)
        
        player.loadVideo(url: url)
        player.backgroundMode = .suspend
        player.delegate = self
        player.setVideoTitle("\(mp3Info.albumName ?? "") \(mp3Info.title ?? "") \(mp3Info.artist ?? "")")
        player.playerView.layer.contents = mp3Info.artwork?.cgImage
        player.playerView.layer.contentsGravity = .resizeAspect
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
    
    deinit {
        print("LyricsPlayerController销毁了")
    }
}

extension Mp3PlayController {
    @objc
    private func changeMusic(_ button: UIButton) {
        button.tag = button.tag + 1
        let url: URL
        if button.tag % 2 == 0 {
            url = URL(fileURLWithPath: Bundle.main.path(forResource: "saber", ofType: "mp3")!)
        }else {
            url = URL(fileURLWithPath: Bundle.main.path(forResource: "music", ofType: "mp3")!)
        }
        
        let mp3Info = ResourceLoaderManager.avURLAssetInfo(url: url)
        player.loadVideo(url: url)
        player.setVideoTitle("\(mp3Info.albumName ?? "") \(mp3Info.title ?? "") \(mp3Info.artist ?? "")")
        player.playerView.layer.contents = mp3Info.artwork?.cgImage
        player.play()
    }
}

extension Mp3PlayController: ZDPlayerDelegate {
    
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
