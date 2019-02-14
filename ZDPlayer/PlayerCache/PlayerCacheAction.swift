//
//  PlayerCacheAction.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

public enum PlayerCacheActionType {
    case local
    case remote
}

public struct PlayerCacheAction {
    public let type: PlayerCacheActionType
    public let range: NSRange

    public init(type: PlayerCacheActionType, range: NSRange) {
        self.type = type
        self.range = range
    }
}

extension PlayerCacheAction: Hashable {
    public var hashValue: Int {
        return String(format: "%@%@", NSStringFromRange(range), String(describing: type)).hashValue
    }
    
    public static func == (lhs: PlayerCacheAction, rhs: PlayerCacheAction) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension PlayerCacheAction: CustomStringConvertible {
    public var description: String {
        return "type: \(type), range: \(range)"
    }
}
