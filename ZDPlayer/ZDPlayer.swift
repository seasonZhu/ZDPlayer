//
//  ZDPlayer.swift
//  ZDPlayer
//
//  Created by season on 2019/2/12.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation
import AVFoundation

/// 播放状态
///
/// - none: 无
/// - playing: 正在播放
/// - pause: 暂停
/// - playFinished: 播放完成
/// - error: 错误
public enum PlayState {
    case none
    case playing
    case pause
    case playFinished
    case error
}

/// 缓冲状态
///
/// - none: 无
/// - readyToPlay: 准备播放
/// - buffering: 正在缓冲
/// - stop: 停止
/// - bufferFinished: 缓冲完成
public enum BufferState {
    case none
    case readyToPlay
    case buffering
    case stop
    case bufferFinished
}

/// 后台播放模式
///
/// - suspend: 挂起
/// - autoPlayAndPaused: 自动播放和停止
/// - proceed: 前进
public enum BackgroundMode {
    case suspend
    case autoPlayAndPaused
    case proceed
}

/// 视频格式
///
/// - unknown: 未知
/// - mpeg4: mpeg4
/// - m3u8: m3u8
/// - mov: mov
/// - m4v: m4v
/// - error: 错误
public enum MediaFormat: String{
    case unknown = "unknown"
    case mpeg4 = "mpeg4"
    case m3u8 = "m3u8"
    case mov = "mov"
    case m4v = "m4v"
    case error = "error"
    
    /// 分析视频格式
    ///
    /// - Parameter url: 视频地址
    /// - Returns: 格式类型
    public static func analyzeVideoFormat(url: URL?) -> MediaFormat {
        if url == nil {
            return .error
        }
        if let path = url?.absoluteString{
            if path.contains(".mp4") {
                return .mpeg4
            } else if path.contains(".m3u8") {
                return .m3u8
            } else if path.contains(".mov") {
                return .mov
            } else if path.contains(".m4v"){
                return .m4v
            } else {
                return .unknown
            }
        } else {
            return .error
        }
    }
}

/// ZDPlayer的代理
public protocol ZDPlayerDelegate: class {
    func player(_ player: ZDPlayer, stateDidChange state: PlayState)
    func player(_ player: ZDPlayer, playerDurationDidChange currentDuration: TimeInterval, totalDuration: TimeInterval)
    func player(_ player: ZDPlayer, bufferStateDidChange state: BufferState)
    func player(_ player: ZDPlayer, bufferDidChange bufferedDuration: TimeInterval, totalDuration: TimeInterval)
    func player(_ player: ZDPlayer, playerFailed error: PlayerError)
    
    func player(_ player: ZDPlayer, playerView: ZDPlayerView, willFullscreen isFullscreen: Bool)
    func player(_ player: ZDPlayer, playerView: ZDPlayerView, didPressCloseButton button: UIButton)
    func player(_ player: ZDPlayer, playerView: ZDPlayerView, didPressFullscreenButton button: UIButton)
    func player(_ player: ZDPlayer, playerView: ZDPlayerView, showPlayerControl isShowPlayControl: Bool)
}

// MARK: - ZDPlayer的代理的默认实现
public extension ZDPlayerDelegate {
    func player(_ player: ZDPlayer, stateDidChange state: PlayState) {}
    func player(_ player: ZDPlayer, playerDurationDidChange currentDuration: TimeInterval, totalDuration: TimeInterval) {}
    func player(_ player: ZDPlayer, bufferStateDidChange state: BufferState) {}
    func player(_ player: ZDPlayer, bufferDidChange bufferedDuration: TimeInterval, totalDuration: TimeInterval) {}
    func player(_ player: ZDPlayer, playerFailed error: PlayerError) {}
    
    func player(_ player: ZDPlayer, playerView: ZDPlayerView, willFullscreen isFullscreen: Bool) {}
    func player(_ player: ZDPlayer, playerView: ZDPlayerView, didPressCloseButton button: UIButton) {}
    func player(_ player: ZDPlayer, playerView: ZDPlayerView, didPressFullscreenButton button: UIButton) {}
    func player(_ player: ZDPlayer, playerView: ZDPlayerView, showPlayerControl isShowPlayControl: Bool) {}
}

