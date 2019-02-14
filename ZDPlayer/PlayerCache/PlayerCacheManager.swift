//
//  PlayerCacheManager.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

public class PlayerCacheManager {
    static public let CacheConfigurationKey = "PlayerCacheConfigurationKey"
    static public let CacheErrorKey = "PlayerCacheErrorKey"
    static public let CleanCacheKey = "PlayerCleanCacheKey"
    
    public static var mediaCacheNotifyInterval = 0.1
    
    private let ioQueue: DispatchQueue
    private var fileManager: FileManager!
    
    public static let share = PlayerCacheManager()
    private init() {
        ioQueue = DispatchQueue(label: "com.lostsakura.www.ioQueue")
        ioQueue.sync {
            fileManager = FileManager()
        }
    }
    
    public private(set) var cacheConfig = PlayerCacheConfiguration()
}

extension PlayerCacheManager {
    public static var cacheDirectory: String {
        return NSTemporaryDirectory() + "PlayerCache"
    }
    
    public static func cacheFilePath(for url: URL) -> String {
        if let cacheFolder = url.lastPathComponent.components(separatedBy: ".").first {
            return cacheDirectory + "/" + cacheFolder + "/" + url.lastPathComponent
        }
        return cacheDirectory + "/" + url.lastPathComponent
    }
    
    public static func cacheConfiguration(forURL url: URL) -> PlayerCacheMediaConfiguration {
        let filePath = cacheFilePath(for: url)
        return PlayerCacheMediaConfiguration.configuration(filePath: filePath)
    }
}

extension PlayerCacheManager {
    public func clearAllCache() {
        ioQueue.sync {
            do {
                try fileManager.removeItem(atPath: PlayerCacheManager.cacheDirectory)
            }catch {
                
            }
        }
    }
    
    public func calculateDiskCacheSize(completion callback: @escaping (_ size: UInt) -> Void) {
        ioQueue.async {
            let (_, diskCacheSize, _) = self.cachedFiles(atPath: PlayerCacheManager.cacheDirectory)
            DispatchQueue.main.async {
                callback(diskCacheSize)
            }
        }
    }
    
    public func clearOldFiles(completion callback: (([String]) -> Void)? = nil) {
        ioQueue.sync {
            var (_, diskCacheSize, cachedFiles) = self.cachedFiles(atPath: PlayerCacheManager.cacheDirectory)
            var deleteUrls = [URL]()
            if diskCacheSize > cacheConfig.maxDiskCacheSize  {
                let targetSize = cacheConfig.maxDiskCacheSize / 2
                
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
                NotificationCenter.default.post(name: .PlayerCacheManagerDidCleanCache, object: self, userInfo: [PlayerCacheManager.CleanCacheKey: deleteFileName])
                callback?(deleteFileName)
            }
        }
    }
    
    private func cachedFiles(atPath path: String, onlyForCacheSize: Bool = true) -> (urlsToDelete: [URL], diskCacheSize: UInt, cachedFiles: [URL: URLResourceValues]) {
        let expiredDate = (cacheConfig.maxCachePeriodInSecond < 0) ? Date(timeIntervalSinceNow: -24 * 60 * 60 ) : Date(timeIntervalSinceNow: -cacheConfig.maxCachePeriodInSecond)
        
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

extension Dictionary {
    func keysSortedByValue(_ isOrderedBefore: (Value, Value) -> Bool) -> [Key] {
        return Array(self).sorted { isOrderedBefore($0.1, $1.1) }.map{ $0.0 }
    }
}

extension Notification.Name {
    public static var PlayerCacheManagerDidUpdateCache = Notification.Name("com.lostsakura.www.PlayerCacheManagerDidUpdateCache")
    public static var PlayerCacheManagerDidFinishCache = Notification.Name("com.lostsakura.www.PlayerCacheManagerDidFinishCache")
    public static var PlayerCacheManagerDidCleanCache = Notification.Name("com.lostsakura.www.PlayerCacheManagerDidCleanCache")
}
