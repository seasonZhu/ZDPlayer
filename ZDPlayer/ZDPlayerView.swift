//
//  ZDPlayerView.swift
//  ZDPlayer
//
//  Created by season on 2019/2/12.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit
import MediaPlayer
import SnapKit

/// ZDPlayerView的代理
public protocol ZDPlayerViewDelegate: class {
    func playerView(_ playerView: ZDPlayerView, willFullscreen isFullscreen: Bool)
    
    func playerView(_ playerView: ZDPlayerView, didPressCloseButton button: UIButton)
    
    func playerView(_ playerView: ZDPlayerView, didPressFullscreenButton button: UIButton)

    func playerView(_ playerView: ZDPlayerView, showPlayerControl isShowPlayerControl: Bool)
}

// MARK: - ZDPlayerView的代理的默认实现 注意的是对于这种带有public的协议可选, 其extension也是public修饰
public extension ZDPlayerViewDelegate {
    func playerView(_ playerView: ZDPlayerView, willFullscreen isFullscreen: Bool) {}
    
    func playerView(_ playerView: ZDPlayerView, didPressCloseButton button: UIButton) {}
    
    func playerView(_ playerView: ZDPlayerView, didPressFullscreenButton button: UIButton) {}
    
    func playerView(_ playerView: ZDPlayerView, showPlayerControl isShowPlayerControl: Bool) {}
}

/// ZDPlayerView
open class ZDPlayerView: UIView {
    
    /// 播放器
    public weak var player: ZDPlayer?
    
    /// 代理
    public weak var delegate: ZDPlayerViewDelegate?

    /// 动画时长
    public var controlViewDuration: TimeInterval = 5.0
    
    /// AVPlayerLayer
    public private(set) var playerLayer: AVPlayerLayer?

    /// 是否是全屏
    public private(set) var isFullScreen = false
    
    /// 是否在滑动进度条
    public private(set) var isTimeSliding = false
    
    /// 是否显示播放小组件
    public private(set) var isShowPlayerControl = true {
        didSet {
            if isShowPlayerControl != oldValue {
                delegate?.playerView(self, showPlayerControl: isShowPlayerControl)
            }
        }
    }
    
    /// 播放器顶部view
    public lazy var topView: UIView = {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        return view
    }()
    
