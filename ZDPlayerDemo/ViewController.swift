//
//  ViewController.swift
//  ZDPlayerDemo
//
//  Created by season on 2019/2/11.
//  Copyright © 2019 season. All rights reserved.
//

import UIKit
import ZDPlayer

class ViewController: UIViewController {
    
    let dataSource = ["NormalPlayController", "VerticalFullScreenPlayController", "LyricsPlayController", "Mp3PlayController", "EmbedTableViewController"]
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reuseIdentifier")
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "索引"
        view.addSubview(tableView)
        
        let person = Person(name: "season", age: 32)
        
        // 序列化
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted //输出格式好看点
        guard let data = try? encoder.encode(person) else { return }
        let filePath = CacheManager.cacheDirectory + "/person.json"
        let url = URL(fileURLWithPath: filePath)
        try? data.write(to: url)
        let jsonString = String(data: data, encoding: .utf8)
        print(jsonString)
        
        // 反序列化
        guard let sandBoxData = try? Data(contentsOf: url) else { return }
        let decodeStudent = try? JSONDecoder().decode(Person.self, from: sandBoxData)
        print(decodeStudent)
        
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        cell.textLabel?.text = dataSource[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            navigationController?.pushViewController(NormalPlayController(), animated: true)
        case 1:
            navigationController?.pushViewController(VerticalFullScreenPlayController(), animated: true)
        case 2:
            navigationController?.pushViewController(LyricsPlayerController(), animated: true)
        case 3:
            navigationController?.pushViewController(Mp3PlayController(), animated: true)
        default:
            navigationController?.pushViewController(EmbedTableViewController(), animated: true)
        }
    }
}

struct Person: Codable {
    let name: String
    let age: Int
}

