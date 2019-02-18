//
//  DownloaderManager.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation
import MobileCoreServices

public struct DownloaderManagerStatus {
    
    private var downloadingURLs: Set<URL>
    //fileprivate let downloaderStatusQueue: DispatchQueue
    
    public static var share = DownloaderManagerStatus()
    private init() {
        //downloaderStatusQueue = DispatchQueue(label: "com.vgplayer.downloaderStatusQueue")
        downloadingURLs = Set<URL>()
    }
    
    /*
     这个地方的添加与删除 我并没同步线程,不知道会不会有问题
     应该说我使用同步线程 系统提示我这么做没有意义
     */
    public mutating func insert(url: URL) {
        downloadingURLs.insert(url)
    }
    
    public mutating func remove(url: URL) {
        downloadingURLs.remove(url)
    }
    
    public func contains(url: URL) -> Bool {
        return downloadingURLs.contains(url)
    }
    
    public func urls() -> [URL] {
        return Array(downloadingURLs)
    }
}

/// 下载管理器代理
public protocol DownloaderManagerDelegate: class {
    func downloaderManager(_ downloaderManager: DownloaderManager, didReceiveResponse response: URLResponse)
    func downloaderManager(_ downloaderManager: DownloaderManager, didReceiveData data: Data, isLocal: Bool)
    func downloaderManager(_ downloaderManager: DownloaderManager, didFinishedWithError error: Error?)
}


extension DownloaderManagerDelegate {
    func downloaderManager(_ downloaderManager: DownloaderManager, didReceiveResponse response: URLResponse) { }
    func downloaderManager(_ downloaderManager: DownloaderManager, didReceiveData data: Data, isLocal: Bool) { }
    func downloaderManager(_ downloaderManager: DownloaderManager, didFinishedWithError error: Error?) { }
}

/// 下载管理器
public class DownloaderManager {
    public private(set) var url: URL
    public weak var delegate: DownloaderManagerDelegate?
    public var cacheMedia: PlayerCacheMedia?
    public let cacheMediaWorker: PlayerCacheMediaWorker
    
    private let session: URLSession
    private var isDownloadToEnd = false
    private var downloader: Downloader?
    private var isCurrentURLDownloading: Bool {
        return DownloaderManagerStatus.share.contains(url: url)
    }
    
    init(url: URL) {
        self.url = url
        cacheMediaWorker = PlayerCacheMediaWorker(url: url)
        cacheMedia = cacheMediaWorker.cacheMediaConfiguration?.cacheMedia
        
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
    }
    
    public func downloaderTask(fromOffset: Int64, length: Int, isEnd: Bool) {
        if isCurrentURLDownloading {
            handleCurrentURLDownloadingError()
            return
        }
        
        DownloaderManagerStatus.share.insert(url: url)
        
        var range = NSRange(location: Int(fromOffset), length: length)
        if isEnd {
            if let contentLength = cacheMediaWorker.cacheMediaConfiguration?.cacheMedia?.contentLength {
                range.length = Int(contentLength) - range.location
            }else {
                range.length = 0 - range.location
            }
        }
        
        let actions = cacheMediaWorker.cachedDataActions(forRange: range)
        downloader = Downloader(actions: actions, url: url, cacheMediaWorker: cacheMediaWorker)
        downloader?.delegate = self
        downloader?.start()
    }
    
    public func downloadFrameStartToEnd() {
        if isCurrentURLDownloading {
            handleCurrentURLDownloadingError()
            return
        }
        
        DownloaderManagerStatus.share.insert(url: url)
        
        isDownloadToEnd = true
        let range = NSRange(location: 0, length: 2)
        let actions = cacheMediaWorker.cachedDataActions(forRange: range)
        downloader = Downloader(actions: actions, url: url, cacheMediaWorker: cacheMediaWorker)
        downloader?.delegate = self
        downloader?.start()
    }
    
    public func cancel() {
        invalidateAndCancel()
    }
    
    public func invalidateAndCancel() {
        DownloaderManagerStatus.share.remove(url: url)
        downloader?.cancel()
        downloader?.delegate = nil
        downloader = nil
    }
}

extension DownloaderManager {
    
    func handleCurrentURLDownloadingError() {
        let userInfo = [NSLocalizedDescriptionKey: "URL: \(url) alreay in downloading queue."]
        let error = NSError(domain: "com.lostsakura.www.DownloaderManager", code: -1, userInfo: userInfo)
        delegate?.downloaderManager(self, didFinishedWithError: error as Error)
    }
}

extension DownloaderManager: DownloaderDelegate {
    public func downloader(_ downloader: Downloader, didReceive response: URLResponse) {
        if cacheMedia == nil {
            let cacheMedia = PlayerCacheMedia()
            if let httpURLResponse = response as? HTTPURLResponse {
                let acceptRange = httpURLResponse.allHeaderFields["Accept-Ranges"] as? String
                if acceptRange == "bytes" {
                    cacheMedia.isByteRangeAccessSupported = true
                }
                
                if let contentRange = httpURLResponse.allHeaderFields["content-range"] as? String,
                    let last = contentRange.components(separatedBy: "/").last,
                    let contentLength = Int64(last) {
                    cacheMedia.contentLength = contentLength
                }
                
                if let contentRange = httpURLResponse.allHeaderFields["Content-Range"] as? String,
                    let last = contentRange.components(separatedBy: "/").last,
                    let contentLength = Int64(last) {
                    cacheMedia.contentLength = contentLength
                }
            }
            
            if let mimeType = response.mimeType {
                let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)
                if let takeUnretainedValue = contentType?.takeUnretainedValue() {
                    cacheMedia.contentType = takeUnretainedValue as String
                }
            }
            
            self.cacheMedia = cacheMedia
            let isSet = cacheMediaWorker.set(cacheMedia: cacheMedia)
            if !isSet {
                let error = NSError(domain: "com.lostsakura.www.PlayerCacheMedia", code: -1, userInfo: [NSLocalizedDescriptionKey:"Set cache media failed."])
                delegate?.downloaderManager(self, didFinishedWithError: error as Error)
                return
            }
        }
        delegate?.downloaderManager(self, didReceiveResponse: response)
    }
    
    public func downloader(_ downloader: Downloader, didReceive data: Data, isLocal: Bool) {
        delegate?.downloaderManager(self, didReceiveData: data, isLocal: isLocal)
    }
    
    public func downloader(_ downloader: Downloader, didFinishWithError error: Error?) {
        DownloaderManagerStatus.share.remove(url: url)
        if error == nil && isDownloadToEnd {
            isDownloadToEnd = false
            if let contentLength = cacheMediaWorker.cacheMediaConfiguration?.cacheMedia?.contentLength {
                let length = contentLength - 2
                downloaderTask(fromOffset: 2, length: Int(length), isEnd: true)
            }
        }else {
            delegate?.downloaderManager(self, didFinishedWithError: error)
        }
    }
}