    /// 顶部view上的视频标题
    public lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        return label
    }()
    
    /// 顶部view上的关闭按钮
    public lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        let closeImage = BundleManager.image(named: "VGPlayer_ic_nav_back")
        button.setImage(closeImage?.scaledToSize(CGSize(width: 15, height: 20)), for: .normal)
        button.addTarget(self, action: #selector(onClose(_:)), for: .touchUpInside)
        return button
    }()
    
    /// 中间的加载view
    public lazy var loadingIndicator: LoadingIndicator = {
        let loadingIndicator = LoadingIndicator()
        loadingIndicator.lineWidth = 1.0
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        return loadingIndicator
    }()
    
    /// 中间的重播按钮
    public lazy var replayButton: UIButton = {
        let button = UIButton(type: .custom)
        let replayImage = BundleManager.image(named: "VGPlayer_ic_replay")
        button.setImage(replayImage?.scaledToSize(CGSize(width: 30, height: 30)), for: .normal)
        button.addTarget(self, action: #selector(onReplay(_:)), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    /// 播放器的底部view
    public lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        return view
    }()
    
    /// 底部view上的播放按钮
    public lazy var playButton: UIButton = {
        let button = UIButton(type: .custom)
        let playImage = BundleManager.image(named: "VGPlayer_ic_play")
        let pauseImage = BundleManager.image(named: "VGPlayer_ic_pause")
        button.setImage(playImage?.scaledToSize(CGSize(width: 15, height: 15)), for: .normal)
        button.setImage(pauseImage?.scaledToSize(CGSize(width: 15, height: 15)), for: .selected)
        button.addTarget(self, action: #selector(onPlay(_:)), for: .touchUpInside)
        return button
    }()
    
    /// 底部view上的声音按钮 静音或者有声音
    public lazy var soundButton: UIButton = {
        let button = UIButton(type: .custom)
        let soundOff = BundleManager.image(named: "sound_off")
        let soundOn = BundleManager.image(named: "sound_on")
        button.isSelected = false
        button.setImage(soundOff, for: .normal)
        button.setImage(soundOn, for: .selected)
        button.addTarget(self, action: #selector(onSound(_:)), for: .touchUpInside)
        return button
    }()
    
    /// 底部view上的全屏按钮
    public lazy var fullscreenButton: UIButton = {
        let button = UIButton(type: .custom)
        let enlargeImage = BundleManager.image(named: "VGPlayer_ic_fullscreen")
        let narrowImage = BundleManager.image(named: "VGPlayer_ic_fullscreen_exit")
        button.setImage(enlargeImage?.scaledToSize(CGSize(width: 15, height: 15)), for: .normal)
        button.setImage(narrowImage?.scaledToSize(CGSize(width: 15, height: 15)), for: .selected)
        button.addTarget(self, action: #selector(onFullScreen(_:)), for: .touchUpInside)
        return button
    }()
    
    /// 底部view上的时间Label
    public lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        label.font = UIFont.systemFont(ofSize: 12.0)
        label.text = "--:-- | --:--"
        return label
    }()
    
    /// 底部view上的时间进度条
    public lazy var timeSlider: PlayerSlider = {
        let timeSlider = PlayerSlider()
        timeSlider.addTarget(self, action: #selector(timeSliderValueChanged(_:)), for: .valueChanged)
        timeSlider.addTarget(self, action: #selector(timeSliderTouchUpInside(_:)), for: .touchUpInside)
        timeSlider.addTarget(self, action: #selector(timeSliderTouchDown(_:)), for: .touchDown)
        return timeSlider
    }()
    
    /// 声音强度条
    public var volumeSlider: UISlider!
    
    /// 亮度强度条 高仿系统
    public var brightnessSlider: BrightnessView?
    
    /// 滑动手势的方向 默认是横向
    public private(set) var panGestureDirection : NSLayoutConstraint.Axis = .horizontal
    
    /// 单击手势
    public lazy var singleTapGesture: UITapGestureRecognizer = {
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onSingleTapGesture(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.numberOfTouchesRequired = 1
        singleTapGesture.delegate = self
        return singleTapGesture
    }()
    
    /// 双击手势
    public lazy var doubleTapGesture: UITapGestureRecognizer = {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTapGesture(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        doubleTapGesture.numberOfTouchesRequired = 1
        doubleTapGesture.delegate = self
        return doubleTapGesture
    }()
    
    /// 滑动手势
    public lazy var panGesture: UIPanGestureRecognizer = {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture(_:)))
        panGesture.delegate = self
        return panGesture
    }()
    
    /// 是否有声音
    private var isVolume = true
    
    /// 进度条滑动的值
    private var sliderSeekTimeValue: TimeInterval = .nan
    
    /// 父view
    private weak var parentView: UIView?
    
    /// 定时器
    private var timer: Timer?

    /// 播放器的frame
    private var viewFrame = CGRect.zero
    
    /// 记录上一次的手机方位
    private var lastOrientation: UIInterfaceOrientation?
    
    /// 记录上一次的手机声音值
    private var lastSoundValue: Float = 0
    
    /// 构造函数
    ///
    /// - Parameter frame: frame
    public override init(frame: CGRect) {
        playerLayer = AVPlayerLayer(player: nil)
        lastOrientation = UIApplication.shared.statusBarOrientation
        super.init(frame: frame)
        addDeviceOrientationNotification()
        addGestureRecognizer()
        getVolumeSlider()
        getBrightnessSlider()
        setUpUI()
        //setUpUIBySystem_iOS9()
        //setUpUIBySystem()
    }
    
    /// 便利构造函数
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// layoutSubviews
    open override func layoutSubviews() {
        super.layoutSubviews()
        updatePlayerView(frame: bounds)
    }
    
    /// 析构函数
    deinit {
        print("\(String(describing: type(of: self)))销毁了")
        timer?.invalidate()
        timer = nil
        playerLayer?.removeFromSuperlayer()
        NotificationCenter.default.removeObserver(self)
        BrightnessView.destoryInstance()
    }
    
    //MARK:- 对外可重写方法,open修饰的方法不能写在extension中
    
    /// 播放状态已经改变
    ///
    /// - Parameter state: 播放状态
    open func playStateDidChange(state: PlayState) {
        playButton.isSelected = state == .playing
        replayButton.isHidden = !(state == .playFinished)
        
        if state == .playing || state == .playFinished {
            delayPlayControlViewDisappear()
        }
        
        if state == .playFinished {
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()
        }
    }
    
    /// 缓冲状态已经改变
    ///
    /// - Parameter state: 缓冲状态
    open func bufferStateDidChange(state: BufferState) {
        if state == .buffering {
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimating()
        }else {
            loadingIndicator.isHidden = true
            loadingIndicator.stopAnimating()
        }
        
        guard let player = player else { return }
        var current = formatSecondsToString(seconds: player.currentDuration)
        if player.totalDuration.isNaN {
            current = "00:00"
        }
        
        if state == .readyToPlay && !isTimeSliding {
            timeLabel.text = current + " | " + formatSecondsToString(seconds: player.totalDuration)
        }
    }
    
    /// 缓冲的时间轴进行了改变
    ///
    /// - Parameters:
    ///   - buffereDuration: 缓冲进度时间
    ///   - totalDuration: 总时间
    open func bufferDidChange(buffereDuration: TimeInterval, totalDuration: TimeInterval) {
        timeSlider.setProgress(Float(buffereDuration / totalDuration), animated: true)
    }
    
    /// 播放时间轴进行了改变
    ///
    /// - Parameters:
    ///   - currentDuration: 播放的当前时间
    ///   - totalDuration: 总时间
    open func playerDurationDidChange(currentDuration: TimeInterval, totalDuration: TimeInterval) {
        var current = formatSecondsToString(seconds: currentDuration)
        if totalDuration.isNaN {
            current = "00:00"
        }
        
        if !isTimeSliding {
            timeLabel.text = current + " | " +  formatSecondsToString(seconds: totalDuration)
            timeSlider.value = Float(currentDuration / totalDuration)
        }
    }
    
    /// 设置ZDPlayer
    ///
    /// - Parameter player: ZDPlayer
    open func setPlayer(_ player: ZDPlayer) {
        self.player = player
    }
    
    /// 重新加载View
    open func reloadView() {
        playerLayer = AVPlayerLayer(player: nil)
        timeSlider.value = 0
        timeSlider.setProgress(0, animated: false)
        replayButton.isHidden = true
        isTimeSliding = false
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimating()
        timeLabel.text = "--:-- | --:--"
        reloadLayer()
    }
    
    /// 重新加载Layer
    open func reloadLayer() {
        playerLayer = AVPlayerLayer(player: player?.player)
        guard let playerLayer = playerLayer else { return }
        layer.insertSublayer(playerLayer, at: 0)
        updatePlayerView(frame: bounds)
        timeSlider.isUserInteractionEnabled = player?.mediaFormat != .m3u8
        reloadGravity()
    }
    
    /// 重新视频模式
    open func reloadGravity() {
        guard let player = player else { return }
        playerLayer?.videoGravity = player.videoGravity
    }
    
    /// 播放组件展示
    ///
    /// - Parameter isShow: 是否展示
    open func playControlViewShow(_ isShow: Bool) {
        isShow ? showPlayerControlAnimation() : hiddenPlayerControlAnimation()
    }
    
    /// 更新PlayerView的frame
    ///
    /// - Parameter frame: frame
    open func updatePlayerView(frame: CGRect) {
        playerLayer?.frame = frame
    }
    
    /// 进入全屏播放
    open func enterFullScreen() {
        UIDevice.current.setValue(UIDeviceOrientation.landscapeLeft.rawValue, forKey: #keyPath(UIDevice.orientation))
    }
    
    /// 退出全屏播放
    open func exitFullscreen() {
        UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: #keyPath(UIDevice.orientation))
    }
    
    /// 播放失败
    ///
    /// - Parameter error: 错误
    open func playFailed(error: PlayerError) {
        
    }
    
    /// 组件布局
    open func setUpUI() {
        backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        setUpTopView()
        setUpMiddelView()
        setUpBottomView()
    }
    
    /// 时间格式化为字符串
    ///
    /// - Parameter seconds: 秒
    /// - Returns: xx:xx 的格式
    open func formatSecondsToString(seconds: TimeInterval) -> String {
        if seconds.isNaN {
            return "00:00"
        }
        
        let interval = Int(seconds)
        let sec = Int(seconds.truncatingRemainder(dividingBy: 60))
        let min = interval / 60
        return String(format: "%02d:%02d", min, sec)
    }
}

extension ZDPlayerView {
    
    /// 播放
    func play() {
        playButton.isSelected = true
    }
    
    /// 暂停
    func pause() {
        playButton.isSelected = false
    }
    
    /// 播放组件动画展示
    func showPlayerControlAnimation() {
        bottomView.isHidden = false
        topView.isHidden = false
        isShowPlayerControl = true
        UIView.animate(withDuration: 0.5, animations: {
            self.bottomView.alpha = 1
            self.topView.alpha = 1
        }) { (_) in
            self.delayPlayControlViewDisappear()
        }
    }
    
    /// 播放组件动画隐藏
    func hiddenPlayerControlAnimation() {
        isShowPlayerControl = false
        UIView.animate(withDuration: 0.5, animations: {
            self.bottomView.alpha = 0
            self.topView.alpha = 0
        }) { (_) in
            self.bottomView.isHidden = true
            self.topView.isHidden = true
        }
    }
    
    /// 延迟播放组件消失
    func delayPlayControlViewDisappear() {
        timer?.invalidate()
        /// 这个地方我觉得不使用扩展分类,使用系统的方法,也不会导致循环引用
        timer = Timer.scheduledTimer(timeInterval: controlViewDuration, repeats: false) { [weak self] in
            self?.playControlViewShow(false)
        }
    }
    
    /// 获取声音进度条
    func getVolumeSlider() {
        //  引入MediaPlayer就是为了获取系统的声音进度条
        let volumeView = MPVolumeView()
        if let view = volumeView.subviews.first as? UISlider {
            volumeSlider = view
            lastSoundValue = volumeSlider.value
        }
    }
    
    /// 获取亮度进度条
    func getBrightnessSlider() {
        brightnessSlider = BrightnessView.instance()
    }
}

// MARK: - 屏幕旋转相关
extension ZDPlayerView {
    
    /// 添加设备方向变化的通知
    func addDeviceOrientationNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(statusBarOrientationWillChange(_:)), name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(statusBarOrientationDidChange(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    /// 设备方向即将变化的通知具体实现
    ///
    /// - Parameter notification: 通知
    @objc
    func statusBarOrientationWillChange(_ notification: Notification) {
        
        //  这个两个状态太过于相似都是不知道用什么好, 使用这个什么通知 那什么对应的值 另外 第一次拿UIDevice.current.orientation一般都会是unknown,但是UIDevice.current.orientation会有值
        
        //  设备方向
        let device = UIDevice.current.orientation
        //  界面方向
        let ui = UIApplication.shared.statusBarOrientation
        
        //  这里是为了记录非全屏状态下的frame和superview,便于从全屏退回的时候保持原来的状态
        if let userInfo = notification.userInfo, let number = userInfo[UIApplication.statusBarOrientationUserInfoKey] as? Int {
            let newOrientation = UIInterfaceOrientation(rawValue: number)
            if (lastOrientation == .portrait || lastOrientation == .unknown || lastOrientation == .portraitUpsideDown)
                && (newOrientation == .landscapeLeft || newOrientation == .landscapeRight) {
                parentView = superview
                viewFrame = frame
                print(viewFrame)
            }
            
            lastOrientation = newOrientation
        }
    }
    
    /// 设备方向已经变化的通知具体实现
    ///
    /// - Parameter notification: 通知
    @objc
    func statusBarOrientationDidChange(_ notification: Notification) {
        let orientation = UIApplication.shared.statusBarOrientation
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            onStatusBarOrientation(isFullScreen: true, orientation: orientation)
        case .portrait, .portraitUpsideDown:
            onStatusBarOrientation(isFullScreen: false, orientation: orientation)
        default:
            break
        }
    }
    
    /// 设备方向变化进而改变frame
    ///
    /// - Parameters:
    ///   - fullScreen: 是否全屏
    ///   - orientation: 设备方向
    func onStatusBarOrientation(isFullScreen: Bool, orientation: UIInterfaceOrientation) {
        if orientation == .landscapeLeft || orientation == .landscapeRight {
            let rectInWindow = convert(bounds, to: UIApplication.shared.keyWindow)
            frame = rectInWindow
            
            removeFromSuperview()
            
            UIApplication.shared.keyWindow?.addSubview(self)
            guard let superview = self.superview else {
                return
            }
            
            snp.remakeConstraints { (make) in
                make.width.equalTo(superview.bounds.width)
                make.height.equalTo(superview.bounds.height)
            }
            
            //systemConstraintUpdateToLandscape(superview: superview)
            
        }else if orientation == .portrait || orientation == .portraitUpsideDown {
            guard let parentView = self.parentView else {
                return
            }
            
            removeFromSuperview()
            
            parentView.addSubview(self)
            
            let frame = parentView.convert(viewFrame, to: UIApplication.shared.keyWindow)
            
            snp.remakeConstraints { (make) in
                make.centerX.equalTo(viewFrame.midX)
                make.centerY.equalTo(viewFrame.midY)
                make.width.equalTo(frame.width)
                make.height.equalTo(frame.height)
            }
            
            //systemConstraintUpdateToPortrait(frame: frame)
            
            viewFrame = .zero
            self.parentView = nil
        }
        
        self.isFullScreen = isFullScreen
        fullscreenButton.isSelected = isFullScreen
        delegate?.playerView(self, willFullscreen: isFullScreen)
    }
}

// MARK: - 界面搭建相关,功能按钮的布局还可以优化,这里仅仅实现了功能
extension ZDPlayerView {
    
    /// 上布局
    func setUpTopView() {
        addSubview(topView)
        topView.snp.makeConstraints { (make) in
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.top.equalTo(self)
            make.height.equalTo(44)
        }
        
        topView.addSubview(closeButton)
        closeButton.snp.makeConstraints { (make) in
            make.left.equalTo(topView).offset(10)
            make.centerY.equalTo(topView)
            make.height.equalTo(30)
            make.width.equalTo(30)
        }
        
        topView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.center.equalTo(topView)
        }
    }
    
    /// 中布局
    func setUpMiddelView() {
        addSubview(replayButton)
        replayButton.snp.makeConstraints { (make) in
            make.center.equalTo(self)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
        
        addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { (make) in
            make.center.equalTo(self)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
    }
    
    /// 下布局
    func setUpBottomView() {
        addSubview(bottomView)
        bottomView.snp.makeConstraints { (make) in
            make.left.equalTo(self)
            make.right.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(44)
        }
        
        bottomView.addSubview(playButton)
        playButton.snp.makeConstraints { (make) in
            make.left.equalTo(bottomView).offset(20)
            make.height.equalTo(25)
            make.width.equalTo(25)
            make.centerY.equalTo(bottomView)
        }
        
        bottomView.addSubview(soundButton)
        soundButton.snp.makeConstraints { (make) in
            make.left.equalTo(playButton.snp.right).offset(20)
            make.height.equalTo(25)
            make.width.equalTo(25)
            make.centerY.equalTo(bottomView)
        }
        
        bottomView.addSubview(fullscreenButton)
        fullscreenButton.snp.makeConstraints { (make) in
            make.centerY.equalTo(bottomView)
            make.right.equalTo(bottomView).offset(-10)
            make.height.equalTo(30)
            make.width.equalTo(30)
        }
        
        bottomView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { (make) in
            make.right.equalTo(fullscreenButton.snp.left).offset(-10)
            make.centerY.equalTo(bottomView)
            make.height.equalTo(30)
        }
        
        bottomView.addSubview(timeSlider)
        timeSlider.snp.makeConstraints { (make) in
            make.centerY.equalTo(playButton)
            make.right.equalTo(timeLabel.snp.left).offset(-10)
            make.left.equalTo(soundButton.snp.right).offset(25)
            make.height.equalTo(25)
        }
    }
    
    /// 播放按钮的点击事件
    ///
    /// - Parameter button: 按钮
    @objc
    func onPlay(_ button: UIButton) {
        button.isSelected ? player?.pause() : player?.play()
    }
    
    /// 重播按钮的点击事件
    ///
    /// - Parameter button: 按钮
    @objc
    func onReplay(_ button: UIButton) {
        guard let player = player, let url = player.contentURL else { return }
        player.loadVideo(url: url)
        player.play()
    }
    
    /// 关闭的点击事件
    ///
    /// - Parameter button: 按钮
    @objc
    func onClose(_ button: UIButton) {
        delegate?.playerView(self, didPressCloseButton: button)
    }
    
    /// 全屏按钮的点击事件
    ///
    /// - Parameter button: 按钮
    @objc
    func onFullScreen(_ button: UIButton) {
        button.isSelected = !button.isSelected
        isFullScreen = button.isSelected
        isFullScreen ? enterFullScreen() : exitFullscreen()
        delegate?.playerView(self, didPressFullscreenButton: button)
    }
    
    /// 静音按钮的点击事件
    ///
    /// - Parameter button: 按钮
    @objc
    func onSound(_ button: UIButton) {
        button.isSelected = !button.isSelected
        button.isSelected ? (volumeSlider.value = 0) : (volumeSlider.value = lastSoundValue)
    }
    
    /// 时间轴的值的值变化
    ///
    /// - Parameter sender: PlayerSlider
    @objc
    func timeSliderValueChanged(_ sender: PlayerSlider) {
        isTimeSliding = true
        
        if let totalDuration = player?.totalDuration {
            let currentTime = Double(sender.value) * totalDuration
            timeLabel.text = formatSecondsToString(seconds: currentTime) + " | " +  formatSecondsToString(seconds: totalDuration)
        }
    }
    
    /// 时间轴拖动
    ///
    /// - Parameter sender: PlayerSlider
    @objc
    func timeSliderTouchUpInside(_ sender: PlayerSlider) {
        isTimeSliding = true
        
        if let totalDuration = player?.totalDuration {
            let currentTime = Double(sender.value) * totalDuration
            player?.seekTime(currentTime) { [weak self] (finished) in
                if finished {
                    self?.isTimeSliding = false
                    self?.delayPlayControlViewDisappear()
                }
            }
            timeLabel.text = formatSecondsToString(seconds: currentTime) + " | " +  formatSecondsToString(seconds: totalDuration)
        }
    }
    
    /// 时间轴拖动按下
    /// 这个动作我暂时不知道怎么说
    /// - Parameter sender: PlayerSlider
    @objc
    func timeSliderTouchDown(_ sender: PlayerSlider) {
        isTimeSliding = true
        timer?.invalidate()
    }
}

// MARK: - 手势相关
extension ZDPlayerView {
    
    /// 添加手势
    func addGestureRecognizer() {
        addGestureRecognizer(singleTapGesture)
        addGestureRecognizer(doubleTapGesture)
        addGestureRecognizer(panGesture)
        
        singleTapGesture.require(toFail: doubleTapGesture)
    }
    
    /// 点击手势
    ///
    /// - Parameter tap: 手势
    @objc
    func onSingleTapGesture(_ tap: UITapGestureRecognizer) {
        isShowPlayerControl = !isShowPlayerControl
        playControlViewShow(isShowPlayerControl)
    }
    
    /// 双击手势
    ///
    /// - Parameter tap: 手势
    @objc
    func onDoubleTapGesture(_ tap: UITapGestureRecognizer) {
        guard let player = player else { return }
        switch player.state {
        case .playing:
            player.pause()
        case .pause:
            player.play()
        default:
            break
        }
    }
    
    /// 滑动手势
    ///
    /// - Parameter pan: 手势
    @objc
    func onPanGesture(_ pan: UIPanGestureRecognizer) {
        let translation = pan.translation(in: self)
        let location = pan.location(in: self)
        let velocity = pan.velocity(in: self)
        
        switch pan.state {
        case .began:
            let x = abs(translation.x)
            let y = abs(translation.y)
            
            // 纵向滑动
            if x < y {
                panGestureDirection = .vertical
                // 视频层的右半边为声音控制,左半边为亮度控制
                if location.x > bounds.width / 2 {
                    isVolume = true
                }else {
                    isVolume = false
                }
            }
            //  横向滑动
            else if x > y {
                guard player?.mediaFormat == .m3u8 else {
                    panGestureDirection = .horizontal
                    return
                }
            }else {
                
            }
        case .changed:
            
            // begin状态时候 可以监听到,但是x与y的值都是0,根本无法判断是横滑动还是竖滑动
            let x = abs(translation.x)
            let y = abs(translation.y)
            
            // 纵向滑动
            if x < y {
                panGestureDirection = .vertical
                // 视频层的右半边为声音控制,左半边为亮度控制
                if location.x > bounds.width / 2 {
                    isVolume = true
                }else {
                    isVolume = false
                }
            }
            //  横向滑动
            else if x > y {
                panGestureDirection = .horizontal
            }else {
                
            }
            
            switch panGestureDirection {
            case .horizontal:
                if player?.currentDuration == 0 {
                    return
                }
                sliderSeekTimeValue = onPanGestureHorizontal(velocityX: velocity.x)
            case .vertical:
                onPanGestureVertical(velocityY: velocity.y)
            }
        case .ended:
            switch panGestureDirection {
            case .horizontal:
                if sliderSeekTimeValue.isNaN {
                    return
                }
                player?.seekTime(sliderSeekTimeValue) { [weak self] (finished) in
                    self?.isTimeSliding = false
                    self?.delayPlayControlViewDisappear()
                }
            case .vertical:
                isVolume = false
            }
        default:
            break
        }
    }
    
    /// 横向滑动
    ///
    /// - Parameter veocityX: 滑动x的偏移
    /// - Returns: 时间
    func onPanGestureHorizontal(velocityX: CGFloat) -> TimeInterval {
        playControlViewShow(true)
        isTimeSliding = true
        timer?.invalidate()
        let value = timeSlider.value
        if let _ = player?.currentDuration, let totalDuration = player?.totalDuration {
            let sliderValue = TimeInterval(value) * totalDuration + TimeInterval(velocityX) / 100.0 * (TimeInterval(totalDuration) / 400)
            timeSlider.setValue(Float(sliderValue/totalDuration), animated: false)
            return sliderValue
        }else {
            return TimeInterval.nan
        }
    }
    
    /// 纵向滑动
    ///
    /// - Parameter velocityY: 滑动y的偏移
    func onPanGestureVertical(velocityY: CGFloat) {
        if isVolume {
            volumeSlider.value -= Float(velocityY / 10000)
            lastSoundValue = volumeSlider.value
            if BrightnessView.instance().alpha == 1 {
                BrightnessView.instance().alpha = 0
            }
            soundButton.isSelected = volumeSlider.value == 0
        }else {
            UIScreen.main.brightness -= velocityY / 10000
        }
    }
}

// MARK: - UIGestureRecognizer的代理
extension ZDPlayerView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let _ = touch.view as? ZDPlayerView {
            return true
        }
        return false
    }
}

// MARK: - iOS9.0之后的系统布局
extension ZDPlayerView {
    func setUpUIBySystem_iOS9() {
        backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        setUpTopViewBySystem_iOS9()
        setUpMiddelViewBySystem_iOS9()
        setUpBottomViewBySystem_iOS9()
    }
    
    
    /// 上布局
    func setUpTopViewBySystem_iOS9() {
        addSubview(topView)
        topView.translatesAutoresizingMaskIntoConstraints = false
        topView.leftAnchor.constraint(equalTo: leftAnchor).setIsActive(true)
        topView.rightAnchor.constraint(equalTo: rightAnchor).setIsActive(true)
        topView.topAnchor.constraint(equalTo: topAnchor).setIsActive(true)
        topView.heightAnchor.constraint(equalToConstant: 44).setIsActive(true)
        
        topView.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.leftAnchor.constraint(equalTo: topView.leftAnchor).setIsActive(true)
        closeButton.centerYAnchor.constraint(equalTo: topView.centerYAnchor).setIsActive(true)
        closeButton.heightAnchor.constraint(equalToConstant: 30).setIsActive(true)
        closeButton.widthAnchor.constraint(equalToConstant: 30).setIsActive(true)
        
        topView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leftAnchor.constraint(equalTo: closeButton.rightAnchor).setIsActive(true)
        titleLabel.rightAnchor.constraint(equalTo: topView.rightAnchor, constant: -30).setIsActive(true)
        titleLabel.heightAnchor.constraint(equalToConstant: 44).setIsActive(true)
        titleLabel.widthAnchor.constraint(equalToConstant: bounds.width - 60).setIsActive(true)
    }
    
    /// 中布局
    func setUpMiddelViewBySystem_iOS9() {
        addSubview(replayButton)
        replayButton.translatesAutoresizingMaskIntoConstraints = false
        replayButton.centerXAnchor.constraint(equalTo: centerXAnchor).setIsActive(true)
        replayButton.centerYAnchor.constraint(equalTo: centerYAnchor).setIsActive(true)
        replayButton.heightAnchor.constraint(equalToConstant: 30).setIsActive(true)
        replayButton.widthAnchor.constraint(equalToConstant: 30).setIsActive(true)
        
        addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor).setIsActive(true)
        loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor).setIsActive(true)
        loadingIndicator.heightAnchor.constraint(equalToConstant: 30).setIsActive(true)
        loadingIndicator.widthAnchor.constraint(equalToConstant: 30).setIsActive(true)
    }
    
    /// 下布局
    func setUpBottomViewBySystem_iOS9() {
        addSubview(bottomView)
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.leftAnchor.constraint(equalTo: leftAnchor).setIsActive(true)
        bottomView.rightAnchor.constraint(equalTo: rightAnchor).setIsActive(true)
        bottomView.bottomAnchor.constraint(equalTo: bottomAnchor).setIsActive(true)
        bottomView.heightAnchor.constraint(equalToConstant: 44).setIsActive(true)
        bottomView.widthAnchor.constraint(equalToConstant: bounds.width).setIsActive(true)
        
        bottomView.addSubview(playButton)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.leftAnchor.constraint(equalTo: bottomView.leftAnchor, constant: 20).setIsActive(true)
        playButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).setIsActive(true)
        playButton.heightAnchor.constraint(equalToConstant: 25).setIsActive(true)
        playButton.widthAnchor.constraint(equalToConstant: 25).setIsActive(true)
        
        bottomView.addSubview(soundButton)
        soundButton.translatesAutoresizingMaskIntoConstraints = false
        soundButton.leftAnchor.constraint(equalTo: playButton.rightAnchor, constant: 20).setIsActive(true)
        soundButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).setIsActive(true)
        soundButton.heightAnchor.constraint(equalToConstant: 25).setIsActive(true)
        soundButton.widthAnchor.constraint(equalToConstant: 25).setIsActive(true)
        
        bottomView.addSubview(fullscreenButton)
        fullscreenButton.translatesAutoresizingMaskIntoConstraints = false
        fullscreenButton.rightAnchor.constraint(equalTo: bottomView.rightAnchor, constant: -10).setIsActive(true)
        fullscreenButton.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).setIsActive(true)
        fullscreenButton.heightAnchor.constraint(equalToConstant: 30).setIsActive(true)
        fullscreenButton.widthAnchor.constraint(equalToConstant: 30).setIsActive(true)
        
        bottomView.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.rightAnchor.constraint(equalTo: fullscreenButton.leftAnchor, constant: -10).setIsActive(true)
        timeLabel.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).setIsActive(true)
        timeLabel.heightAnchor.constraint(equalToConstant: 30).setIsActive(true)
        
        bottomView.addSubview(timeSlider)
        timeSlider.translatesAutoresizingMaskIntoConstraints = false
        timeSlider.rightAnchor.constraint(equalTo: timeLabel.leftAnchor, constant: -10).setIsActive(true)
        timeSlider.centerYAnchor.constraint(equalTo: bottomView.centerYAnchor).setIsActive(true)
        timeSlider.leftAnchor.constraint(equalTo: soundButton.rightAnchor, constant: 25).setIsActive(true)
        timeSlider.heightAnchor.constraint(equalToConstant: 25).setIsActive(true)
    }
}