//public class CacheMediaInfo: NSObject, NSCoding {
//
//    /// 文件路径
//    public private(set) var filePath: String?
//
//    /// 缓存段数组
//    public private(set) var cacheSegments = [NSValue]()
//
//    /// 缓存媒体
//    public var cacheMedia: CacheMedia?
//
//    /// 资源网址
//    public var url: URL?
//
//    /// 缓存段队列
//    private let cacheSegmentQueue: DispatchQueue
//
//    /// 缓存下载信息队列
//    private let cacheDownloadInfoQueue: DispatchQueue
//
//    /// 文件名
//    private var fileName: String?
//
//    /// 下载信息
//    private var downloadInfo = [DownloadInfo]() // 元组是否可以被序列化 这个是个问题
//
//    /// 下载速度 kB/s
//    public private(set) var downloadSpeed: Double? {
//        didSet {
//            var bytes: UInt64 = 0
//            var time: TimeInterval = 0.0
//            if downloadInfo.count > 0 {
//                cacheDownloadInfoQueue.sync {
//                    for info in downloadInfo {
//                        bytes += info.downloadedBytes
//                        time += info.time
//                    }
//                }
//            }
//            downloadSpeed = Double(bytes) / 1024.0 / time
//        }
//    }
//
//    /// 已下载的字节数
//    public private(set) var downloadedBytes: Int64? {
//        didSet {
//            var bytes = 0
//            cacheSegmentQueue.sync {
////                bytes = cacheSegments.reduce(0) { (result, value) in
////                    return result + value.rangeValue.length
////                }
//                for range in cacheSegments {
//                    bytes += range.rangeValue.length
//                }
//            }
//            downloadedBytes = Int64(bytes)
//        }
//    }
//
//    /// 下载进度
//    public private(set) var progress: Double = 0.0 {
//        didSet {
//            if let contentLength = cacheMedia?.contentLength, let downloadedBytes = downloadedBytes {
//                progress = Double(downloadedBytes / contentLength)
//            }
//        }
//    }
//
//    public override init() {
//        cacheSegmentQueue = DispatchQueue(label: "com.lostsakura.www.CacheSegmentQueue")
//        cacheDownloadInfoQueue = DispatchQueue(label: "com.lostsakura.www.CacheDownloadInfoQueue")
//        super.init()
//    }
//
//    public required convenience init?(coder aDecoder: NSCoder) {
//        guard let fileName = aDecoder.decodeObject(forKey: "fileName") as? String,
//            let cacheSegments = aDecoder.decodeObject(forKey:"cacheSegments") as? [NSValue],
//            let downloadInfo = aDecoder.decodeObject(forKey:"downloadInfo") as? [DownloadInfo],
//            let cacheMedia = aDecoder.decodeObject(forKey:"cacheMedia") as? CacheMedia,
//            let url = aDecoder.decodeObject(forKey:"url") as? URL
//            else { return nil }
//        self.init()
//        self.fileName = fileName
//        self.cacheSegments = cacheSegments
//        self.downloadInfo = downloadInfo
//        self.cacheMedia = cacheMedia
//        self.url = url
//    }
//
//    public func encode(with aCoder: NSCoder) {
//        aCoder.encode(fileName, forKey: "fileName")
//        aCoder.encode(cacheSegments, forKey: "cacheSegments")
//        aCoder.encode(downloadInfo, forKey: "downloadInfo")
//        aCoder.encode(cacheMedia, forKey: "cacheMedia")
//        aCoder.encode(url, forKey: "url")
//    }
//
//}
//
//extension CacheMediaInfo: NSCopying {
//    public func copy(with zone: NSZone? = nil) -> Any {
//        let mediaInfo = CacheMediaInfo()
//        mediaInfo.filePath = filePath
//        mediaInfo.fileName = fileName
//        mediaInfo.cacheSegments = cacheSegments
//        mediaInfo.cacheMedia = cacheMedia
//        mediaInfo.url = url
//        mediaInfo.downloadInfo = downloadInfo
//        return mediaInfo
//    }
//}
//
//extension CacheMediaInfo {
//    public override var description: String {
//        return "filePath: \(String(describing: filePath))\n cacheMedia: \(String(describing: cacheMedia))\n url: \(String(describing: url))\n cacheSegments: \(cacheSegments) \n"
//    }
//}
//
//extension CacheMediaInfo {
//    public static func getMediaInfoPath(for filePath: String) -> String {
//        return (filePath as NSString).deletingPathExtension + "." + "conf"
//    }
//
//    public static func getMediaInfo(filePath: String) -> CacheMediaInfo {
//        let path = getMediaInfoPath(for: filePath)
//
//        let data = NSData(contentsOf: URL.init(fileURLWithPath: path))
//
//        let string = String(data: data as! Data, encoding: .utf8)
//
//        let any = NSKeyedUnarchiver.unarchiveObject(withFile: path)
//
//        guard let info = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? CacheMediaInfo else {
//            let defaultInfo = CacheMediaInfo()
//            defaultInfo.filePath = path
//            defaultInfo.fileName = (filePath as NSString).lastPathComponent
//            return defaultInfo
//        }
//
//        info.filePath = path
//
//        return info
//    }
//}
//
//// MARK: - 更新
//extension CacheMediaInfo {
//    public func save() {
//        cacheSegmentQueue.sync {
//            if let filePath = filePath {
//                NSKeyedArchiver.archiveRootObject(self, toFile: filePath)
//            }
//        }
//    }
//
//    public func addCache(segment: NSRange) {
//        if segment.location == NSNotFound || segment.location == 0 {
//            return
//        }
//
//        cacheDownloadInfoQueue.sync {
//            var cacheSegments = self.cacheSegments
//            let segmentValue = NSValue(range: segment)
//            let count = cacheSegments.count
//
//            if count == 0 {
//                cacheSegments.append(segmentValue)
//            }else {
//                let indexSet = NSMutableIndexSet()
//                for (index, value) in cacheSegments.enumerated() {
//                    let range = value.rangeValue
//                    if segment.location + segment.length <= range.location, indexSet.count == 0 {
//                        indexSet.add(index)
//                        break
//                    } else if segment.location <= range.location + range.length
//                        && segment.location + segment.length > range.location {
//                        indexSet.add(index)
//                    } else if segment.location >= range.location + range.length, index == count - 1 {
//                        indexSet.add(index)
//                    }
//                }
//
//                if indexSet.count > 1 {
//                    let firstRange = cacheSegments[indexSet.firstIndex].rangeValue
//                    let lastRange = cacheSegments[indexSet.lastIndex].rangeValue
//                    let location = min(firstRange.location, segment.location)
//                    let endOffset = max(lastRange.location + lastRange.length, segment.location + segment.length)
//
//                    let combineRange = NSMakeRange(location, endOffset - location)
//                    let _ = indexSet.sorted(by: >).map { cacheSegments.remove(at: $0) }
//                    cacheSegments.insert(NSValue(range: combineRange), at: indexSet.firstIndex)
//                } else if indexSet.count == 1 {
//                    let firstRange = self.cacheSegments[indexSet.firstIndex].rangeValue
//                    let expandFirstRange = NSMakeRange(firstRange.location, firstRange.length + 1)
//                    let expandSegmentRange = NSMakeRange(segment.location, segment.length + 1)
//                    let intersectionRange = NSIntersectionRange(expandFirstRange, expandSegmentRange)
//
//                    if intersectionRange.length > 0 {
//                        let location = min(firstRange.location, segment.location)
//                        let endOffset = max(firstRange.location + firstRange.length, segment.location + segment.length)
//                        let combineRange = NSMakeRange(location, endOffset - location)
//                        cacheSegments.remove(at: indexSet.firstIndex)
//                        cacheSegments.insert(NSValue(range:combineRange), at: indexSet.firstIndex)
//                    } else {
//                        if firstRange.location > segment.location {
//                            cacheSegments.insert(segmentValue, at: indexSet.lastIndex)
//                        } else {
//                            cacheSegments.insert(segmentValue, at: indexSet.lastIndex + 1)
//                        }
//                    }
//                }
//            }
//            self.cacheSegments = cacheSegments
//        }
//    }
//
//    public func add(downloadedBytes: UInt64, time: TimeInterval) {
//        cacheDownloadInfoQueue.sync {
//            let newDownloadInfo = DownloadInfo()
//            newDownloadInfo.downloadedBytes = downloadedBytes
//            newDownloadInfo.time = time
//            downloadInfo.append(newDownloadInfo)
//        }
//    }
//}
//
