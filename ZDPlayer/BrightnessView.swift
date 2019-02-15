//
//  SystemBrightnessView.swift
//  ZDPlayer
//
//  Created by season on 2019/2/15.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

public class BrightnessView: UIView {
    
    public static let share = BrightnessView()
    
    private lazy var backImage: UIImageView = {
        let backImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 79, height: 76))
        backImage.image = BundleManager.image(named: "brightness")
        return backImage
    }()
    
    private lazy var title: UILabel = {
        let title = UILabel(frame: CGRect(x: 0, y: 5, width: bounds.size.width, height: 30))
        title.font = UIFont.boldSystemFont(ofSize: 16)
        title.textColor = UIColor(red: 0.25, green: 0.22, blue: 0.21, alpha: 1.00)
        title.textAlignment = .center
        title.text = "亮度"
        return title
    }()
    
    private lazy var brightnessLevelView: UIView = {
        let brightnessLevelView = UIView(frame: CGRect(x: 13, y: 132, width: bounds.size.width - 26, height: 7))
        brightnessLevelView.backgroundColor = UIColor(red: 0.25, green: 0.22, blue: 0.21, alpha: 1.00)
        return brightnessLevelView
    }()
    
    private lazy var tipArray = [UIImageView]()
    
    private var timer: Timer?
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        frame = CGRect(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height * 0.5 - 20, width: 155, height: 155)
        backgroundColor = UIColor.white
        layer.cornerRadius = 10
        layer.masksToBounds = true
        
        // 毛玻璃效果
        let blurEffect = UIBlurEffect(style: .light)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)
        visualEffectView.alpha = 1
        visualEffectView.frame = bounds
        addSubview(visualEffectView)
        
        addSubview(backImage)
        addSubview(title)
        addSubview(brightnessLevelView)
        
        createTips()
        addStatusBarNotification()
        addKVOObserver()
        
        alpha = 0.0
    }
    
    private func createTips() {

        let tipW: CGFloat = (brightnessLevelView.bounds.size.width - 17) / 16
        let tipH: CGFloat = 5
        let tipY: CGFloat = 1
        
        for i in 0..<16 {
            let tipX: CGFloat = CGFloat(i) * (tipW + 1) + 1
            let image = UIImageView()
            image.backgroundColor = UIColor.white
            image.frame = CGRect(x: tipX, y: tipY, width: tipW, height: tipH)
            brightnessLevelView.addSubview(image)
            tipArray.append(image)
        }
        updateBrightnessLevel(UIScreen.main.brightness)
    }
    
    func addStatusBarNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.statusBarOrientationNotification(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    @objc
    func statusBarOrientationNotification(_ notify: Notification?) {
        setNeedsLayout()
    }
    
    func addKVOObserver() {
        UIScreen.main.addObserver(self, forKeyPath: #keyPath(UIScreen.brightness), options: .new, context: nil)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == #keyPath(UIScreen.brightness), let levelValue = change?[.newKey] as? NSNumber  {
            let level = CGFloat(levelValue.floatValue)
            removeTimer()
            appearBrightnessView()
            updateBrightnessLevel(level)
        }
        
        
    }
    
    // MARK: - Brightness显示 隐藏
    func appearBrightnessView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.alpha = 1
        }) { finished in
            self.addtimer()
        }
    }
    
    @objc
    func disAppearBrightnessView() {
        if alpha == 1.0 {
            UIView.animate(withDuration: 0.5, animations: {
                self.alpha = 0.0
            }) { finished in
                self.removeTimer()
            }
        }
    }
    
    // MARK: - 定时器
    func addtimer() {
        if let _ = timer {
            return
        }
        timer = Timer(timeInterval: 2, target: self, selector: #selector(disAppearBrightnessView), userInfo: nil, repeats: false)
        RunLoop.main.add(timer!, forMode: .default)
    }
    
    func removeTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - 更新亮度值
    func updateBrightnessLevel(_ brightnessLevel: CGFloat) {
        let stage: CGFloat = 1 / 15.0
        let level = Int(brightnessLevel / stage)
        for i in 0..<tipArray.count {
            let img: UIImageView? = tipArray[i]
            if i <= level {
                img?.isHidden = false
            } else {
                img?.isHidden = true
            }
        }
    }
    
    // MARK: - 更新布局
    public override func layoutSubviews() {
        super.layoutSubviews()
        //InterfaceOrientation值
        let currInterfaceOrientation: UIInterfaceOrientation = UIApplication.shared.statusBarOrientation
        switch currInterfaceOrientation {
        case .portrait, .portraitUpsideDown:
            center = CGPoint(x: UIScreen.main.bounds.width * 0.5, y: (UIScreen.main.bounds.height - 10) * 0.5)
        case .landscapeLeft, .landscapeRight:
            center = CGPoint(x: UIScreen.main.bounds.width * 0.5, y: UIScreen.main.bounds.height * 0.5)
        default:
            break
        }
        backImage.center = CGPoint(x: 155 * 0.5, y: 155 * 0.5)
        superview?.bringSubviewToFront(self)
    }
    
    deinit {
        UIScreen.main.removeObserver(self, forKeyPath: #keyPath(UIScreen.brightness))
        NotificationCenter.default.removeObserver(self)
    }
}
