//
//  CacheMediaInfo.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

/// 多媒体下载配置信息
public class CacheMediaInfo: Codable {
    
    /// 信息路径
    public private(set) var filePath: String?
    
    /// 缓存段
    public private(set) var cacheSegments = [NSValue]()
    
    /// 缓存的NSRang数组
    public private(set) var cacheRanges = [NSRange]()
    
    /// 缓存多媒体
    public var cacheMedia: CacheMedia?
    
    /// 资源网址
    public var url: URL?
    
    /// 缓存段队列
    private let cacheSegmentQueue: DispatchQueue
    
    /// 缓存下载信息队列
    private let cacheDownloadInfoQueue: DispatchQueue
    
    /// 文件名
    private var fileName: String?
    
    /// 下载信息
    private var downloadInfos = [DownloadInfo]()
    
    /// 进度
    public private(set) var progress: Double = 0.0 {
        didSet {
            if let contentLength = cacheMedia?.contentLength,
                let downloadedBytes = downloadedBytes  {
                progress = Double(downloadedBytes / contentLength)
            }
        }
    }
    
    /// 已下载的数据大小
    public private(set) var downloadedBytes: Int64? {
        didSet {
            var bytes = 0
            
            cacheSegmentQueue.sync {
                for range in cacheSegments {
                    bytes += range.rangeValue.length
                }
            }
            downloadedBytes = Int64(bytes)
        }
    }
    
    /// 下载速度 kB/s
    public private(set) var downloadSpeed: Double? {
        didSet {
            var bytes: UInt64 = 0
            var time = 0.0
            if downloadInfos.count > 0 {
                cacheDownloadInfoQueue.sync {
                    for array in downloadInfos {
                        bytes += array.downloadedBytes
                        time += array.time
                    }
                }
            }
            downloadSpeed = Double(bytes) / 1024.0 / time
        }
    }
    
    public init() {
        cacheSegmentQueue = DispatchQueue(label: "com.lostsakura.www.CacheSegmentQueue")
        cacheDownloadInfoQueue = DispatchQueue(label: "com.lostsakura.www.CacheDownloadInfoQueue")
    }
    
    /// Copy
    public func copy() -> CacheMediaInfo {
        let mediaInfo = CacheMediaInfo()
        mediaInfo.filePath = filePath
        mediaInfo.fileName = fileName
        mediaInfo.cacheSegments = cacheSegments
        mediaInfo.cacheMedia = cacheMedia
        mediaInfo.url = url
        mediaInfo.fileName = fileName
        mediaInfo.downloadInfos = downloadInfos
        return mediaInfo
    }
    
    public var description: String {
        return "filePath: \(String(describing: filePath))\n cacheMedia: \(String(describing: cacheMedia))\n url: \(String(describing: url))\n cacheSegments: \(cacheSegments) \n"
    }
    
    private enum CodingKeys:String, CodingKey {
        case fileName
        case cacheRanges
        case downloadInfos
        case cacheMedia
        case url
    }
    
    /// Codable
    required public convenience init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fileName = try values.decode(String.self, forKey: .fileName)
        cacheRanges = try values.decode([NSRange].self, forKey: .cacheRanges)
        cacheSegments = cacheRanges.map {  return NSValue(range: $0) }
        downloadInfos = try values.decode([DownloadInfo].self, forKey: .downloadInfos)
        cacheMedia = try values.decode(CacheMedia.self, forKey: .cacheMedia)
        url = try values.decode(URL.self, forKey: .url)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fileName, forKey: .fileName)
        cacheRanges = cacheSegments.map { return $0.rangeValue }
        try container.encode(cacheRanges, forKey: .cacheRanges)
        try container.encode(downloadInfos, forKey: .downloadInfos)
        try container.encode(cacheMedia, forKey: .cacheMedia)
        try container.encode(url, forKey: .url)
    }
}

extension CacheMediaInfo {
    
    /// 获取MediaInfo的路径
    ///
    /// - Parameter filePath: 文件路径
    /// - Returns: info的路径
    public static func getMediaInfoPath(for filePath: String) -> String {
        let nsString = filePath as NSString
        return nsString.deletingPathExtension + ".json"
    }
    
    /// 获取MediaInfo的模型
    ///
    /// - Parameter filePath: 文件路径
    /// - Returns: 模型
    public static func getMediaInfo(filePath: String) -> CacheMediaInfo {
        let path = getMediaInfoPath(for: filePath)
    
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path)), let info = try? JSONDecoder().decode(CacheMediaInfo.self, from: data) {
            info.filePath = path
            return info
        }
        
        let defaultInfo = CacheMediaInfo()
        defaultInfo.filePath = path
        defaultInfo.fileName = (filePath as NSString).lastPathComponent
        return defaultInfo
    }
}

