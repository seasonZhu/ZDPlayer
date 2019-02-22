//
//  CacheManager.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

/// 视频缓存文件管理器
public class CacheManager {
    
    /// CacheMediaInfoKey
    public static let CacheMediaInfoKey = "CacheMediaInfoKey"
    
    /// CacheErrorKey
    public static let CacheErrorKey = "CacheErrorKey"
    
    /// CacheClearKey
    public static let CacheClearKey = "CacheClearKey"
    
    /// 多媒体缓存通知间隔
    public static var mediaCacheNotifyInterval = 0.1
    
    /// 沙盒保存期限
    public var maxCachePeriodInSecond: TimeInterval = 60 * 60 * 24 * 7
    
    /// 沙盒保存容量
    public var maxDiskCacheSize: UInt = 0
    
    /// 读取线程
    private let ioQueue: DispatchQueue
    
    /// 文件管理器
    private var fileManager: FileManager!
    
    /// 单例
    public static let share = CacheManager()
    private init() {
        ioQueue = DispatchQueue(label: "com.lostsakura.www.ioQueue")
        ioQueue.sync {
            fileManager = FileManager()
        }
    }
}

extension CacheManager {
    
    /// 获取缓存文件夹
    public static var cacheDirectory: String {
        return NSTemporaryDirectory() + "PlayerCache"
    }
    
    /// 通过URL获取缓存文件夹下中的缓存文件路径
    ///
    /// - Parameter url: URL
    /// - Returns: 缓存文件路径
    public static func cacheFilePath(for url: URL) -> String {
        if let cacheFolder = url.lastPathComponent.components(separatedBy: ".").first {
            return cacheDirectory + "/" + cacheFolder + "/" + url.lastPathComponent
        }
        return cacheDirectory + "/" + url.lastPathComponent
    }
    
    /// 通过URL获取缓存文件夹下中的缓存文件的配置信息
    ///
    /// - Parameter url: URL
    /// - Returns: 配置信息
    public static func cacheConfiguration(forURL url: URL) -> CacheMediaInfo {
        let filePath = cacheFilePath(for: url)
        return CacheMediaInfo.getMediaInfo(filePath: filePath)
    }
}

extension CacheManager {
    
    /// 清除所有的沙盒缓存
    public func clearAllCache() {
        ioQueue.sync {
            do {
                try fileManager.removeItem(atPath: CacheManager.cacheDirectory)
            }catch {
                
            }
        }
    }
    
    /// 计算沙盒缓存
    ///
    /// - Parameter callback: 回调缓存大小
    public func calculateDiskCacheSize(completion callback: @escaping (_ size: UInt) -> Void) {
        ioQueue.async {
            let (_, diskCacheSize, _) = self.cachedFiles(atPath: CacheManager.cacheDirectory)
            DispatchQueue.main.async {
                callback(diskCacheSize)
            }
        }
    }
    
    /// 清理过期文件
    ///
    /// - Parameter callback: 回调(删除的过期文件名称)
    public func clearOldFiles(completion callback: (([String]) -> Void)? = nil) {
        ioQueue.sync {
            var (_, diskCacheSize, cachedFiles) = self.cachedFiles(atPath: CacheManager.cacheDirectory)
            var deleteUrls = [URL]()
            if diskCacheSize > maxDiskCacheSize  {
                let targetSize = maxDiskCacheSize / 2
                
                let sortedFiles = cachedFiles.keysSortedByValue {
                    resourceValue1, resourceValue2 -> Bool in
                    
                    if let date1 = resourceValue1.contentAccessDate,
                        let date2 = resourceValue2.contentAccessDate {
                        return date1.compare(date2) == .orderedAscending
                    }
                    return true
                }
                
                for url in sortedFiles {
                    let (_, clearCacheSize, _) = self.cachedFiles(atPath: url.path)
                    
                    do {
                        try fileManager.removeItem(at: url)
                        diskCacheSize -= clearCacheSize
                    }catch {
                        
                    }
                    
                    if diskCacheSize < targetSize {
                        break
                    }
                    
                    deleteUrls.append(url)
                }
            }
            
            DispatchQueue.main.async {
                let deleteFileName = deleteUrls.map { $0.lastPathComponent }
                NotificationCenter.default.post(name: .CacheManagerDidCleanCache, object: self, userInfo: [CacheManager.CacheClearKey: deleteFileName])
                callback?(deleteFileName)
            }
        }
    }
    
    /// 获取缓存路径下的文件信息
    ///
    /// - Parameters:
    ///   - path: 路径
    ///   - onlyForCacheSize: 是否仅仅针对缓存大小
    /// - Returns: 文件信息
    private func cachedFiles(atPath path: String, onlyForCacheSize: Bool = true) -> (urlsToDelete: [URL], diskCacheSize: UInt, cachedFiles: [URL: URLResourceValues]) {
        let expiredDate = (maxCachePeriodInSecond < 0) ? Date(timeIntervalSinceNow: -24 * 60 * 60 ) : Date(timeIntervalSinceNow: -maxCachePeriodInSecond)
        
        var urlsToDelete = [URL]()
        var diskCacheSize: UInt = 0
        var cachedFiles = [URL: URLResourceValues]()
        
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey, .contentAccessDateKey, .totalFileAllocatedSizeKey]
        let fullPath = (path as NSString).expandingTildeInPath
 
        let url = URL(fileURLWithPath: fullPath)
        if let directoryEnumerators = fileManager.enumerator(at: url, includingPropertiesForKeys: Array(resourceKeys), options: [.skipsHiddenFiles], errorHandler: nil) {
            for directoryEnumerator in directoryEnumerators {
                do {
                    if let fileUrl = directoryEnumerator as? URL {
                        let resourceValues = try fileUrl.resourceValues(forKeys: resourceKeys)
                        
                        if !onlyForCacheSize,
                            let lastAccessData = resourceValues.contentAccessDate,
                            (lastAccessData as NSDate).laterDate(expiredDate) == expiredDate {
                            urlsToDelete.append(fileUrl)
                            continue
                        }
                        
                        if !onlyForCacheSize && resourceValues.isDirectory == true {
                            cachedFiles[fileUrl] = resourceValues
                        }
                        
                        if let size = resourceValues.totalFileAllocatedSize {
                            diskCacheSize += UInt(size)
                        }
                    }
                }catch {
                    
                }
            }
        }
        
        return (urlsToDelete, diskCacheSize, cachedFiles)
    }
}

// MARK: - 字典key通过value的升序进行排列后返回[key]数组
extension Dictionary {
    func keysSortedByValue(_ isOrderedBefore: (Value, Value) -> Bool) -> [Key] {
        return Array(self).sorted { isOrderedBefore($0.1, $1.1) }.map{ $0.0 }
    }
}

// MARK: - 缓存管理器的通知名称
extension Notification.Name {
    public static var CacheManagerDidUpdateCache = Notification.Name("com.lostsakura.www.CacheManagerDidUpdateCache")
    public static var CacheManagerDidFinishCache = Notification.Name("com.lostsakura.www.CacheManagerDidFinishCache")
    public static var CacheManagerDidCleanCache = Notification.Name("com.lostsakura.www.CacheManagerDidCleanCache")
}