// MARK: - iOS通用的系统布局
extension ZDPlayerView {
    func setUpUIBySystem() {
        backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        setUpTopViewBySystem()
        setUpMiddelViewBySystem()
        setUpBottomViewBySystem()
    }
    
    /// 上布局
    func setUpTopViewBySystem() {
        addSubview(topView)
        topView.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: topView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: topView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: topView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: topView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44))
        
        
        topView.addSubview(closeButton)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: closeButton, attribute: .left, relatedBy: .equal, toItem: topView, attribute: .left, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: closeButton, attribute: .centerY, relatedBy: .equal, toItem: topView, attribute: .centerY, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: closeButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30))
        addConstraint(NSLayoutConstraint(item: closeButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 30))
        
        topView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .centerX, relatedBy: .equal, toItem: topView, attribute: .centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: topView, attribute: .centerY, multiplier: 1, constant: 0))
        
    }
    
    /// 中布局
    func setUpMiddelViewBySystem() {
        addSubview(replayButton)
        replayButton.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: replayButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: replayButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: replayButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30))
        addConstraint(NSLayoutConstraint(item: replayButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 30))
        
        addSubview(loadingIndicator)
        addConstraint(NSLayoutConstraint(item: loadingIndicator, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: loadingIndicator, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: loadingIndicator, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30))
        addConstraint(NSLayoutConstraint(item: loadingIndicator, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 30))
    }
    
    /// 下布局
    func setUpBottomViewBySystem() {
        addSubview(bottomView)
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: bottomView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: bottomView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: bottomView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: bottomView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44))
        
        bottomView.addSubview(playButton)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: playButton, attribute: .left, relatedBy: .equal, toItem: bottomView, attribute: .left, multiplier: 1, constant: 20))
        addConstraint(NSLayoutConstraint(item: playButton, attribute: .centerY, relatedBy: .equal, toItem: bottomView, attribute: .centerY, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: playButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 25))
        addConstraint(NSLayoutConstraint(item: playButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 25))
        
        bottomView.addSubview(soundButton)
        soundButton.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: soundButton, attribute: .left, relatedBy: .equal, toItem: playButton, attribute: .right, multiplier: 1, constant: 20))
        addConstraint(NSLayoutConstraint(item: soundButton, attribute: .centerY, relatedBy: .equal, toItem: bottomView, attribute: .centerY, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: soundButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 25))
        addConstraint(NSLayoutConstraint(item: soundButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 25))
        
        bottomView.addSubview(fullscreenButton)
        fullscreenButton.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: fullscreenButton, attribute: .right, relatedBy: .equal, toItem: bottomView, attribute: .right, multiplier: 1, constant: -10))
        addConstraint(NSLayoutConstraint(item: fullscreenButton, attribute: .centerY, relatedBy: .equal, toItem: bottomView, attribute: .centerY, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: fullscreenButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 30))
        addConstraint(NSLayoutConstraint(item: fullscreenButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30))
        
        bottomView.addSubview(timeLabel)
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: timeLabel, attribute: .right, relatedBy: .equal, toItem: fullscreenButton, attribute: .left, multiplier: 1, constant: -10))
        addConstraint(NSLayoutConstraint(item: timeLabel, attribute: .centerY, relatedBy: .equal, toItem: bottomView, attribute: .centerY, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: timeLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30))
        
        bottomView.addSubview(timeSlider)
        timeSlider.translatesAutoresizingMaskIntoConstraints = false
        addConstraint(NSLayoutConstraint(item: timeSlider, attribute: .right, relatedBy: .equal, toItem: timeLabel, attribute: .left, multiplier: 1, constant: -10))
        addConstraint(NSLayoutConstraint(item: timeSlider, attribute: .centerY, relatedBy: .equal, toItem: bottomView, attribute: .centerY, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: timeSlider, attribute: .left, relatedBy: .equal, toItem: soundButton, attribute: .right, multiplier: 1, constant: 25))
        addConstraint(NSLayoutConstraint(item: timeSlider, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 25))
    }
    
    /// 系统布局更新到横屏
    func systemConstraintUpdateToLandscape(superview: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        removeConstraints(constraints)
        addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: superview.bounds.width))
        addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: superview.bounds.height))
        setUpUIBySystem()
    }

    /// 系统布局更新到竖屏
    func systemConstraintUpdateToPortrait(frame: CGRect) {
        translatesAutoresizingMaskIntoConstraints = false
        removeConstraints(constraints)
        addConstraint(NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: frame.width))
        addConstraint(NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: frame.height))
        setUpUIBySystem()
    }
}

extension NSLayoutConstraint {
    func setIsActive(_ isActive: Bool) {
        self.isActive = isActive
    }
}
