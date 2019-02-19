//
//  CacheAction.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

/// 缓存类型
///
/// - local: 本地文件缓存
/// - remote: 服务器文件缓存
public enum CacheType {
    case local
    case remote
}

/// 缓存行为
public struct CacheAction {
    
    /// 缓存类型
    public let type: CacheType
    
    /// 缓存数据段的range
    public let range: NSRange

    /// 初始化方法
    ///
    /// - Parameters:
    ///   - type: 缓存类型
    ///   - range: 缓存数据段的range
    public init(type: CacheType, range: NSRange) {
        self.type = type
        self.range = range
    }
}

extension CacheAction: Hashable {
    public var hashValue: Int {
        return String(format: "%@%@", NSStringFromRange(range), String(describing: type)).hashValue
    }
    
    public static func == (lhs: CacheAction, rhs: CacheAction) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension CacheAction: CustomStringConvertible {
    public var description: String {
        return "type: \(type), range: \(range)"
    }
}
