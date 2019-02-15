//
//  LyricsPlayerController.swift
//  ZDPlayerDemo
//
//  Created by season on 2019/2/14.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit
import ZDPlayer
import SnapKit

class LyricsPlayerController: UIViewController {

    
    lazy var player : ZDPlayer = {
        let playeView = LyricsPlayerView()
        let playe = ZDPlayer(playerView: playeView)
        return playe
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        title = String(describing: type(of: self))
        
        if  let srt = Bundle.main.url(forResource: "Despacito Remix Luis Fonsi ft.Daddy Yankee Justin Bieber Lyrics [Spanish]", withExtension: "srt") {
            let playerView = self.player.playerView as! LyricsPlayerView
            playerView.setSubtitlesManager(SubtitlesManager(filePath: srt))
        }
        
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "2", ofType: "mp4")!)
        view.addSubview(player.playerView)
        
        player.loadVideo(url: url)
        player.backgroundMode = .suspend
        player.delegate = self
        player.playerView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.player.play()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player.pause()
    }
    
    deinit {
        print("LyricsPlayerController销毁了")
    }
}

extension LyricsPlayerController: ZDPlayerDelegate {
    
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

