//
//  DownloaderManager.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation
import MobileCoreServices

/// 下载管理器状态
public struct DownloaderManagerStatus {
    
    /// 单例 这里使用var其实对于一个单例而言并不是很好,这样写
    public static var share = DownloaderManagerStatus()
    
    /// 正在下载资源集合
    private var downloadingURLs: Set<URL>
    //fileprivate let downloaderStatusQueue: DispatchQueue
    
    /// 私有化初始化方法
    private init() {
        //downloaderStatusQueue = DispatchQueue(label: "com.lostsakura.www.downloaderManagerStatusQueue")
        downloadingURLs = Set<URL>()
    }
    
    /*
     这个地方的添加与删除 我并没同步线程,不知道会不会有问题
     应该说我使用同步线程 系统提示我这么做没有意义
     */
    
    /// 添加资源到正在下载资源集合
    ///
    /// - Parameter url: 资源网址
    public mutating func insert(url: URL) {
        downloadingURLs.insert(url)
    }
    
    /// 移除资源到正在下载资源集合
    ///
    /// - Parameter url: 资源网址
    public mutating func remove(url: URL) {
        downloadingURLs.remove(url)
    }
    
    /// 正在下载资源集合是否包含该资源网址
    ///
    /// - Parameter url: 资源网址
    /// - Returns: Bool
    public func contains(url: URL) -> Bool {
        return downloadingURLs.contains(url)
    }
    
    /// Set转Array
    public var downloadingUrls: [URL] {
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
    
    /// 资源网址
    public private(set) var url: URL
    
    /// 代理
    public weak var delegate: DownloaderManagerDelegate?
    
    /// 多媒体请求信息
    public var cacheMedia: CacheMedia?
    
    /// 多媒体工作器
    public let cacheMediaWorker: CacheMediaWorker
    
    /// 请求Session
    private let session: URLSession
    
    /// 是否从始到终的下载
    private var isDownloadToEnd = false
    
    /// 下载器
    private var downloader: Downloader?
    
    /// 当前资源是否正在下载
    private var isCurrentURLDownloading: Bool {
        return DownloaderManagerStatus.share.contains(url: url)
    }
    
    /// 初始化方法
    ///
    /// - Parameter url: 资源网址
    public init(url: URL) {
        self.url = url
        cacheMediaWorker = CacheMediaWorker(url: url)
        cacheMedia = cacheMediaWorker.mediaInfo?.cacheMedia
        
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
            if let contentLength = cacheMediaWorker.mediaInfo?.cacheMedia?.contentLength {
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
    
    /// 从始到终的下载
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
    
    /// 取消 和下面的一样
    public func cancel() {
        invalidateAndCancel()
    }
    
    /// 作废并取消
    public func invalidateAndCancel() {
        DownloaderManagerStatus.share.remove(url: url)
        downloader?.cancel()
        downloader?.delegate = nil
        downloader = nil
    }
}

extension DownloaderManager {
    
    /// 构成正在下载的错误
    func handleCurrentURLDownloadingError() {
        let userInfo = [NSLocalizedDescriptionKey: "URL: \(url) alreay in downloading queue."]
        let error = NSError(domain: "com.lostsakura.www.DownloaderManager", code: -1, userInfo: userInfo)
        delegate?.downloaderManager(self, didFinishedWithError: error as Error)
    }
}

// MARK: - 下载器的代理
extension DownloaderManager: DownloaderDelegate {
    public func downloader(_ downloader: Downloader, didReceive response: URLResponse) {
        if cacheMedia == nil {
            let cacheMedia = CacheMedia()
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
                let error = NSError(domain: "com.lostsakura.www.CacheMedia", code: -1, userInfo: [NSLocalizedDescriptionKey:"Set cache media failed."])
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
            if let contentLength = cacheMediaWorker.mediaInfo?.cacheMedia?.contentLength {
                let length = contentLength - 2
                downloaderTask(fromOffset: 2, length: Int(length), isEnd: true)
            }
        }else {
            delegate?.downloaderManager(self, didFinishedWithError: error)
        }
    }
}


