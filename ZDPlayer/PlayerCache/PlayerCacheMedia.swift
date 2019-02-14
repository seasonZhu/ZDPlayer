//
//  PlayerCacheMedia.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

public class PlayerCacheMedia: NSCoding {
    
    public var contentType: String?
    public var isByteRangeAccessSupported: Bool = false
    public var contentLength: Int64 = 0
    public var downloadedLength: UInt64 = 0
    
    public init() {}
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(contentType, forKey: "contentType")
        aCoder.encode(isByteRangeAccessSupported, forKey: "isByteRangeAccessSupported")
        aCoder.encode(contentLength, forKey: "contentLength")
        aCoder.encode(downloadedLength, forKey: "downloadedLength")
    }
    
    public required init?(coder aDecoder: NSCoder) {
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

extension PlayerCacheMedia: CustomStringConvertible {
    public var description: String {
        return "contentType: \(String(describing: contentType))\n isByteRangeAccessSupported: \(isByteRangeAccessSupported)\n contentLength: \(contentLength)\n downloadedLength: \(downloadedLength)\n"
    }
}
