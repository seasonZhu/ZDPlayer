//
//  PlayerCacheMediaConfiguration.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

public class PlayerCacheMediaConfiguration: NSCoding {
    
    public private(set) var filePath: String?
    public private(set) var cacheSegments = [NSValue]()
    public var cacheMedia: PlayerCacheMedia?
    public var url: URL?
    
    private let cacheSegmentQueue: DispatchQueue
    private let cacheDownloadInfoQueue: DispatchQueue
    private var fileName: String?
    private var downloadInfo = [(downloadedBytes: UInt64, time: TimeInterval)]() // 元组是否可以被序列化 这个是个问题
    
    /// 下载速度 kB/s
    public private(set) var downloadSpeed: Double? {
        didSet {
            var bytes: UInt64 = 0
            var time: TimeInterval = 0.0
            if downloadInfo.count > 0 {
                cacheDownloadInfoQueue.sync {
                    for tuple in downloadInfo {
                        bytes += tuple.downloadedBytes
                        time += tuple.time
                    }
                }
            }
            downloadSpeed = Double(bytes) / 1024.0 / time
        }
    }
    
    /// 已下载的字节数
    public private(set) var downloadedBytes: Int64? {
        didSet {
            var bytes = 0
            cacheSegmentQueue.sync {
                bytes = cacheSegments.reduce(0) { (result, value) in
                    return result + value.rangeValue.length
                }
            }
            downloadedBytes = Int64(bytes)
        }
    }
    
    /// 下载进度
    public private(set) var progress: Double = 0.0 {
        didSet {
            if let contentLength = cacheMedia?.contentLength, let downloadedBytes = downloadedBytes {
                progress = Double(downloadedBytes / contentLength)
            }
        }
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(fileName, forKey: "fileName")
        aCoder.encode(cacheSegments, forKey: "cacheSegments")
        aCoder.encode(downloadInfo, forKey: "downloadInfo")
        aCoder.encode(cacheMedia, forKey: "cacheMedia")
        aCoder.encode(url, forKey: "url")
    }
    
    public init() {
        cacheSegmentQueue = DispatchQueue(label: "com.lostsakura.www.CacheSegmentQueue")
        cacheDownloadInfoQueue = DispatchQueue(label: "com.lostsakura.www.CacheDownloadInfoQueue")
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        guard let fileName = aDecoder.decodeObject(forKey: "fileName") as? String,
            let cacheSegments = aDecoder.decodeObject(forKey:"cacheSegments") as? [NSValue],
            let downloadInfo = aDecoder.decodeObject(forKey:"downloadInfo") as? [(UInt64, TimeInterval)],
            let cacheMedia = aDecoder.decodeObject(forKey:"cacheMedia") as? PlayerCacheMedia,
            let url = aDecoder.decodeObject(forKey:"url") as? URL
            else { return nil }
        self.init()
        self.fileName = fileName
        self.cacheSegments = cacheSegments
        self.downloadInfo = downloadInfo
        self.cacheMedia = cacheMedia
        self.url = url
    }
}

extension PlayerCacheMediaConfiguration: NSCopying {
    public func copy(with zone: NSZone? = nil) -> Any {
        let mediaConfiguration = PlayerCacheMediaConfiguration()
        mediaConfiguration.filePath = filePath
        mediaConfiguration.fileName = fileName
        mediaConfiguration.cacheSegments = cacheSegments
        mediaConfiguration.cacheMedia = cacheMedia
        mediaConfiguration.url = url
        mediaConfiguration.downloadInfo = downloadInfo
        return mediaConfiguration
    }
}

extension PlayerCacheMediaConfiguration: CustomStringConvertible {
    public var description: String {
        return "filePath: \(String(describing: filePath))\n cacheMedia: \(String(describing: cacheMedia))\n url: \(String(describing: url))\n cacheSegments: \(cacheSegments) \n"
    }
}

