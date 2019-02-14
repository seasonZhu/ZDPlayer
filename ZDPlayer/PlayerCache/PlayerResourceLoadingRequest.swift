//
//  PlayerResourceLoadingRequest.swift
//  ZDPlayer
//
//  Created by season on 2019/2/12.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation
import AVFoundation

public protocol PlayerResourceLoadingRequestDelegate: class {
    func resourceLoadingRequest(_ resourceLoadingRequest: PlayerResourceLoadingRequest, didCompleteWithError error: Error?)
}

public class PlayerResourceLoadingRequest {
    public private(set) var request: AVAssetResourceLoadingRequest
    public weak var delegate: PlayerResourceLoadingRequestDelegate?
    
    private let downloader: PlayerDownloader
    
    init(downloader: PlayerDownloader, request: AVAssetResourceLoadingRequest) {
        self.request = request
        self.downloader = downloader
        downloader.delegate = self
        fillCacheMedia()
    }
    
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
        downloader.downloaderTask(fromOffset: offset, length: length, isEnd: isEnd)
    }
    
    public func finish() {
        if !request.isFinished {
            request.finishLoading(with: loaderCancelledError())
        }
    }
    
    public func cancel() {
        downloader.cancel()
    }
}

extension PlayerResourceLoadingRequest {
    func fillCacheMedia() {
        if let cacheMedia = downloader.cacheMedia {
            request.contentInformationRequest?.contentType = cacheMedia.contentType
            request.contentInformationRequest?.contentLength = cacheMedia.contentLength
            request.contentInformationRequest?.isByteRangeAccessSupported = cacheMedia.isByteRangeAccessSupported
        }
    }
    
    func loaderCancelledError() -> Error {
        let error = NSError(domain: "com.lostsakura.www.PlayerResourceLoadingRequest", code: -3, userInfo: [NSLocalizedDescriptionKey: "Resource loader cancelled"])
        return error as Error
    }

}

extension PlayerResourceLoadingRequest: PlayerDownloaderDelegate {
    public func downloader(_ downloader: PlayerDownloader, didReceiveResponse response: URLResponse) {
        fillCacheMedia()
    }
    
    public func downloader(_ downloader: PlayerDownloader, didReceiveData data: Data, isLocal: Bool) {
        request.dataRequest?.respond(with: data)
    }
    
    public func downloader(_ downloader: PlayerDownloader, didFinishedWithError error: Error?) {
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