public class ZDPlayer: NSObject {
    
    /// 代理
    public weak var delegate: ZDPlayerDelegate?
    
    /// 播放层
    public var playerView: ZDPlayerView
    
    /// 播放状态
    public var state: PlayState = .none {
        didSet {
            if state != oldValue {
                playerView.playStateDidChange(state: state)
                delegate?.player(self, stateDidChange: state)
            }
        }
    }
    
    /// 缓冲状态
    public var bufferState: BufferState = .none {
        didSet {
            if bufferState != oldValue {
                playerView.bufferStateDidChange(state: bufferState)
                delegate?.player(self, bufferStateDidChange: bufferState)
            }
        }
    }
    
    /// 视频模式
    public var videoGravity: AVLayerVideoGravity = .resizeAspect
    
    /// 后台播放模式
    public var backgroundMode: BackgroundMode = .autoPlayAndPaused
    
    /// 缓冲的最短时间
    public var bufferInterval: TimeInterval = 2.0
    
    /// 视频格式
    public private(set) var mediaFormat: MediaFormat
    
    /// 视频整体时间
    public private(set) var totalDuration : TimeInterval = 0.0
    
    /// 视频当前时间
    public private(set) var currentDuration : TimeInterval = 0.0
    
    /// 是否正在缓冲
    public private(set) var isBuffering = false
    
    /// AVPlayer
    public private(set) var player: AVPlayer? {
        willSet {
            removePlayerObserver()
        }
        
        didSet {
            addPlayerObserver()
        }
    }
    
    /// AVPlayerItem
    public private(set) var playerItem: AVPlayerItem? {
        willSet {
            removePlayerItemObserver()
            removePlayerNotification()
        }
        
        didSet {
            addPlayerItemObserver()
            addPlayerNotification()
        }
    }
    
    /// 播放资源
    public private(set) var playerAsset: AVURLAsset?
    
    /// 播放地址
    public private(set) var contentURL: URL?
    
    /// 播放错误
    public private(set) var error: PlayerError
    
    /// 时间观察者
    private var timeObserver: Any?
    
    /// 是否在进行视频时间轴的寻找
    private var isSeeking = false
    
    /// 资源管理器
    private let resourceLoaderManager: ResourceLoaderManager
    
    /// 初始化方法
    ///
    /// - Parameters:
    ///   - url: 播放地址
    ///   - playerView: 播放层
    public init(url: URL? = nil, playerView: ZDPlayerView? = nil) {
        mediaFormat = MediaFormat.analyzeVideoFormat(url: url)
        resourceLoaderManager = ResourceLoaderManager()
        contentURL = url
        error = PlayerError()
        if let playerView = playerView {
            self.playerView = playerView
        }else {
            self.playerView = ZDPlayerView()
        }
        super.init()
        if let url = url {
            setUpPlayer(url: url)
        }
    }
    
    /// 便利构造方法
    public convenience override init() {
        self.init()
    }
    
    /// 析构函数
    deinit {
        print("ZDPlayer销毁了")
        removePlayerNotification()
        clearPlayer()
        playerView.removeFromSuperview()
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - 对外方法
extension ZDPlayer {
    
    /// 替换视频资源
    ///
    /// - Parameter url: 视频资源网址
    public func loadVideo(url: URL) {
        reloadPlayer()
        mediaFormat = MediaFormat.analyzeVideoFormat(url: url)
        contentURL = url
        setUpPlayer(url: url)
    }
    
    /// 重新加载Player
    public func reloadPlayer() {
        isSeeking = false
        totalDuration = 0.0
        currentDuration = 0.0
        error = PlayerError()
        state = .none
        bufferState = .none
        isBuffering = false
        clearPlayer()
    }
    
    /// 清除Player
    public func clearPlayer() {
        player?.pause()
        player?.cancelPendingPrerolls()
        player?.replaceCurrentItem(with: nil)
        player = nil
        
        playerAsset?.cancelLoading()
        playerAsset = nil
        
        playerItem?.cancelPendingSeeks()
        playerItem = nil
    }
    
    /// 播放
    public func play() {
        if contentURL == nil {
            return
        }
        
        // 播放完毕实际上是再重播一次的操作
        if state == .playFinished {
            playerView.onReplay(playerView.replayButton)
            state = .playing
            return
        }
        
        player?.play()
        state = .playing
        playerView.play()
    }
    
    /// 暂停
    public func pause() {
        guard state == .pause else {
            player?.pause()
            state = .pause
            playerView.pause()
            return
        }
    }
    
    /// 拖动视频时间轴
    ///
    /// - Parameters:
    ///   - time: 时间
    ///   - completion: 完成回调
    public func seekTime(_ time: TimeInterval, completion: ((Bool) -> Void)? = nil) {
        if time.isNaN || playerItem?.status != .readyToPlay {
            completion?(false)
            return
        }
    
        isSeeking = true
        startPlayerBuffering()
        playerItem?.seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: Int32(NSEC_PER_SEC))) { [weak self] (finished) in
            self?.isSeeking = false
            self?.stopPlayerBuffering()
            self?.play()
            completion?(finished)
        }
    }
    
