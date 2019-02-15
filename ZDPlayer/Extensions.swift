//
//  Extensions.swift
//  ZDPlayer
//
//  Created by season on 2019/2/12.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

/*
 一些分类的使用
 */

extension Timer {
    
    /// Timer将userInfo作为callback的定时方法
    /// 目的是为了防止Timer导致的内存泄露
    /// - Parameters:
    ///   - timeInterval: 时间间隔
    ///   - repeats: 是否重复
    ///   - callback: 回调方法
    /// - Returns: Timer
    public static func scheduledTimer(timeInterval: TimeInterval, repeats: Bool, with callback: @escaping () -> Void) -> Timer {
        return scheduledTimer(timeInterval: timeInterval,
                              target: self,
                              selector: #selector(callbackInvoke(_:)),
                              userInfo: callback,
                              repeats: repeats)
    }
    
    /// 私有的定时器实现方法
    ///
    /// - Parameter timer: 定时器
    @objc
    private static func callbackInvoke(_ timer: Timer) {
        guard let callback = timer.userInfo as? () -> Void else { return }
        callback()
    }
}


extension UIButton {
    
    /// 设置按钮的点击响应区域扩大
    /// 这是一个全局的设置,一旦设置了,那么全局的按钮的都会受影响,慎重考虑
    /// - Parameters:
    ///   - isNeedLargerHitArea: 是否需要设置点击响应区域扩大
    ///   - minimumHitArea: 最小的点击区域
    public static func setButtonIsNeedLargerHitArea(isNeedLargerHitArea: Bool = false, minimumHitArea: CGSize = CGSize(width: 44, height: 44)) {
        self.isNeedLargerHitArea = isNeedLargerHitArea
        self.minimumHitArea = minimumHitArea
    }
    
    //  https://stackoverflow.com/questions/808503/uibutton-making-the-hit-area-larger-than-the-default-hit-area/13977921
    
    /// 是否需要设置点击响应区域扩大
    private static var minimumHitArea = CGSize(width: 44, height: 44)
    
    /// 最小的点击区域
    private static var isNeedLargerHitArea = false
    
    /// 重写hitTest
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        
        if UIButton.isNeedLargerHitArea {
            // if the button is hidden/disabled/transparent it can't be hit
            if self.isHidden || !self.isUserInteractionEnabled || self.alpha < 0.01 { return nil }
            
            // increase the hit frame to be at least as big as `minimumHitArea`
            let buttonSize = self.bounds.size
            let widthToAdd = max(UIButton.minimumHitArea.width - buttonSize.width, 0)
            let heightToAdd = max(UIButton.minimumHitArea.height - buttonSize.height, 0)
            let largerFrame = self.bounds.insetBy(dx: -widthToAdd / 2, dy: -heightToAdd / 2)
            
            // perform hit test on larger frame
            return (largerFrame.contains(point)) ? super.hitTest(point, with: event) : nil
        }
        
        return super.hitTest(point, with: event)
    }
    
}

extension UIImage {
    
    /// 图片的size重绘
    ///
    /// - Parameter size: 新的size
    /// - Returns: 新图片
    func scaledToSize(_ size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer {
            UIGraphicsEndImageContext()
        }
        
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

/// frame的Bundle管理
class BundleManager {
    
    /// 获取frame的Bundle
    ///
    /// - Returns: Bundle
    public static func frameworkBundle() -> Bundle {
        return Bundle(for: ZDPlayer.self)
    }
    
    /// 资源路径
    ///
    /// - Parameters:
    ///   - name: 资源名称
    ///   - ext: 资源类型
    /// - Returns: 路径
    public static func path(forResource name: String?, ofType ext: String?) -> String? {
        let bundle = frameworkBundle()
        let path = bundle.path(forResource: name, ofType: ext)
        return path
    }
    
    /// 资源图片
    ///
    /// - Parameter name: 图片名称
    /// - Returns: 图片
    public static func image(named name: String) -> UIImage? {
        let bundle = frameworkBundle()
        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
}
