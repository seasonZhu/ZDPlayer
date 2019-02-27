//
//  ResourceLoaderManager.swift
//  ZDPlayer
//
//  Created by season on 2019/2/12.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation
import AVFoundation

/// 资源加载管理器代理
public protocol ResourceLoaderManagerDelegate: class {
    func resourceLoaderManager(_ resourceLoaderManager: ResourceLoaderManager, loadURL: URL, didFailWithError error: Error?)
}

/// 资源加载管理器 使用了AVAssetResourceLoaderDelegate需要继承NSObject
public class ResourceLoaderManager: NSObject {
    
    /// 资源加载管理器的代理
    public weak var delegate: ResourceLoaderManagerDelegate?
    
    /// 加载队列
    private var loaders = [String: ResourceLoader]()
    
    /// 资源前缀
    private var kCacheScheme = "ResourceLoaderManager"
    
    /// 初始化方法
    public override init() {}
    
    /// 清除加载队列
    public func clearLoaders() {
        loaders.removeAll()
    }
    
    /// 取消加载队列的任务
    public func cancelLoaders() {
        for loader in loaders.values {
            loader.cancel()
        }
        
        loaders.removeAll()
    }
    
    /// 资源网址加工
    ///
    /// - Parameter url: 原始的资源网址
    /// - Returns: 加工后的资源网址
    public func assetURL(_ url: URL?) -> URL? {
        guard let url = url else {
            return nil
        }
        
        let assetURL = URL(string: kCacheScheme + url.absoluteString)
        return assetURL
    }
    
    /// 通过资源网址获取AVPlayerItem
    ///
    /// - Parameter url: 资源网址
    /// - Returns: AVPlayerItem?
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

extension ResourceLoaderManager {
    /// 资源的信息
    public struct ResourceInfo {
        public let title: String?
        public let creator: String?
        public let author: String?
        public let artist: String?
        public let albumName: String?
        public let copyrights: String?
        public let artwork: UIImage?
        public let duration: TimeInterval
        
        public init(title: String?, creator: String?, author: String?, artist: String?, albumName: String?, copyrights: String?, artwork: UIImage?, duration: TimeInterval) {
            self.title = title
            self.creator = creator
            self.author = author
            self.artist = artist
            self.albumName = albumName
            self.copyrights = copyrights
            self.artwork = artwork
            self.duration = duration
        }
    }
    
    /// 获取资源信息
    ///
    /// - Parameter url: 资源网址
    /// - Returns: info
    public static func avURLAssetInfo(url: URL) -> ResourceInfo {
        
        var title: String?
        var creator: String?
        var author: String?
        var artist: String?
        var albumName: String?
        var copyrights: String?
        var artwork: UIImage?
        
        let urlAsset = AVURLAsset(url: url)
        for format in urlAsset.availableMetadataFormats {
            for metaData in urlAsset.metadata(forFormat: format) {
                print(metaData.commonKey)
                
                // 音乐的标题
                if metaData.commonKey == AVMetadataKey.commonKeyTitle {
                    title = metaData.value as? String
                    
                }
                
                // 音乐的创作者
                if metaData.commonKey == AVMetadataKey.commonKeyCreator {
                    creator = metaData.value as? String
                }
                
                // 音乐的作者
                if metaData.commonKey == AVMetadataKey.commonKeyAuthor {
                    author = metaData.value as? String
                }
                
                // 音乐的艺术家
                if metaData.commonKey == AVMetadataKey.commonKeyArtist {
                    artist = metaData.value as? String
                }
                
                // 音乐的专辑名称
                if metaData.commonKey == AVMetadataKey.commonKeyAlbumName {
                    albumName = metaData.value as? String
                }
                
                
                // 音乐的版权
                if metaData.commonKey == AVMetadataKey.commonKeyCopyrights {
                    copyrights = metaData.value as? String
                }
                
                // 音乐的图片信息
                if metaData.commonKey == AVMetadataKey.commonKeyArtwork, let data = metaData.value as? Data {
                    artwork = UIImage(data: data)
                }
                
                // 用匹配模式也可以
                if case AVMetadataKey.commonKeyCopyrights = metaData.commonKey {
                    
                }
            }
        }
        
        let resourceInfo = ResourceInfo(title: title, creator: creator, author: author, artist: artist, albumName: albumName, copyrights: copyrights, artwork: artwork, duration: urlAsset.duration.seconds)
        
        return resourceInfo
    }
}

extension ResourceLoaderManager {
    
    /// 通过加工后的资源网址获取其真正的网址字符串
    ///
    /// - Parameter url: 资源网址
    /// - Returns: 资源网址字符串
    func key(forResourceLoaderWithURL url: URL) -> String? {
        guard url.absoluteString.hasPrefix(kCacheScheme) else {
            return nil
        }
        
        return url.absoluteString
    }
    
    /// 通过资源请求获取对应的加载器
    ///
    /// - Parameter request: 资源请求
    /// - Returns: 加载器
    func loader(forRequest request: AVAssetResourceLoadingRequest) -> ResourceLoader? {
        guard let url = request.request.url, let k = key(forResourceLoaderWithURL: url) else {
            return nil
        }
        
        let loader = loaders[k]
        return loader
    }
}

// MARK: - AVAssetResourceLoaderDelegate
extension ResourceLoaderManager: AVAssetResourceLoaderDelegate {
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        if let url = loadingRequest.request.url {
            if url.absoluteString.hasPrefix(kCacheScheme) {
                var loader = self.loader(forRequest: loadingRequest)
                if loader == nil {
                    let urlString = url.absoluteString.replacingOccurrences(of: kCacheScheme, with: "")
                    guard let originURL = URL(string: urlString) else {
                        return false
                    }
                    loader = ResourceLoader(url: originURL)
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

// MARK: - 资源加载器代理
extension ResourceLoaderManager: ResourceLoaderDelegate {
    public func resourceLoader(_ resourceLoader: ResourceLoader, didFailWithError error: Error?) {
        resourceLoader.cancel()
        delegate?.resourceLoaderManager(self, loadURL: resourceLoader.url, didFailWithError: error)
    }
}


