//
//  ResourceLoader.swift
//  ZDPlayer
//
//  Created by season on 2019/2/12.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation
import AVFoundation

/// 资源加载器代理
public protocol ResourceLoaderDelegate: class {
    func resourceLoader(_ resourceLoader: ResourceLoader, didFailWithError  error:Error?)
}

/// 资源加载器
public class ResourceLoader {
    
    /// 资源网址
    public private(set) var url: URL
    
    /// 代理
    public weak var delegate: ResourceLoaderDelegate?
    
    /// 下载器
    private let downloader: PlayerDownloader
    
    /// 资源请求队列
    private var pendingRequestWorkers = [String: ResourceLoadingRequest]()
    
    /// 是否取消
    private var isCanceled = false
    
    /// 初始化方法
    ///
    /// - Parameter url: 资源网址
    init(url: URL) {
        self.url = url
        downloader = PlayerDownloader(url: url)
    }
    
    /// 添加资源请求
    ///
    /// - Parameter request: 资源请求
    public func add(request: AVAssetResourceLoadingRequest) {
        for request in pendingRequestWorkers.values {
            request.cancel()
            request.finish()
        }
        pendingRequestWorkers.removeAll()
        start(request: request)
    }
    
    /// 移除资源请求
    ///
    /// - Parameter request: 资源请求
    public func remove(request: AVAssetResourceLoadingRequest) {
        let k = key(forRequest: request)
        let loadingRequest = ResourceLoadingRequest(downloader: downloader, request: request)
        loadingRequest.finish()
        pendingRequestWorkers.removeValue(forKey: k)
    }
    
    /// 取消资源请求
    public func cancel() {
        downloader.cancel()
    }
    
    /// 析构函数
    deinit {
        downloader.invalidateAndCancel()
    }
}

extension ResourceLoader {
    
    /// 开始获取资源
    ///
    /// - Parameter request: 资源请求
    func start(request: AVAssetResourceLoadingRequest) {
        let k = key(forRequest: request)
        let loadingRequest = ResourceLoadingRequest(downloader: downloader, request: request)
        loadingRequest.delegate = self
        pendingRequestWorkers[k] = loadingRequest
        loadingRequest.start()
    }
    
    
    /// 通过资源请求获取其序列中的key
    ///
    /// - Parameter request: 资源请求
    /// - Returns: key
    func key(forRequest request: AVAssetResourceLoadingRequest) -> String {
        if let range = request.request.allHTTPHeaderFields?["Range"] {
            return String(format: "%@%@", (request.request.url?.absoluteString ?? ""),range)
        }
        return String(format: "%@", request.request.url?.absoluteString ?? "")
    }
}

// MARK: - 资源请求的代理方法
extension ResourceLoader: ResourceLoadingRequestDelegate {
    public func resourceLoadingRequest(_ resourceLoadingRequest: ResourceLoadingRequest, didCompleteWithError error: Error?) {
        remove(request: resourceLoadingRequest.request)
        delegate?.resourceLoader(self, didFailWithError: error)
    }
}