    public func setVideoTitle(_ title: String?) {
        playerView.titleLabel.text = title
    }
}

// MARK: - 私有方法
extension ZDPlayer {
    
    /// 配置player
    func setUpPlayer(url: URL) {
        playerView.setPlayer(self)
        playerView.delegate = self
        playerAsset = AVURLAsset(url: url, options: .none)
        if url.isFileURL, let asset = playerAsset {
            let keys = ["tracks", "playable"]
            playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: keys)
        }else {
            //playerItem = noCacheManagerGetPlayerItem(url: url)
            playerItem = cacheManagerGetPlayerItem(url: url)
        }
        player = AVPlayer(playerItem: playerItem)
        playerView.reloadView()
    }
    
    /// 无缓存的加载在线视频策略
    func noCacheManagerGetPlayerItem(url: URL) -> AVPlayerItem? {
        let urlAsset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: urlAsset)
        
        if #available(iOS 9.0, *) {
            playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        }
        return playerItem
    }
    
    /// 有缓存的加载在线视频策略
    func cacheManagerGetPlayerItem(url: URL) -> AVPlayerItem? {
        return resourceLoaderManager.playerItem(url: url)
    }
    
    /// 开始缓冲
    func startPlayerBuffering() {
        pause()
        bufferState = .buffering
        isBuffering = true
    }
    
    /// 停止缓冲
    func stopPlayerBuffering() {
        bufferState = .stop
        isBuffering = false
    }
    
    /// 收集错误日志
    func collectPlayerError() {
        error.playerItemErrorLogEvent = playerItem?.errorLog()?.events
        error.error = playerItem?.error
        error.extendedLogData = playerItem?.errorLog()?.extendedLogData()
        error.extendedLogDataStringEncoding = playerItem?.errorLog()?.extendedLogDataStringEncoding
    }
}

