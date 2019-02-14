//
//  PlayerCacheConfiguration.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

public class PlayerCacheConfiguration {
    public var maxCachePeriodInSecond: TimeInterval = 60 * 60 * 24 * 7
    
    public var maxDiskCacheSize: UInt = 0
}
