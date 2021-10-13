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
import MediaPlayer

/// 其实封装的这个ZDPlayer目前对于Mp3等音乐播放的兼容并不是特别友好,特别是指进度条等,这里只是为了演示对于Mp3信息的获取上的一些例子
class Mp3PlayController: UIViewController {
    
    lazy var player = ZDPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        title = String(describing: type(of: self))
                
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "saber", ofType: "mp3")!)
//        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "saber", ofType: "mp3")!)
        let mp3Info = ResourceLoaderManager.avURLAssetInfo(url: url)
        
        let buttonItem = UIBarButtonItem.init(title: "切歌", style: .plain, target: self, action: #selector(changeMusic(_:)))
        navigationItem.rightBarButtonItem = buttonItem
        
        view.addSubview(player.playerView)
        
        player.loadVideo(url: url)
        player.backgroundMode = .proceed
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
        
        updateLockScreenInfo(url: url)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player.play()
        
        // 注册为第一响应者 并开始接受远程事件
        becomeFirstResponder()
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.pause()
        
        //  取消为第一响应者 并结局接受远程事件
        resignFirstResponder()
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
    deinit {
        print("LyricsPlayerController销毁了")
    }
}

extension Mp3PlayController {
    @objc
    private func changeMusic(_ button: UIBarButtonItem) {
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
        
        updateLockScreenInfo(url: url)
    }
}

extension Mp3PlayController: ZDPlayerDelegate {
    
    func player(_ player: ZDPlayer, stateDidChange state: PlayState) {
        
    }
    
    func player(_ player: ZDPlayer, playerDurationDidChange currentDuration: TimeInterval, totalDuration: TimeInterval) {
        print("current: \(currentDuration), total: \(totalDuration)")
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

extension Mp3PlayController {
    func updateLockScreenInfo(url: URL) {
        
        guard let player = player.player else {
            return
        }
        
        let mp3Info = ResourceLoaderManager.avURLAssetInfo(url: url)

        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = mp3Info.title
        info[MPMediaItemPropertyArtist] = mp3Info.artist
        info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: mp3Info.artwork!)
        info[MPMediaItemPropertyPlaybackDuration] = mp3Info.duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default()
        
        // 有关于远程控制中心的进度条的控制
        MPRemoteCommandCenter.shared().changePlaybackPositionCommand .addTarget { (event) -> MPRemoteCommandHandlerStatus in
            let totalDuration = mp3Info.duration
            
            return .success
        }
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        guard let subtype = event?.subtype else { return }
        
        switch subtype {
        //播放
        case .remoteControlPlay:
            print("播放")
        //暂停
        case .remoteControlPause:
            print("暂停")
        //停止
        case .remoteControlStop:
            print("停止")
        //切换播放暂停（耳机线控）
        case .remoteControlTogglePlayPause:
            print("切换播放暂停（耳机线控")
        //下一首
        case .remoteControlNextTrack:
            print("下一首")
            changeMusic(navigationItem.rightBarButtonItem!)
        //上一首
        case .remoteControlPreviousTrack:
            print("上一首")
        //开始快退
        case .remoteControlBeginSeekingBackward:
            print("开始快退")
        //结束快退
        case .remoteControlEndSeekingBackward:
            print("结束快退")
        //开始快进
        case .remoteControlBeginSeekingForward:
            print("开始快进")
        //结束快进
        case .remoteControlEndSeekingForward:
            print("结束快进")
        default:
            break
        }
        
        guard let type = event?.type else {
            return
        }
        
        switch type {
        case .motion:
            print("motion")
        case .presses:
            print("presses")
        case .remoteControl:
            print("remoteControl")
        case .touches:
            print("touches")
        case .scroll:
            break
        case .hover:
            break
        case .transform:
            break
        }
    }
}