// MARK: - KVO&Notification
extension ZDPlayer {
    /// 添加player的时间观察
    func addPlayerObserver() {
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 1), queue: DispatchQueue.main) { [weak self] (cmTime) in
            if let currentDuration = self?.player?.currentTime().seconds, let totalDuration = self?.player?.currentItem?.duration.seconds {
                self?.currentDuration = currentDuration
                self?.delegate?.player(self!, playerDurationDidChange: currentDuration, totalDuration: totalDuration)
                self?.playerView.playerDurationDidChange(currentDuration: currentDuration, totalDuration: totalDuration)
            }
        }
    }
    
    /// 移除player的时间观察
    func removePlayerObserver() {
        guard let timeObserver = self.timeObserver else { return }
        player?.removeTimeObserver(timeObserver)
    }
    
    /// 添加playerItem的观察
    func addPlayerItemObserver() {
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.new, .initial], context: nil)
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges), options: [.new, .initial], context: nil)
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty), options: [.new, .initial], context: nil)
    }
    
    /// 移除playerItem的观察
    func removePlayerItemObserver() {
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges))
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.isPlaybackBufferEmpty))
    }
    
    /// 添加player的通知
    func addPlayerNotification() {
        NotificationCenter.default.addObserver(self, selector: .playerItemDidPlayToEndTime, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(self, selector: .applicationWillEnterForeground, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: .applicationDidEnterBackground, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    /// 移除player的通知
    func removePlayerNotification() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    /// 播放结束
    ///
    /// - Parameter notification: 通知
    @objc
    func playerItemDidPlayToEnd(_ notification: Notification) {
        if state != .playFinished {
            state = .playFinished
        }
    }
    
    /// 即将进入前台
    ///
    /// - Parameter notification: 通知
    @objc
    func applicationWillEnterForeground(_ notification: Notification) {
        if let playerLayer = playerView.playerLayer {
            playerLayer.player = player
        }
        
        switch backgroundMode {
        case .suspend:
            pause()
        case .autoPlayAndPaused:
            play()
        case .proceed:
            break
        }
    }
    
    /// 进入后台
    ///
    /// - Parameter notification: 通知
    @objc
    func applicationDidEnterBackground(_ notification: Notification) {
        if let playerLayer = playerView.playerLayer  {
            playerLayer.player = nil
        }
        
        switch backgroundMode {
        case .suspend, .autoPlayAndPaused:
            pause()
        case .proceed:
            play()
        }
    }
    
    /// KVO
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let nsNumber = change?[.newKey] as? NSNumber, let s = AVPlayerItem.Status(rawValue: nsNumber.intValue) {
                status = s
            }else {
                status = .unknown
            }
            
            switch status {
            case .unknown:
                startPlayerBuffering()
            case .readyToPlay:
                bufferState = .readyToPlay
            case .failed:
                state = .error
                collectPlayerError()
                stopPlayerBuffering()
                delegate?.player(self, playerFailed: error)
                playerView.playFailed(error: error)
            }
            
        }else if keyPath == #keyPath(AVPlayerItem.isPlaybackBufferEmpty) {
            if let isPlaybackBufferEmpty = change?[.newKey] as? Bool, isPlaybackBufferEmpty {
                startPlayerBuffering()
            }
        }else if keyPath == #keyPath(AVPlayerItem.loadedTimeRanges) {
            let loadedTimeRanges = player?.currentItem?.loadedTimeRanges
            if let bufferTimeRange = loadedTimeRanges?.first?.timeRangeValue {
                let start = bufferTimeRange.start.seconds
                let durarion = bufferTimeRange.duration.seconds
                let bufferTime = start + durarion
                
                if let itemDuration = playerItem?.duration.seconds {
                    delegate?.player(self, bufferDidChange: bufferTime, totalDuration: itemDuration)
                    playerView.bufferDidChange(buffereDuration: bufferTime, totalDuration: itemDuration)
                    totalDuration = itemDuration
                    if itemDuration == bufferTime {
                        bufferState = .bufferFinished
                    }
                }
                
                if let currentTime = playerItem?.currentTime().seconds {
                    if bufferTime - currentTime >= bufferInterval && state != .pause {
                        play()
                    }
                    
                    if bufferTime - currentTime < bufferInterval {
                        bufferState = .buffering
                        isBuffering = true
                    }else {
                        bufferState = .readyToPlay
                        isBuffering = false
                    }
                }
            }else {
                play()
            }
        }
    }
}

// MARK: - 实现ZDPlayerViewDelegate的方法
extension ZDPlayer: ZDPlayerViewDelegate {
    public func playerView(_ playerView: ZDPlayerView, willFullscreen isFullscreen: Bool) {
        delegate?.player(self, playerView: playerView, willFullscreen: isFullscreen)
    }

    public func playerView(_ playerView: ZDPlayerView, didPressCloseButton button: UIButton) {
        delegate?.player(self, playerView: playerView, didPressCloseButton: button)
    }
    
    public func playerView(_ playerView: ZDPlayerView, didPressFullscreenButton button: UIButton) {
        delegate?.player(self, playerView: playerView, didPressFullscreenButton: button)
    }

    public func playerView(_ playerView: ZDPlayerView, showPlayerControl isShowPlayControl: Bool) {
        delegate?.player(self, playerView: playerView, showPlayerControl: isShowPlayControl)
    }
}

// MARK: - 方法封装
private extension Selector {
    static let playerItemDidPlayToEndTime = #selector(ZDPlayer.playerItemDidPlayToEnd(_:))
    static let applicationWillEnterForeground = #selector(ZDPlayer.applicationWillEnterForeground(_:))
    static let applicationDidEnterBackground = #selector(ZDPlayer.applicationDidEnterBackground(_:))
}