extension PlayerCacheMediaConfiguration {
    public static func getFilePath(for filePath: String) -> String {
        return filePath + "/" + "mediaConfiguration"
    }
    
    public static func configuration(filePath: String) -> PlayerCacheMediaConfiguration {
        let path = getFilePath(for: filePath)
        
        guard let configuration = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? PlayerCacheMediaConfiguration else {
            let defaultConfiguration = PlayerCacheMediaConfiguration()
            defaultConfiguration.filePath = path
            defaultConfiguration.fileName = (filePath as NSString).lastPathComponent
            return defaultConfiguration
        }
        
        configuration.filePath = path
        
        return configuration
    }
}

// MARK: - 更新
extension PlayerCacheMediaConfiguration {
    public func save() {
        cacheSegmentQueue.sync {
            if let filePath = filePath {
                //NSKeyedArchiver.archiveRootObject(self, toFile: filePath)
            }
        }
    }
    
    public func addCache(segment: NSRange) {
        if segment.location == NSNotFound || segment.location == 0 {
            return
        }
        
        cacheDownloadInfoQueue.sync {
            var cacheSegments = self.cacheSegments
            let segmentValue = NSValue(range: segment)
            let count = cacheSegments.count
            
            if count == 0 {
                cacheSegments.append(segmentValue)
            }else {
                let indexSet = NSMutableIndexSet()
                for (index, value) in cacheSegments.enumerated() {
                    let range = value.rangeValue
                    if segment.location + segment.length <= range.location, indexSet.count == 0 {
                        indexSet.add(index)
                        break
                    } else if segment.location <= range.location + range.length
                        && segment.location + segment.length > range.location {
                        indexSet.add(index)
                    } else if segment.location >= range.location + range.length, index == count - 1 {
                        indexSet.add(index)
                    }
                }
                
                if indexSet.count > 1 {
                    let firstRange = cacheSegments[indexSet.firstIndex].rangeValue
                    let lastRange = cacheSegments[indexSet.lastIndex].rangeValue
                    let location = min(firstRange.location, segment.location)
                    let endOffset = max(lastRange.location + lastRange.length, segment.location + segment.length)
                    
                    let combineRange = NSMakeRange(location, endOffset - location)
                    let _ = indexSet.sorted(by: >).map { cacheSegments.remove(at: $0) }
                    cacheSegments.insert(NSValue(range: combineRange), at: indexSet.firstIndex)
                } else if indexSet.count == 1 {
                    let firstRange = self.cacheSegments[indexSet.firstIndex].rangeValue
                    let expandFirstRange = NSMakeRange(firstRange.location, firstRange.length + 1)
                    let expandSegmentRange = NSMakeRange(segment.location, segment.length + 1)
                    let intersectionRange = NSIntersectionRange(expandFirstRange, expandSegmentRange)
                    
                    if intersectionRange.length > 0 {
                        let location = min(firstRange.location, segment.location)
                        let endOffset = max(firstRange.location + firstRange.length, segment.location + segment.length)
                        let combineRange = NSMakeRange(location, endOffset - location)
                        cacheSegments.remove(at: indexSet.firstIndex)
                        cacheSegments.insert(NSValue(range:combineRange), at: indexSet.firstIndex)
                    } else {
                        if firstRange.location > segment.location {
                            cacheSegments.insert(segmentValue, at: indexSet.lastIndex)
                        } else {
                            cacheSegments.insert(segmentValue, at: indexSet.lastIndex + 1)
                        }
                    }
                }
            }
            self.cacheSegments = cacheSegments
        }
    }
    
    public func add(downloadedBytes: UInt64, time: TimeInterval) {
        cacheDownloadInfoQueue.sync {
            var newDownloadInfo = downloadInfo
            newDownloadInfo.append((downloadedBytes: downloadedBytes, time: time))
            downloadInfo = newDownloadInfo
        }
    }
}
