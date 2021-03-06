//
//  Downloader.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

/// 下载工作器代理
public protocol DownloaderDelegate: class {
    func downloader(_ downloader: Downloader, didReceive response: URLResponse)
    func downloader(_ downloader: Downloader, didReceive data: Data, isLocal: Bool)
    func downloader(_ downloader: Downloader, didFinishWithError error: Error?)
}

public extension DownloaderDelegate {
    func downloader(_ downloader: Downloader, didReceive response: URLResponse) {}
    func downloader(_ downloader: Downloader, didReceive data: Data, isLocal: Bool) {}
    func downloader(_ downloader: Downloader, didFinishWithError error: Error?) {}
}

/// 下载工作器
public class Downloader {
    
    /// 缓存行为
    public private(set) var actions: [CacheAction]
    
    /// 资源网址
    public private(set) var url: URL
    
    /// 多媒体工作器
    public private(set) var cacheMediaWorker: CacheMediaWorker
    
    /// 请求的URLSession
    public private(set) var session: URLSession?
    
    /// 请求任务
    public private(set) var task: URLSessionDataTask?
    
    /// 下载器
    public private(set) var sessionDelegate: SessionDelegate?
    
    /// 开始时的偏移
    public private(set) var startOffset = 0
    
    /// 下载工作器的代理
    public weak var delegate: DownloaderDelegate?
    
    /// 是否取消
    private var isCanceled = false
    
    /// 通知时间
    private var notifyTime: TimeInterval = 0.0
    
    /// 初始化方法
    ///
    /// - Parameters:
    ///   - actions: 缓存行为
    ///   - url: 资源网址
    ///   - cacheMediaWorker: 多媒体工作器
    public init(actions: [CacheAction], url: URL, cacheMediaWorker: CacheMediaWorker) {
        self.actions = actions
        self.cacheMediaWorker = cacheMediaWorker
        self.url = url
        sessionDelegate = SessionDelegate(delegate: self)
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration, delegate: sessionDelegate, delegateQueue: nil)
        self.session = session
    }
    
    /// 开始
    public func start() {
        processAction()
    }
    
    /// 取消
    public func cancel() {
        if let _ = session {
            session?.invalidateAndCancel()
        }
        isCanceled = true
    }
    
    /// 析构函数
    deinit {
        cancel()
    }
}

extension Downloader {
    
    /// 操作
    func processAction() {
        if isCanceled {
            return
        }
        
        if let action = actions.first {
            actions.remove(at: 0)
            switch action.type {
            case .local:
                if let data = cacheMediaWorker.readCache(forRange: action.range) {
                    delegate?.downloader(self, didReceive: data, isLocal: true)
                    // 递归
                    processAction()
                }else {
                    let error = NSError(domain: "com.lostsakura.www.Downloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Read local cache data failed."])
                    delegate?.downloader(self, didFinishWithError: error as Error)
                }
            case .remote:
                let fromOffset = action.range.location
                let endOffset = action.range.location + action.range.length - 1
                var request = URLRequest(url: url)
                //   local and remote cache policy 缓存策略
                request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
                let range = String(format: "bytes=%lld-%lld", fromOffset, endOffset)
                request.setValue(range, forHTTPHeaderField: "Range")
                
                startOffset = action.range.location
                task = session?.dataTask(with: request)
                // 不能使用下载请求 因为这个不是一个完整的下载
                // session?.downloadTask(with: request).resume()
                task?.resume()
            }
        }else {
            delegate?.downloader(self, didFinishWithError: nil)
        }
    }
    
    /// 通知下载进度
    ///
    /// - Parameters:
    ///   - isFlush: 是否冲刺?
    ///   - isFinished: 是否完成
    func notify(downloadProgressWithFlush isFlush: Bool, isFinished: Bool) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let interval = CacheManager.mediaCacheNotifyInterval
        if notifyTime < currentTime - interval || isFlush {
            if let mediaInfo = cacheMediaWorker.mediaInfo?.copy() {
                let userInfo = [CacheManager.CacheMediaInfoKey: mediaInfo]
                NotificationCenter.default.post(name: .CacheManagerDidUpdateCache, object: self, userInfo: userInfo)
                
                if isFinished && mediaInfo.progress >= 1.0 {
                    notify(downloadFinishWithError: nil)
                }
            }
        }
    }
    
    /// 通知下载完成 有错误
    ///
    /// - Parameter error: Error
    func notify(downloadFinishWithError error: Error?) {
        if let mediaInfo = cacheMediaWorker.mediaInfo?.copy() {
            var userInfo = [String: Any]()
            if let error = error {
                userInfo.updateValue(mediaInfo, forKey: CacheManager.CacheMediaInfoKey)
                userInfo.updateValue(error, forKey: CacheManager.CacheErrorKey)
            }else {
                userInfo.updateValue(mediaInfo, forKey: CacheManager.CacheMediaInfoKey)
            }
            NotificationCenter.default.post(name: .CacheManagerDidFinishCache, object: self, userInfo: userInfo)
        }
    }
}

// MARK: - sessionDelegate的代理 其实这里意图仿照Alamofire 但是感觉在这里的效果很一般
extension Downloader: SessionDelegateProtocol {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let mimeType = response.mimeType {
            if mimeType.range(of: "video/") == nil
                && mimeType.range(of: "audio/") == nil
                && mimeType.range(of: "application") == nil {
                completionHandler(.cancel)
            }else {
                delegate?.downloader(self, didReceive: response)
                cacheMediaWorker.startWritting()
                completionHandler(.allow)
            }
        }
        
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if isCanceled {
            return
        }
        
        let range = NSRange(location: startOffset, length: data.count)
        cacheMediaWorker.writeCache(data: data, forRange: range) { [weak self] (isCache) in
            if !isCache {
                let error = NSError(domain: "com.lostsakura.www.Downloader", code: -2, userInfo: [NSLocalizedDescriptionKey: "Write cache data failed."])
                delegate?.downloader(self!, didFinishWithError: error as Error)
            }
        }
        
        cacheMediaWorker.save()
        startOffset += data.count
        delegate?.downloader(self, didReceive: data, isLocal: false)
        notify(downloadProgressWithFlush: false, isFinished: false)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        cacheMediaWorker.finishWritting()
        cacheMediaWorker.save()
        if let error = error {
            delegate?.downloader(self, didFinishWithError: error)
            notify(downloadFinishWithError: error)
        }else {
            notify(downloadProgressWithFlush: true, isFinished: true)
            // 递归
            processAction()
        }
    }
}
