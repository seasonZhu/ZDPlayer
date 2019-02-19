//
//  CacheMediaWorker.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

/// 多媒体工作器
public class CacheMediaWorker {
    
    /// 多媒体下载信息
    public private(set) var mediaInfo: CacheMediaInfo?
    
    /// 初始化标记的错误
    public private(set) var initError: Error?
    
    /// 读Handle
    private var readFileHandle: FileHandle?
    
    /// 写Handle
    private var writeFileHandle: FileHandle?
    
    /// 文件路径
    private var filePath: String
    
    /// 当前的数据偏移
    private var currentOffset: UInt64?
    
    /// 开始写入的数据
    private var startWriteDate: Date?
    
    /// 写入的进度
    private var writeBytes: Double = 0.0
    
    /// 是否正在写入数据
    private var isWritting: Bool = false
    
    /// 写文件的队列
    private let writeFileQueue: DispatchQueue
    
    /// 数据包长
    private let kPackageLength = 204800
    
    /// 初始化方法
    ///
    /// - Parameter url: 资源网址
    public init(url: URL) {
        let path = CacheManager.cacheFilePath(for: url)
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
            
            do {
                let fileUrl = URL(fileURLWithPath: path)
                try readFileHandle = FileHandle(forReadingFrom: fileUrl)
                
            }catch let error {
                err = error
            }
            
        }
        
        if err == nil {
            if !FileManager.default.fileExists(atPath: path) {
                FileManager.default.createFile(atPath: path, contents: nil, attributes: nil)
            }
            
            do {
                let fileUrl = URL(fileURLWithPath: path)
                try writeFileHandle = FileHandle(forWritingTo: fileUrl)
                mediaInfo = CacheMediaInfo.getMediaInfo(filePath: path)
                mediaInfo?.url = url
                
            }catch let error {
                err = error
            }
            
        }
        
        initError = err
    }
    
    /// 析构函数
    deinit {
        NotificationCenter.default.removeObserver(self)
        save()
        readFileHandle?.closeFile()
        writeFileHandle?.closeFile()
    }
}

extension CacheMediaWorker {
    
    /// 写入缓存数据
    ///
    /// - Parameters:
    ///   - data: 数据
    ///   - range: 数据的range
    ///   - callback: 是否写入成功
    public func writeCache(data: Data, forRange range: NSRange, callback: (Bool) -> Void) {
        writeFileQueue.sync {
            if let _ = writeFileHandle?.seek(toFileOffset: UInt64(range.location)), let _ = writeFileHandle?.write(data) {
                writeBytes += Double(data.count)
                mediaInfo?.addCache(segment: range)
                callback(true)
            }else {
                callback(false)
            }
        }
    }
    
    /// 读取缓存数据段
    ///
    /// - Parameter range: 数据的range
    /// - Returns: 数据
    public func readCache(forRange range: NSRange) -> Data? {
        readFileHandle?.seek(toFileOffset: UInt64(range.location))
        let data = readFileHandle?.readData(ofLength: range.length)
        return data
    }
    
    /// 通过数据的range获取缓存行为
    ///
    /// - Parameter range: 数据的range
    /// - Returns: 连续的缓存行为数组
    public func cachedDataActions(forRange range: NSRange) -> [CacheAction] {
        var actions = [CacheAction]()
        if range.location == NSNotFound {
            return actions
        }
        
        let endOffset = range.location + range.length
        
        if let cacheSegments = mediaInfo?.cacheSegments {
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
                        let action = CacheAction(type: .local, range: range)
                        actions.append(action)
                    }
                } else if segmentRange.location >= endOffset {
                    break
                }
            }
        }
        
        if actions.count == 0 {
            let action = CacheAction(type: .remote, range: range)
            actions.append(action)
        }else {
            var localRemoteActions = [CacheAction]()
            for (index, value) in actions.enumerated() {
                let actionRange = value.range
                
                if index == 0 {
                    if range.location < actionRange.location {
                        let range = NSMakeRange(range.location, actionRange.location - range.location)
                        let action = CacheAction(type: .remote, range: range)
                        localRemoteActions.append(action)
                    }
                    localRemoteActions.append(value)
                }else {
                    if let lastAction = localRemoteActions.last {
                        let lastOffset = lastAction.range.location + lastAction.range.length
                        if actionRange.location > lastOffset {
                            let range = NSMakeRange(lastOffset, actionRange.location - lastOffset)
                            let action = CacheAction(type: .remote, range: range)
                            localRemoteActions.append(action)
                        }
                    }
                    localRemoteActions.append(value)
                }
                
                if index == actions.count - 1 {
                    let localEndOffset = actionRange.location + actionRange.length
                    if endOffset > localEndOffset {
                        let range = NSMakeRange(localEndOffset, endOffset)
                        let action = CacheAction(type: .remote, range: range)
                        localRemoteActions.append(action)
                    }
                }
            }
            
            actions = localRemoteActions
        }
        
        return actions
    }
    
    /// set CacheMedia
    ///
    /// - Parameter cacheMedia: CacheMedia
    /// - Returns: set是否成功
    public func set(cacheMedia: CacheMedia) -> Bool {
        mediaInfo?.cacheMedia = cacheMedia
        if let _ = writeFileHandle?.truncateFile(atOffset: UInt64(cacheMedia.contentLength)), let _ = writeFileHandle?.synchronizeFile() {
            return true
        }else {
            return false
        }
    }
    
    /// 保存
    public func save() {
        writeFileQueue.sync {
            writeFileHandle?.synchronizeFile()
            mediaInfo?.save()
        }
    }
    
    /// 开始写入
    public func startWritting() {
        if !isWritting {
            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        }
        isWritting = true
        startWriteDate = Date()
        writeBytes = 0.0
    }
    
    /// 结束写入
    public func finishWritting() {
        if isWritting {
            isWritting = false
            NotificationCenter.default.removeObserver(self)
            if let startWriteDate = startWriteDate {
                let time = Date().timeIntervalSince(startWriteDate)
                mediaInfo?.addDownloadInfo(downloadedBytes: UInt64(writeBytes), time: time)
            }
        }
    }
    
    /// 开始写入的时候程序进入后台的操作
    ///
    /// - Parameter notification: 通知
    @objc
    func applicationDidEnterBackground(_ notification: Notification) {
        save()
    }
}