// MARK: - 更新
extension CacheMediaInfo {
    
    /// 保存MediaInfo
    public func save() {
        cacheSegmentQueue.sync {
            guard let filePath = filePath else { return }
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encodeData = try? encoder.encode(self)
            try? encodeData?.write(to: URL(fileURLWithPath: filePath))
        }
    }
    
    
    /// 添加缓存段的范围
    ///
    /// - Parameter segment: NSRange
    public func addCache(segment: NSRange) {
        if segment.location == NSNotFound || segment.length == 0 {
            return
        }
        
        cacheSegmentQueue.sync {
            var cacheSegments = self.cacheSegments
            let segmentValue = NSValue(range: segment)
            let count = self.cacheSegments.count
            
            if count == 0 {
                cacheSegments.append(segmentValue)
            } else {
                let indexSet = NSMutableIndexSet()
                for (index, value) in cacheSegments.enumerated() {
                    let range = value.rangeValue
                    if (segment.location + segment.length) <= range.location {
                        if (indexSet.count == 0) {
                            indexSet.add(index)
                        }
                        break
                    } else if (segment.location <= (range.location + range.length) && (segment.location + segment.length) > range.location) {
                        indexSet.add(index)
                    } else if (segment.location >= range.location + range.length) {
                        if index == count - 1 {
                            indexSet.add(index)
                        }
                    }
                    
                }
                
                if indexSet.count > 1 {
                    let firstRange = self.cacheSegments[indexSet.firstIndex].rangeValue
                    let lastRange = self.cacheSegments[indexSet.lastIndex].rangeValue
                    let location = min(firstRange.location, segment.location)
                    let endOffset = max(lastRange.location + lastRange.length, segment.location + segment.length)
                    
                    let combineRange = NSMakeRange(location, endOffset - location)
                    let _ = indexSet.sorted(by: >).map {cacheSegments.remove(at: $0)}
                    cacheSegments.insert(NSValue(range:combineRange), at: indexSet.firstIndex)
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
            self.cacheRanges = cacheSegments.map { return $0.rangeValue }
        }
        
    }
    
    /// 添加downloadInfo
    ///
    /// - Parameters:
    ///   - downloadedBytes: 已下载的字节数
    ///   - time: 下载花费的时间
    public func addDownloadInfo(downloadedBytes: UInt64, time: TimeInterval) {
        cacheDownloadInfoQueue.sync {
            let downloadInfo = DownloadInfo()
            downloadInfo.downloadedBytes = downloadedBytes
            downloadInfo.time = time
            self.downloadInfos.append(downloadInfo)
        }
    }
}

class DownloadInfo: Codable {
    
    var downloadedBytes: UInt64 = 0
    var time: TimeInterval = 0
    
    init() {}

    private enum CodingKeys:String, CodingKey {
        case downloadedBytes
        case time
    }

    /// Codable
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        downloadedBytes = try values.decode(UInt64.self, forKey: .downloadedBytes)
        time = try values.decode(TimeInterval.self, forKey: .time)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(downloadedBytes, forKey: .downloadedBytes)
        try container.encode(time, forKey: .time)
    }
}

/*
 NSCoding, NSCopying 协议的大前提是类必须继承NSObject呀
 */

/*
 其实想去NSObject化,使用Codable协议进行数据的存储工作,但是看见网上的例子设计Codable都是JSON转模型的,看来这里是很难用上的了
 */

/*
/// 多媒体下载配置信息
public class CacheMediaInfo: NSObject, NSCoding, NSCopying, Codable {
    
    /// 信息路径
    public private(set) var filePath: String?
    
    /// 缓存段
    public private(set) var cacheSegments = [NSValue]()
    
    public private(set) var cacheRanges = [NSRange]()
    
    /// 缓存多媒体
    public var cacheMedia: CacheMedia?
    
    /// 资源网址
    public var url: URL?
    
    /// 缓存段队列
    private let cacheSegmentQueue: DispatchQueue
    
    /// 缓存下载信息队列
    private let cacheDownloadInfoQueue: DispatchQueue
    
    /// 文件名
    private var fileName: String?
    
    /// 下载信息
    private var downloadInfos = [DownloadInfo]()
    
    /// 进度
    public private(set) var progress: Double = 0.0 {
        didSet {
            if let contentLength = cacheMedia?.contentLength,
                let downloadedBytes = downloadedBytes  {
                progress = Double(downloadedBytes / contentLength)
            }
        }
    }
    
    /// 已下载的数据大小
    public private(set) var downloadedBytes: Int64? {
        didSet {
            var bytes = 0
            
            cacheSegmentQueue.sync {
                for range in cacheSegments {
                    bytes += range.rangeValue.length
                }
            }
            downloadedBytes = Int64(bytes)
        }
    }
    
    /// 下载速度 kB/s
    public private(set) var downloadSpeed: Double? {
        didSet {
            var bytes: UInt64 = 0
            var time = 0.0
            if downloadInfos.count > 0 {
                cacheDownloadInfoQueue.sync {
                    for array in downloadInfos {
                        bytes += array.downloadedBytes
                        time += array.time
                    }
                }
            }
            downloadSpeed = Double(bytes) / 1024.0 / time
        }
    }
    
    public override init() {
        cacheSegmentQueue = DispatchQueue(label: "com.lostsakura.www.CacheSegmentQueue")
        cacheDownloadInfoQueue = DispatchQueue(label: "com.lostsakura.www.CacheDownloadInfoQueue")
        super.init()
    }
    
    /// NSCoding
    public required convenience init?(coder aDecoder: NSCoder) {
        guard let fileName = aDecoder.decodeObject(forKey: "fileName") as? String,
            let cacheSegments = aDecoder.decodeObject(forKey:"cacheSegments") as? [NSValue],
            let downloadInfos = aDecoder.decodeObject(forKey:"downloadInfo") as? [DownloadInfo],
            let cacheMedia = aDecoder.decodeObject(forKey:"cacheMedia") as? CacheMedia,
            let url = aDecoder.decodeObject(forKey:"url") as? URL
            else {
                return nil
        }
        
        self.init()
        self.fileName = fileName
        self.cacheSegments = cacheSegments
        self.downloadInfos = downloadInfos
        self.cacheMedia = cacheMedia
        self.url = url
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(fileName, forKey: "fileName")
        aCoder.encode(cacheSegments, forKey: "cacheSegments")
        aCoder.encode(downloadInfos, forKey: "downloadInfo")
        aCoder.encode(cacheMedia, forKey: "cacheMedia")
        aCoder.encode(url, forKey: "url")
    }
    
    /// NSCoying
    public func copy(with zone: NSZone? = nil) -> Any {
        let mediaInfo = CacheMediaInfo()
        mediaInfo.filePath = filePath
        mediaInfo.fileName = fileName
        mediaInfo.cacheSegments = cacheSegments
        mediaInfo.cacheMedia = cacheMedia
        mediaInfo.url = url
        mediaInfo.fileName = fileName
        mediaInfo.downloadInfos = downloadInfos
        return mediaInfo
    }
    
    public override var description: String {
        return "filePath: \(String(describing: filePath))\n cacheMedia: \(String(describing: cacheMedia))\n url: \(String(describing: url))\n cacheSegments: \(cacheSegments) \n"
    }
    
    private enum CodingKeys:String, CodingKey {
        case fileName
        case cacheRanges
        case downloadInfos
        case cacheMedia
        case url
    }
    
    /// Codable
    required public convenience init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fileName = try values.decode(String.self, forKey: .fileName)
        cacheRanges = try values.decode([NSRange].self, forKey: .cacheRanges)
        cacheSegments = cacheRanges.map {  return NSValue(range: $0) }
        downloadInfos = try values.decode([DownloadInfo].self, forKey: .downloadInfos)
        cacheMedia = try values.decode(CacheMedia.self, forKey: .cacheMedia)
        url = try values.decode(URL.self, forKey: .url)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(fileName, forKey: .fileName)
        cacheRanges = cacheSegments.map { return $0.rangeValue }
        try container.encode(cacheRanges, forKey: .cacheRanges)
        try container.encode(downloadInfos, forKey: .downloadInfos)
        try container.encode(cacheMedia, forKey: .cacheMedia)
        try container.encode(url, forKey: .url)
    }
}

extension CacheMediaInfo {
    
    /// 获取MediaInfo的路径
    ///
    /// - Parameter filePath: 文件路径
    /// - Returns: info的路径
    public static func getMediaInfoPath(for filePath: String) -> String {
        let nsString = filePath as NSString
        return nsString.deletingPathExtension + ".conf"
    }
    
    /// 获取MediaInfo的模型
    ///
    /// - Parameter filePath: 文件路径
    /// - Returns: 模型
    public static func getMediaInfo(filePath: String) -> CacheMediaInfo {
        let path = getMediaInfoPath(for: filePath)
        
        guard let mediaInfo = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? CacheMediaInfo else {
            let defaultInfo = CacheMediaInfo()
            defaultInfo.filePath = path
            defaultInfo.fileName = (filePath as NSString).lastPathComponent
            return defaultInfo
        }
        mediaInfo.filePath = path
        
        
        if let data = try? Data(contentsOf: URL(fileURLWithPath: path + ".json")) {
            let jsonString = String(data: data, encoding: .utf8)
            let info = try? JSONDecoder().decode(CacheMediaInfo.self, from: data)
            print(jsonString)
            print(info)
            info?.filePath = path
            if let newInfo = info {
                return newInfo
            }
        }
        
        return mediaInfo
    }
}

// MARK: - 更新
extension CacheMediaInfo {
    
    /// 保存MediaInfo
    public func save() {
        cacheSegmentQueue.sync {
            guard let filePath = filePath else { return }
            let _ = NSKeyedArchiver.archiveRootObject(self, toFile: filePath)
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encodeData = try? encoder.encode(self)
            print(encodeData)
            try? encodeData?.write(to: URL(fileURLWithPath: filePath + ".json"))
        }
    }
    
    
    /// 添加缓存段的范围
    ///
    /// - Parameter segment: NSRange
    public func addCache(segment: NSRange) {
        if segment.location == NSNotFound || segment.length == 0 {
            return
        }
        
        cacheSegmentQueue.sync {
            var cacheSegments = self.cacheSegments
            let segmentValue = NSValue(range: segment)
            let count = self.cacheSegments.count
            
            if count == 0 {
                cacheSegments.append(segmentValue)
            } else {
                let indexSet = NSMutableIndexSet()
                for (index, value) in cacheSegments.enumerated() {
                    let range = value.rangeValue
                    if (segment.location + segment.length) <= range.location {
                        if (indexSet.count == 0) {
                            indexSet.add(index)
                        }
                        break
                    } else if (segment.location <= (range.location + range.length) && (segment.location + segment.length) > range.location) {
                        indexSet.add(index)
                    } else if (segment.location >= range.location + range.length) {
                        if index == count - 1 {
                            indexSet.add(index)
                        }
                    }
                    
                }
                
                if indexSet.count > 1 {
                    let firstRange = self.cacheSegments[indexSet.firstIndex].rangeValue
                    let lastRange = self.cacheSegments[indexSet.lastIndex].rangeValue
                    let location = min(firstRange.location, segment.location)
                    let endOffset = max(lastRange.location + lastRange.length, segment.location + segment.length)
                    
                    let combineRange = NSMakeRange(location, endOffset - location)
                    let _ = indexSet.sorted(by: >).map {cacheSegments.remove(at: $0)}
                    cacheSegments.insert(NSValue(range:combineRange), at: indexSet.firstIndex)
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
            self.cacheRanges = cacheSegments.map { return $0.rangeValue }
        }
        
    }
    
    /// 添加downloadInfo
    ///
    /// - Parameters:
    ///   - downloadedBytes: 已下载的字节数
    ///   - time: 下载花费的时间
    public func addDownloadInfo(downloadedBytes: UInt64, time: TimeInterval) {
        cacheDownloadInfoQueue.sync {
            let downloadInfo = DownloadInfo()
            downloadInfo.downloadedBytes = downloadedBytes
            downloadInfo.time = time
            self.downloadInfos.append(downloadInfo)
        }
    }
}

class DownloadInfo: NSObject, NSCoding, Codable {

    var downloadedBytes: UInt64 = 0
    var time: TimeInterval = 0
    
    override init() {
        super.init()
    }
    
    /// NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(downloadedBytes, forKey: "downloadedBytes")
        // 注意Double类型不能被NSCoding序列化, Double是struct Int/UInt也是struct 搞不懂 Double -> NSNumber
        aCoder.encode(NSNumber(value: time), forKey: "time")
    }

    required init?(coder aDecoder: NSCoder) {
        super.init()
        self.downloadedBytes = aDecoder.decodeObject(forKey: "downloadedBytes") as? UInt64 ?? 0
        self.time = (aDecoder.decodeObject(forKey:"time") as? NSNumber)?.doubleValue ?? 0
    }
    
    private enum CodingKeys:String, CodingKey {
        case downloadedBytes
        case time
    }
    
    /// Codable
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        downloadedBytes = try values.decode(UInt64.self, forKey: .downloadedBytes)
        time = try values.decode(TimeInterval.self, forKey: .time)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(downloadedBytes, forKey: .downloadedBytes)
        try container.encode(time, forKey: .time)
    }
}
*/
