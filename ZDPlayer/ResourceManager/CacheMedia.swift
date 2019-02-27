//
//  CacheMedia.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

/// 多媒体请求信息
public class CacheMedia: Codable {
    
    /// 文件类型
    public var contentType: String?
    
    /// 是否支持通过range进行数据的拼接
    public var isByteRangeAccessSupported: Bool = false
    
    /// 文件长度
    public var contentLength: Int64 = 0
    
    /// 以下载的长度
    public var downloadedLength: UInt64 = 0
    
    //MARK:- 下面这段其实可写可不写,但是注意,如果Xcode提示你非写不可,说明你的属性中有自定义的模型中没有遵守Codable
    
    /// 初始化
    public init() {}
    
    private enum CodingKeys:String, CodingKey {
        case contentType
        case isByteRangeAccessSupported
        case contentLength
        case downloadedLength
    }
    
    /// Codable
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        contentType = try values.decode(String.self, forKey: .contentType)
        isByteRangeAccessSupported = try values.decode(Bool.self, forKey: .isByteRangeAccessSupported)
        contentLength = try values.decode(Int64.self, forKey: .contentLength)
        downloadedLength = try values.decode(UInt64.self, forKey: .downloadedLength)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(isByteRangeAccessSupported, forKey: .isByteRangeAccessSupported)
        try container.encode(contentLength, forKey: .contentLength)
        try container.encode(downloadedLength, forKey: .downloadedLength)
    }
}

extension CacheMedia {
    public var description: String {
        return "contentType: \(String(describing: contentType))\n isByteRangeAccessSupported: \(isByteRangeAccessSupported)\n contentLength: \(contentLength)\n downloadedLength: \(downloadedLength)\n"
    }
}


/*
/// 多媒体请求信息
public class CacheMedia: NSObject, NSCoding, Codable {
    
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
    
    private enum CodingKeys:String, CodingKey {
        case contentType
        case isByteRangeAccessSupported
        case contentLength
        case downloadedLength
    }
    
    /// Codable
    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        contentType = try values.decode(String.self, forKey: .contentType)
        isByteRangeAccessSupported = try values.decode(Bool.self, forKey: .isByteRangeAccessSupported)
        contentLength = try values.decode(Int64.self, forKey: .contentLength)
        downloadedLength = try values.decode(UInt64.self, forKey: .downloadedLength)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentType, forKey: .contentType)
        try container.encode(isByteRangeAccessSupported, forKey: .isByteRangeAccessSupported)
        try container.encode(contentLength, forKey: .contentLength)
        try container.encode(downloadedLength, forKey: .downloadedLength)
    }
}

extension CacheMedia {
    public override var description: String {
        return "contentType: \(String(describing: contentType))\n isByteRangeAccessSupported: \(isByteRangeAccessSupported)\n contentLength: \(contentLength)\n downloadedLength: \(downloadedLength)\n"
    }
}
*/
