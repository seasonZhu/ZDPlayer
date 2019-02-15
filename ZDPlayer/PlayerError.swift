//
//  PlayerError.swift
//  ZDPlayer
//
//  Created by season on 2019/2/12.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation
import AVFoundation

/// 播放错误
public struct PlayerError {
    var error: Error?
    var playerItemErrorLogEvent : [AVPlayerItemErrorLogEvent]?
    var extendedLogData : Data?
    var extendedLogDataStringEncoding : UInt?
}

extension PlayerError: CustomStringConvertible {
    public var description: String {
        return "ZDPlayer Log -------------------------- \n error: \(String(describing: error))\n playerItemErrorLogEvent: \(String(describing: playerItemErrorLogEvent))\n extendedLogData: \(String(describing: extendedLogData))\n extendedLogDataStringEncoding \(String(describing: extendedLogDataStringEncoding))\n --------------------------"
    }
}
