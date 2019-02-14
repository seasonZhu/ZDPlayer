//
//  PlayerDownloader.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation
import MobileCoreServices

public struct PlayerDownloaderStatus {
    
    private var downloadingURLs: Set<URL>
    //fileprivate let downloaderStatusQueue: DispatchQueue
    
    public static var share = PlayerDownloaderStatus()
    private init() {
        //downloaderStatusQueue = DispatchQueue(label: "com.vgplayer.downloaderStatusQueue")
        downloadingURLs = Set<URL>()
    }
    
    /*
     这个地方的添加与删除 我并没同步线程,不知道会不会有问题
     应该说我使用同步线程 系统提示我这么做没有意义
     */
    public mutating func add(url: URL) {
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

public protocol PlayerDownloaderDelegate: class {
    func downloader(_ downloader: PlayerDownloader, didReceiveResponse response: URLResponse)
    func downloader(_ downloader: PlayerDownloader, didReceiveData data: Data, isLocal: Bool)
    func downloader(_ downloader: PlayerDownloader, didFinishedWithError error: Error?)
}


extension PlayerDownloaderDelegate {
    func downloader(_ downloader: PlayerDownloader, didReceiveResponse response: URLResponse) { }
    func downloader(_ downloader: PlayerDownloader, didReceiveData data: Data, isLocal: Bool) { }
    func downloader(_ downloader: PlayerDownloader, didFinishedWithError error: Error?) { }
}

public class PlayerDownloader {
    public private(set) var url: URL
    public weak var delegate: PlayerDownloaderDelegate?
    public var cacheMedia: PlayerCacheMedia?
    public let cacheMediaWorker: PlayerCacheMediaWorker
    
    private let session: URLSession
    private var isDownloadToEnd = false
    private var downloaderWorker: PlayerDownloaderWorker?
    
    init(url: URL) {
        self.url = url
        cacheMediaWorker = PlayerCacheMediaWorker(url: url)
        cacheMedia = cacheMediaWorker.cacheMediaConfiguration?.cacheMedia
        
        let configuration = URLSessionConfiguration.default
        session = URLSession(configuration: configuration)
    }
    
    public func downloaderTask(fromOffset: Int64, length: Int, isEnd: Bool) {
        if isCurrentURLDownloading() {
            handleCurrentURLDownloadingError()
            return
        }
        
        PlayerDownloaderStatus.share.add(url: url)
        
        var range = NSRange(location: Int(fromOffset), length: length)
        if isEnd {
            if let contentLength = cacheMediaWorker.cacheMediaConfiguration?.cacheMedia?.contentLength {
                range.length = Int(contentLength) - range.location
            }else {
                range.length = 0 - range.location
            }
        }
        
        let actions = cacheMediaWorker.cachedDataActions(forRange: range)
        downloaderWorker = PlayerDownloaderWorker(actions: actions, url: url, cacheMediaWorker: cacheMediaWorker)
        downloaderWorker?.delegate = self
        downloaderWorker?.start()
    }
    
    public func downloadFrameStartToEnd() {
        if isCurrentURLDownloading() {
            handleCurrentURLDownloadingError()
            return
        }
        
        PlayerDownloaderStatus.share.add(url: url)
        
        isDownloadToEnd = true
        let range = NSRange(location: 0, length: 2)
        let actions = cacheMediaWorker.cachedDataActions(forRange: range)
        downloaderWorker = PlayerDownloaderWorker(actions: actions, url: url, cacheMediaWorker: cacheMediaWorker)
        downloaderWorker?.delegate = self
        downloaderWorker?.start()
    }
    
    public func cancel() {
        invalidateAndCancel()
    }
    
    public func invalidateAndCancel() {
        PlayerDownloaderStatus.share.remove(url: url)
        downloaderWorker?.cancel()
        downloaderWorker?.delegate = nil
        downloaderWorker = nil
    }
}

extension PlayerDownloader {
    func isCurrentURLDownloading() -> Bool {
        return PlayerDownloaderStatus.share.contains(url: url)
    }
    
    func handleCurrentURLDownloadingError() {
        if isCurrentURLDownloading() {
            let userInfo = [NSLocalizedDescriptionKey: "URL: \(url) alreay in downloading queue."]
            let error = NSError(domain: "com.lostsakura.www.PlayerDownloader", code: -1, userInfo: userInfo)
            delegate?.downloader(self, didFinishedWithError: error as Error)
        }
    }
}

extension PlayerDownloader: PlayerDownloaderWorkerDelegate {
    public func downloaderWorker(_ downloaderWorker: PlayerDownloaderWorker, didReceive response: URLResponse) {
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
                delegate?.downloader(self, didFinishedWithError: error as Error)
                return
            }
        }
        delegate?.downloader(self, didReceiveResponse: response)
    }
    
    public func downloaderWorker(_ downloaderWorker: PlayerDownloaderWorker, didReceive data: Data, isLocal: Bool) {
        delegate?.downloader(self, didReceiveData: data, isLocal: isLocal)
    }
    
    public func downloaderWorker(_ downloaderWorker: PlayerDownloaderWorker, didFinishWithError error: Error?) {
        PlayerDownloaderStatus.share.remove(url: url)
        if error == nil && isDownloadToEnd {
            isDownloadToEnd = false
            if let contentLength = cacheMediaWorker.cacheMediaConfiguration?.cacheMedia?.contentLength {
                let length = contentLength - 2
                downloaderTask(fromOffset: 2, length: Int(length), isEnd: true)
            }
        }else {
            delegate?.downloader(self, didFinishedWithError: error)
        }
    }
}


