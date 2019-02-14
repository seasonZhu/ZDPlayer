//
//  PlayerCacheMediaWorker.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

public class PlayerCacheMediaWorker {
    public fileprivate(set) var cacheMediaConfiguration: PlayerCacheMediaConfiguration?
    public fileprivate(set) var initError: Error?
    
    private var readFileHandle: FileHandle?
    private var writeFileHandle: FileHandle?
    private var filePath: String
    private var currentOffset: UInt64?
    private var startWriteDate: Date?
    private var writeBytes: Double = 0.0
    private var isWritting: Bool = false
    
    private let writeFileQueue: DispatchQueue
    private let kPackageLength = 204800
    
    public init(url: URL) {
        let path = PlayerCacheManager.cacheFilePath(for: url)
        writeFileQueue = DispatchQueue(label: "com.lostsakura.www.writeFileQueue")
        filePath = path
        
        let cacheFolder = (path as NSString).deletingLastPathComponent
        var err: Error?
        if !FileManager.default.fileExists(atPath: cacheFolder) {
            do {
                try FileManager.default.createDirectory(atPath: cacheFolder, withIntermediateDirectories: true, attributes: nil)
            }catch let error {
                err = error
            }
        }
        
        if err == nil {
            if !FileManager.default.fileExists(atPath: path) {
                FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
            }
            let fileUrl = URL(fileURLWithPath: path)
            do {
                try readFileHandle = FileHandle(forReadingFrom: fileUrl)
                
                try writeFileHandle = FileHandle(forWritingTo: fileUrl)
                cacheMediaConfiguration = PlayerCacheMediaConfiguration.configuration(filePath: path)
                cacheMediaConfiguration?.url = url
            }catch let error {
                err = error
            }
            
        }
        
        initError = err
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        save()
        readFileHandle?.closeFile()
        writeFileHandle?.closeFile()
    }
}

extension PlayerCacheMediaWorker {
    public func writeCache(data: Data, forRange range: NSRange, callback: (Bool) -> Void) {
        writeFileQueue.sync {
            if let _ = writeFileHandle?.seek(toFileOffset: UInt64(range.location)), let _ = writeFileHandle?.write(data) {
                writeBytes += Double(data.count)
                cacheMediaConfiguration?.addCache(segment: range)
                callback(true)
            }else {
                callback(false)
            }
        }
    }
    
    public func readCache(forRange range: NSRange) -> Data? {
        readFileHandle?.seek(toFileOffset: UInt64(range.location))
        let data = readFileHandle?.readData(ofLength: range.length)
        return data
    }
    
    public func cachedDataActions(forRange range:NSRange) -> [PlayerCacheAction] {
        var actions = [PlayerCacheAction]()
        if range.location == NSNotFound {
            return actions
        }
        
        let endOffset = range.location + range.length
        
        if let cacheSegments = cacheMediaConfiguration?.cacheSegments {
            for value in cacheSegments {
                let segmentRange = value.rangeValue
                let intersctionRange = NSIntersectionRange(range, segmentRange)
                if intersctionRange.length > 0 {
                    let package = intersctionRange.length / kPackageLength
                    for i in 0 ... package {
                        let offset = i * kPackageLength
                        let offsetLocation = intersctionRange.location + offset
                        let maxLocation = intersctionRange.location + intersctionRange.length
                        let length = offsetLocation + kPackageLength > maxLocation ? maxLocation - offsetLocation : kPackageLength
                        let range = NSMakeRange(offsetLocation, length)
                        let action = PlayerCacheAction(type: .local, range: range)
                        actions.append(action)
                    }
                } else if segmentRange.location >= endOffset {
                    break
                }
            }
        }
        
        if actions.count == 0 {
            let action = PlayerCacheAction(type: .remote, range: range)
            actions.append(action)
        }else {
            var localRemoteActions = [PlayerCacheAction]()
            for (index, value) in actions.enumerated() {
                let actionRange = value.range
                
                if index == 0 {
                    if range.location < actionRange.location {
                        let range = NSMakeRange(range.location, actionRange.location - range.location)
                        let action = PlayerCacheAction(type: .remote, range: range)
                        localRemoteActions.append(action)
                    }
                    localRemoteActions.append(value)
                }else {
                    if let lastAction = localRemoteActions.last {
                        let lastOffset = lastAction.range.location + lastAction.range.length
                        if actionRange.location > lastOffset {
                            let range = NSMakeRange(lastOffset, actionRange.location - lastOffset)
                            let action = PlayerCacheAction(type: .remote, range: range)
                            localRemoteActions.append(action)
                        }
                    }
                    localRemoteActions.append(value)
                }
                
                if index == actions.count - 1 {
                    let localEndOffset = actionRange.location + actionRange.length
                    if endOffset > localEndOffset {
                        let range = NSMakeRange(localEndOffset, endOffset)
                        let action = PlayerCacheAction(type: .remote, range: range)
                        localRemoteActions.append(action)
                    }
                }
            }
            
            actions = localRemoteActions
        }
        
        return actions
    }
    
    public func set(cacheMedia: PlayerCacheMedia) -> Bool {
        cacheMediaConfiguration?.cacheMedia = cacheMedia
        if let _ = writeFileHandle?.truncateFile(atOffset: UInt64(cacheMedia.contentLength)), let _ = writeFileHandle?.synchronizeFile() {
            return true
        }else {
            return false
        }
    }
    
    public func save() {
        writeFileQueue.sync {
            writeFileHandle?.synchronizeFile()
            cacheMediaConfiguration?.save()
        }
    }
    
    public func startWritting() {
        if !isWritting {
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
        isWritting = true
        startWriteDate = Date()
        writeBytes = 0.0
    }
    
    public func finishWritting() {
        if isWritting {
            isWritting = false
            NotificationCenter.default.removeObserver(self)
            if let startWriteDate = startWriteDate {
                let time = Date().timeIntervalSince(startWriteDate)
                cacheMediaConfiguration?.add(downloadedBytes: UInt64(writeBytes), time: time)
            }
        }
    }
    
    @objc
    func applicationDidEnterBackground(_ notification: Notification) {
        save()
    }
}
