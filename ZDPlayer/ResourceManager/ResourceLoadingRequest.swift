//
//  ResourceLoadingRequest.swift
//  ZDPlayer
//
//  Created by season on 2019/2/12.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation
import AVFoundation

/// 资源加载请求代理
public protocol ResourceLoadingRequestDelegate: class {
    func resourceLoadingRequest(_ resourceLoadingRequest: ResourceLoadingRequest, didCompleteWithError error: Error?)
}

/// 资源加载请求
public class ResourceLoadingRequest {
    
    /// 资源请求
    public private(set) var request: AVAssetResourceLoadingRequest
    
    /// 资源请求代理
    public weak var delegate: ResourceLoadingRequestDelegate?
    
    /// 下载器
    private let downloaderManager: DownloaderManager
    
    /// 取消错误
    private var cancelledError: Error {
        let error = NSError(domain: "com.lostsakura.www.ResourceLoadingRequest", code: -3, userInfo: [NSLocalizedDescriptionKey: "Resource loader cancelled"])
        return error as Error
    }
    
    /// 初始化方法
    ///
    /// - Parameters:
    ///   - downloader: 下载器
    ///   - request: 资源请求
    init(downloaderManager: DownloaderManager, request: AVAssetResourceLoadingRequest) {
        self.request = request
        self.downloaderManager = downloaderManager
        downloaderManager.delegate = self
        setCacheMediaToAVAssetResourceLoadingRequest()
    }
    
    /// 开始资源请求
    public func start() {
        guard let dataRequest = request.dataRequest else {
            return
        }
        
        var offset = dataRequest.requestedOffset
        let length = dataRequest.requestedLength
        if dataRequest.currentOffset != 0 {
            offset = dataRequest.currentOffset
        }
        var isEnd = false
        if #available(iOS 9.0, *) {
            if dataRequest.requestsAllDataToEndOfResource {
                isEnd = true
            }
        }
        downloaderManager.downloaderTask(fromOffset: offset, length: length, isEnd: isEnd)
    }
    
    /// 结束资源请求
    public func finish() {
        if !request.isFinished {
            request.finishLoading(with: cancelledError)
        }
    }
    
    /// 取消资源请求
    public func cancel() {
        downloaderManager.cancel()
    }
}

extension ResourceLoadingRequest {
    
    /// set CacheMedia to request
    func setCacheMediaToAVAssetResourceLoadingRequest() {
        request.contentInformationRequest?.contentType = downloaderManager.cacheMedia?.contentType
        if let cacheMedia = downloaderManager.cacheMedia {
            request.contentInformationRequest?.contentLength = cacheMedia.contentLength
            request.contentInformationRequest?.isByteRangeAccessSupported = cacheMedia.isByteRangeAccessSupported
        }
    }
}

// MARK: - 下载管理器代理
extension ResourceLoadingRequest: DownloaderManagerDelegate {
    public func downloaderManager(_ downloaderManager: DownloaderManager, didReceiveResponse response: URLResponse) {
        setCacheMediaToAVAssetResourceLoadingRequest()
    }
    
    public func downloaderManager(_ downloaderManager: DownloaderManager, didReceiveData data: Data, isLocal: Bool) {
        request.dataRequest?.respond(with: data)
    }
    
    public func downloaderManager(_ downloaderManager: DownloaderManager, didFinishedWithError error: Error?) {
        if error?._code == NSURLErrorCancelled {
            return
        }
        
        if let _ = error {
            request.finishLoading(with: error)
        }else {
            request.finishLoading()
        }
        
        delegate?.resourceLoadingRequest(self, didCompleteWithError: error)
    }
}
