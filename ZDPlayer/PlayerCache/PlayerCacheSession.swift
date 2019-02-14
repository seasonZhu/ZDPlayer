//
//  PlayerCacheSession.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

public class PlayerCacheSession {
    public fileprivate(set) var downloadQueue: OperationQueue
    
    public static let share = PlayerCacheSession()
    private init() {
        downloadQueue = OperationQueue()
        downloadQueue.name = "com.lostsakura.www.downloadQueueSession"
    }
}
