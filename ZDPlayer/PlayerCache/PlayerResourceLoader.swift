//
//  PlayerResourceLoader.swift
//  ZDPlayer
//
//  Created by season on 2019/2/12.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation
import AVFoundation

public protocol PlayerResourceLoaderDelegate: class {
    func resourceLoader(_ resourceLoader: PlayerResourceLoader, didFailWithError  error:Error?)
}

public class PlayerResourceLoader {
    public private(set) var url: URL
    public weak var delegate: PlayerResourceLoaderDelegate?
    
    private let downloader: PlayerDownloader
    private var pendingRequestWorkers = [String: PlayerResourceLoadingRequest]()
    private var isCanceled = false
    
    init(url: URL) {
        self.url = url
        downloader = PlayerDownloader(url: url)
    }
    
    public func add(request: AVAssetResourceLoadingRequest) {
        for (_, value) in pendingRequestWorkers {
            value.cancel()
            value.finish()
        }
        pendingRequestWorkers.removeAll()
        start(request: request)
    }
    
    public func remove(request: AVAssetResourceLoadingRequest) {
        let k = key(forRequest: request)
        let loadingRequest = PlayerResourceLoadingRequest(downloader: downloader, request: request)
        loadingRequest.finish()
        pendingRequestWorkers.removeValue(forKey: k)
    }
    
    public func cancel() {
        downloader.cancel()
    }
    
    deinit {
        downloader.invalidateAndCancel()
    }
}

extension PlayerResourceLoader {
    func start(request: AVAssetResourceLoadingRequest) {
        let k = key(forRequest: request)
        let loadingRequest = PlayerResourceLoadingRequest(downloader: downloader, request: request)
        loadingRequest.delegate = self
        pendingRequestWorkers[k] = loadingRequest
        loadingRequest.start()
    }
    
    
    func key(forRequest request: AVAssetResourceLoadingRequest) -> String {
        if let range = request.request.allHTTPHeaderFields?["Range"] {
            return String(format: "%@%@", (request.request.url?.absoluteString ?? ""),range)
        }
        return String(format: "%@", request.request.url?.absoluteString ?? "")
    }
}

extension PlayerResourceLoader: PlayerResourceLoadingRequestDelegate {
    public func resourceLoadingRequest(_ resourceLoadingRequest: PlayerResourceLoadingRequest, didCompleteWithError error: Error?) {
        remove(request: resourceLoadingRequest.request)
        if let _ = error {
            delegate?.resourceLoader(self, didFailWithError: error)
        }
    }
}
