//
//  PlayerDownloaderWorker.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

public protocol PlayerDownloaderWorkerDelegate: class {
    func downloaderWorker(_ downloaderWorker: PlayerDownloaderWorker, didReceive response: URLResponse)
    func downloaderWorker(_ downloaderWorker: PlayerDownloaderWorker, didReceive data: Data, isLocal: Bool)
    func downloaderWorker(_ downloaderWorker: PlayerDownloaderWorker, didFinishWithError error: Error?)
}

extension PlayerDownloaderWorkerDelegate {
    func downloaderWorker(_ downloaderWorker: PlayerDownloaderWorker, didReceive response: URLResponse) {}
    func downloaderWorker(_ downloaderWorker: PlayerDownloaderWorker, didReceive data: Data, isLocal: Bool) {}
    func downloaderWorker(_ downloaderWorker: PlayerDownloaderWorker, didFinishWithError error: Error?) {}
}

public class PlayerDownloaderWorker {
    public private(set) var actions: [CacheAction]
    public private(set) var url: URL
    public private(set) var cacheMediaWorker: PlayerCacheMediaWorker
    
    public private(set) var session: URLSession?
    public private(set) var task: URLSessionDataTask?
    public private(set) var downloadURLSessionManager: PlayerDownloaderManager?
    public private(set) var startOffset: Int = 0
    
    public weak var delegate: PlayerDownloaderWorkerDelegate?
    
    private var isCanceled: Bool = false
    private var notifyTime = 0.0
    
    public init(actions: [CacheAction], url: URL, cacheMediaWorker: PlayerCacheMediaWorker) {
        self.actions = actions
        self.cacheMediaWorker = cacheMediaWorker
        self.url = url
        downloadURLSessionManager = PlayerDownloaderManager(delegate: self)
        let sessionConfiguration = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfiguration, delegate: downloadURLSessionManager, delegateQueue: PlayerCacheSession.share.downloadQueue)
        self.session = session
    }
    
    public func start() {
        processAction()
    }
    
    public func cancel() {
        if let _ = session {
            session?.invalidateAndCancel()
        }
        isCanceled = true
    }
    
    deinit {
        cancel()
    }
}

extension PlayerDownloaderWorker {
    func processAction() {
        if isCanceled {
            return
        }
        
        
        if let action = actions.first {
            actions.remove(at: 0)
            switch action.type {
            case .local:
                if let data = cacheMediaWorker.readCache(forRange: action.range) {
                    delegate?.downloaderWorker(self, didReceive: data, isLocal: true)
                    processAction()
                }else {
                    let error = NSError(domain: "com.lostsakura.www.PlayerDownloaderWorker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Read cache data failed."])
                    delegate?.downloaderWorker(self, didFinishWithError: error as Error)
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
                task?.resume()
            }
        }else {
            delegate?.downloaderWorker(self, didFinishWithError: nil)
        }
    }
    
    func notify(downloadProgressWithFlush isFlush: Bool, isFinished: Bool) {
        let currentTime = CFAbsoluteTimeGetCurrent()
        let interval = CacheManager.mediaCacheNotifyInterval
        if notifyTime < currentTime - interval || isFlush {
            if let configuration = cacheMediaWorker.cacheMediaConfiguration?.copy() as? PlayerCacheMediaConfiguration {
                let userInfo = [CacheManager.CacheConfigurationKey: configuration]
                NotificationCenter.default.post(name: .CacheManagerDidUpdateCache, object: self, userInfo: userInfo)
                
                if isFinished && configuration.progress >= 1.0 {
                    notify(downloadFinishWithError: nil)
                }
            }
        }
    }
    
    func notify(downloadFinishWithError error: Error?) {
        if let configuration = cacheMediaWorker.cacheMediaConfiguration?.copy() {
            var userInfo = [CacheManager.CacheConfigurationKey: configuration]
            if let error = error {
                userInfo.updateValue(error, forKey: CacheManager.CacheErrorKey)
            }
            NotificationCenter.default.post(name: .CacheManagerDidFinishCache, object: self, userInfo: userInfo)
        }
    }
}

extension PlayerDownloaderWorker: PlayerDownloaderManagerDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let mimeType = response.mimeType {
            if mimeType.range(of: "video/") == nil && mimeType.range(of: "audio/") == nil && mimeType.range(of: "application") == nil {
                completionHandler(.cancel)
            }else {
                delegate?.downloaderWorker(self, didReceive: response)
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
        cacheMediaWorker.writeCache(data: data, forRange: range) { (isCache) in
            if !isCache {
                let error = NSError(domain: "com.lostsakura.www.PlayerDownloaderWorker", code: -2, userInfo: [NSLocalizedDescriptionKey: "Write cache data failed."])
                delegate?.downloaderWorker(self, didFinishWithError: error as Error)
            }
        }
        
        cacheMediaWorker.save()
        startOffset += data.count
        delegate?.downloaderWorker(self, didReceive: data, isLocal: false)
        notify(downloadProgressWithFlush: false, isFinished: false)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        cacheMediaWorker.finishWritting()
        cacheMediaWorker.save()
        if let error = error {
            delegate?.downloaderWorker(self, didFinishWithError: error)
            notify(downloadFinishWithError: error)
        }else {
            notify(downloadProgressWithFlush: true, isFinished: true)
            processAction()
        }
    }
}
