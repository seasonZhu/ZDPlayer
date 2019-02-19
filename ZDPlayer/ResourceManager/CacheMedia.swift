//
//  CacheMedia.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

/// 多媒体请求信息
public class CacheMedia: NSObject, NSCoding {
    
    /// 文件类型
    public var contentType: String?
    
    /// 是否支持通过range进行数据的拼接
    public var isByteRangeAccessSupported: Bool = false
    
    /// 文件长度
    public var contentLength: Int64 = 0
    
    /// 以下载的长度
    public var downloadedLength: UInt64 = 0
    
    /// 初始化
    public override init() {
        super.init()
    }
    
    /// NSCoding
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(contentType, forKey: "contentType")
        aCoder.encode(isByteRangeAccessSupported, forKey: "isByteRangeAccessSupported")
        aCoder.encode(contentLength, forKey: "contentLength")
        aCoder.encode(downloadedLength, forKey: "downloadedLength")
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init()
        contentType = aDecoder.decodeObject(forKey: "contentType") as? String
        isByteRangeAccessSupported = aDecoder.decodeBool(forKey: "isByteRangeAccessSupported")
        contentLength = aDecoder.decodeInt64(forKey: "contentLength")
        if let downloadedLength = aDecoder.decodeObject(forKey: "downloadedLength") as? UInt64 {
            self.downloadedLength = downloadedLength
        } else {
            downloadedLength = 0
        }
    }
}

extension CacheMedia {
    public override var description: String {
        return "contentType: \(String(describing: contentType))\n isByteRangeAccessSupported: \(isByteRangeAccessSupported)\n contentLength: \(contentLength)\n downloadedLength: \(downloadedLength)\n"
    }
}
