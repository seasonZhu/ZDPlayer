//
//  Subtitles.swift
//  ZDPlayer
//
//  Created by season on 2019/2/12.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

/* srt 字幕
 1
 00:00:00,038 --> 00:00:02,064
 So brother how are things career wise ?
 */

/* ASS字幕
 Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
 Dialogue: 0,0:00:42.09,0:00:45.04,Default,,0,0,0,,美国环球影片公司出品
 Dialogue: 0,0:00:51.51,0:00:53.80,Default,,0,0,0,,导演  F·加里·格雷
 Dialogue: 0,0:01:04.50,0:01:06.64,Default,,0,0,0,,古巴  哈瓦那
 */

/// 字幕类型
///
/// - unknown: 未知
/// - srt: srt
/// - ass: ass
public enum SubtitlesFormat: String {
    case unknown = "unknown"
    case srt = "srt"
    case ass = "ass"
    
    static func getFormat(filePath: URL) -> SubtitlesFormat {
        let path = filePath.absoluteString
        if path.contains(".srt") {
            return .srt
        } else if path.contains(".ass") {
            return .ass
        } else {
            return .unknown
        }
    }
}

/// 字幕
public struct Subtitles {
    
    /// 标记
    public var index : Int
    
    /// 字幕开始时间
    public var start : TimeInterval
    
    /// 字幕结束时间
    public var end : TimeInterval
    
    /// 字幕内容
    public var content : String
    
    /// 初始化方法
    ///
    /// - Parameters:
    ///   - index: 标记
    ///   - start: 字幕开始时间
    ///   - end: 字幕结束时间
    ///   - content: 字幕内容
    init(index: Int, start: TimeInterval, end: TimeInterval, content: String) {
        self.index = index
        self.start = start
        self.end = end
        self.content = content
    }
}

extension Subtitles: CustomStringConvertible {
    public var description: String {
        return "\nindex: \(index)\n start: \(start)\n end: \(end)\n content: \(content)\n\n\n\n"
    }
}

/// 字幕管理器
public class SubtitlesManager {
    
    /// 字幕格式
    public private(set) var subtitlesFormat : SubtitlesFormat = .unknown
    
    /// 存放字幕的数组
    public private(set) var subtitlesGroups : [Subtitles] = []
    
    /// 初始化方法
    ///
    /// - Parameters:
    ///   - filePath: 字幕文件路径
    ///   - encoding: 编码方式
    public init(filePath: URL, encoding: String.Encoding = String.Encoding.utf8) {
        
        do{
            subtitlesFormat = SubtitlesFormat.getFormat(filePath: filePath)
            let string = try String(contentsOf: filePath, encoding: encoding)
            subtitlesGroups = parseSubtitles(string)
        }
        catch {
            
        }
    }
    
    /// 通过时间寻找字幕
    ///
    /// - Parameter time: 时间
    /// - Returns: 字幕
    public func search(for time: TimeInterval) -> Subtitles? {
        var result : Subtitles?
        for group in subtitlesGroups {
            if group.start <= time && group.end >= time {
                result = group
                return result
            }
        }
        return result
    }
    
    
    /// 格式化字幕
    ///
    /// - Parameter script: 台本
    /// - Returns: 字幕数组
    private func parseSubtitles(_ script: String) -> [Subtitles]  {
        switch subtitlesFormat {
        case .srt:
            return parseSrtSubtitles(script) ?? []
        case .ass:
            return parseAssSubtitles(script) ?? []
        default:
            return []
        }
        
    }
    
    /// 格式化srt字幕
    ///
    /// - Parameter script: 台本
    /// - Returns: 字幕数组
    private func parseSrtSubtitles(_ script: String) -> [Subtitles]? {
        var group: [Subtitles] = []
        let scanner = Scanner(string: script)
        while !scanner.isAtEnd {
            
            var indexString: NSString?
            scanner.scanUpToCharacters(from: .newlines, into: &indexString)
            
            var startString: NSString?
            scanner.scanUpTo(" --> ", into: &startString)
            
            scanner.scanString("-->", into: nil)
            
            var endString: NSString?
            scanner.scanUpToCharacters(from: .newlines, into: &endString)
            
            var contentString: NSString?
            scanner.scanUpTo("\r\n\r\n", into: &contentString)
            
            if let indexString = indexString,
                let index = Int(indexString as String),
                let start = startString,
                let end   = endString,
                let content  = contentString {
                let starTime = parseTime(start as String)
                let endTime = parseTime(end as String)
                let sub = Subtitles(index: index, start: starTime, end: endTime, content: content as String)
                group.append(sub)
            }
        }
        return group
        
    }
    
    /// 格式化ass字幕
    ///
    /// - Parameter script: 台本
    /// - Returns: 字幕数组
    private func parseAssSubtitles(_ script: String) -> [Subtitles]? {
        var groups: [Subtitles] = []
        let regxString = "Dialogue: [^,.]*[0-9]*,([1-9]?[0-9]*:[0-9]*:[0-9]*.[0-9]*),([1-9]?[0-9]*:[0-9]*:[0-9]*.[0-9]*),[^,.]*,[^,.]*,[0-9]*,[0-9]*,[0-9]*,[^,.]*,(.*)"
        var index = 0
        do {
            let regex = try NSRegularExpression(pattern: regxString, options: .caseInsensitive)
            let matches = regex.matches(in: script, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, script.count))
            for matche in matches {
                let group = (script as NSString).substring(with: matche.range)
                let regex = try NSRegularExpression(pattern: "\\d{1,2}:\\d{1,2}:\\d{1,2}[,.]\\d{1,3}", options: .caseInsensitive)
                let match = regex.matches(in: group, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, group.count))
                guard let start = match.first, let end = match.last else {
                    continue
                }
                let startString = (group as NSString).substring(with: start.range)
                let endString = (group as NSString).substring(with: end.range)
                
                // content before
                let contentRegex = try NSRegularExpression(pattern: "[0-9]*,[0-9]*,[^,.]*,[^,.]*,[0-9]*,[0-9]*,", options: .caseInsensitive)
                let contentMatch = contentRegex.matches(in: group, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, group.count))
                
                guard let text = contentMatch.first else {
                    continue
                }
                
                guard (group as NSString).length - text.range.length > 0 else {
                    continue
                }
                
                let contentRange = NSMakeRange(0, text.range.location + text.range.length + 1)
                let content = (group as NSString).replacingCharacters(in: contentRange, with: "")
                let starTime = parseTime(startString as String)
                let endTime = parseTime(endString as String)
                let sub = Subtitles(index: index, start: starTime, end: endTime, content: content )
                groups.append(sub)
                index += 1
            }
            return groups
        } catch _ {
            return groups
        }
    }
    
    /// 格式化时间轴
    ///
    /// - Parameter timeString: 时间字符串
    /// - Returns: 时间
    private func parseTime(_ timeString: String) -> TimeInterval {
        var h: TimeInterval = 0.0, m: TimeInterval = 0.0, s: TimeInterval = 0.0, c: TimeInterval = 0.0
        let scanner = Scanner(string: timeString)
        scanner.scanDouble(&h)
        scanner.scanString(":", into: nil)
        scanner.scanDouble(&m)
        scanner.scanString(":", into: nil)
        scanner.scanDouble(&s)
        scanner.scanString(",", into: nil)
        scanner.scanDouble(&c)
        let time = (h * 3600.0) + (m * 60.0) + s + (c / 1000.0)
        return time
    }
}
