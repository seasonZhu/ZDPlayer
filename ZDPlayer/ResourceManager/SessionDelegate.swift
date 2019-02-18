//
//  SessionDelegate.swift
//  ZDPlayer
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

/// 下载管理器代理
public protocol DownloaderSessionDelegate: class {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data)
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
}

/// 下载管理器
public class SessionDelegate: NSObject {
    private let kBufferSize = 10 * 1024
    private var bufferData: NSMutableData!
    private let bufferDataQueue: DispatchQueue
    
    public weak var delegate: DownloaderSessionDelegate?
    
    public init(delegate: DownloaderSessionDelegate?) {
        self.delegate = delegate
        bufferData = NSMutableData()
        bufferDataQueue = DispatchQueue(label: "com.lostsakura.www.bufferDataQueue")
        super.init()
    }
}

extension SessionDelegate: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        delegate?.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        bufferDataQueue.sync {
            bufferData.append(data)
            if bufferData.length > kBufferSize {
                let chunkRange = NSRange(location: 0, length: bufferData.length)
                let chunkData = bufferData.subdata(with: chunkRange)
                bufferData.replaceBytes(in: chunkRange, withBytes: nil, length: 0)
                delegate?.urlSession(session, dataTask: dataTask, didReceive: chunkData)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        bufferDataQueue.sync {
            if bufferData.length > 0 && error == nil {
                let chunkRange = NSRange(location: 0, length: bufferData.length)
                let chunkData = bufferData.subdata(with: chunkRange)
                bufferData.replaceBytes(in: chunkRange, withBytes: nil, length: 0)
                delegate?.urlSession(session, dataTask: task as! URLSessionDataTask, didReceive: chunkData)
            }
        }
        delegate?.urlSession(session, task: task, didCompleteWithError: error)
    }
}
