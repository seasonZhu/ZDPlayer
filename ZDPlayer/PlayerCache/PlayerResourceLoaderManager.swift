//
//  PlayerResourceLoaderManager.swift
//  ZDPlayer
//
//  Created by season on 2019/2/12.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation
import AVFoundation

public protocol PlayerResourceLoaderManagerDelegate: class {
    func resourceLoaderManager(_ resourceLoaderManager: PlayerResourceLoaderManager, loadURL: URL, didFailWithError error: Error?)
}

public class PlayerResourceLoaderManager: NSObject {
    public weak var delegate: PlayerResourceLoaderManagerDelegate?
    
    private var loaders = [String: PlayerResourceLoader]()
    private var kCacheScheme = "playerMideaCache"
    
    public override init() {}
    
    public func clearCache() {
        loaders.removeAll()
    }
    
    public func cancelLoaders() {
        for (_, value) in loaders {
            value.cancel()
        }
        
        loaders.removeAll()
    }
    
    public func assetURL(_ url: URL?) -> URL? {
        guard let url = url else {
            return nil
        }
        
        let assetURL = URL(string: kCacheScheme + url.absoluteString)
        return assetURL
    }
    
    public func playerItem(url: URL) -> AVPlayerItem? {
        guard let url = assetURL(url) else {
            return nil
        }
        
        let urlAsset = AVURLAsset(url: url)
        urlAsset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
        let playerItem = AVPlayerItem(asset: urlAsset)
        
        if #available(iOS 9.0, *) {
            playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        }
        
        return playerItem
    }
}

extension PlayerResourceLoaderManager {
    func key(forResourceLoaderWithURL url: URL) -> String? {
        guard url.absoluteString.hasPrefix(kCacheScheme) else {
            return nil
        }
        
        return url.absoluteString
    }
    
    func loader(forRequest request: AVAssetResourceLoadingRequest) -> PlayerResourceLoader? {
        guard let url = request.request.url, let k = key(forResourceLoaderWithURL: url) else {
            return nil
        }
        
        let loader = loaders[k]
        return loader
    }
}

extension PlayerResourceLoaderManager: AVAssetResourceLoaderDelegate {
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        if let url = loadingRequest.request.url {
            if url.absoluteString.hasPrefix(kCacheScheme) {
                var loader = self.loader(forRequest: loadingRequest)
                if loader == nil {
                    let urlString = url.absoluteString.replacingOccurrences(of: kCacheScheme, with: "")
                    guard let originURL = URL(string: urlString) else {
                        return false
                    }
                    loader = PlayerResourceLoader(url: originURL)
                    loader?.delegate = self
                    
                    guard let k = key(forResourceLoaderWithURL: url) else {
                        return false
                    }
                    
                    loaders[k] = loader
                }
                
                loader?.add(request: loadingRequest)
                return true
            }
        }
        
        return false
    }
    
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        let loader = self.loader(forRequest: loadingRequest)
        loader?.cancel()
        loader?.remove(request: loadingRequest)
    }
}

extension PlayerResourceLoaderManager: PlayerResourceLoaderDelegate {
    public func resourceLoader(_ resourceLoader: PlayerResourceLoader, didFailWithError error: Error?) {
        resourceLoader.cancel()
        delegate?.resourceLoaderManager(self, loadURL: resourceLoader.url, didFailWithError: error)
    }
}
