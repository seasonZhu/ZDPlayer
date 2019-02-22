//
//  CodableExtension.swift
//  ZDPlayerDemo
//
//  Created by season on 2019/2/22.
//  Copyright © 2019 season. All rights reserved.
//

import Foundation

extension JSONEncoder {
    
    /// 序列化到沙盒的错误
    ///
    /// - createDirectoryError: 创建文件夹的错误
    /// - encodeError: 序列化错误
    /// - writeError: 写入错误
    public enum EncodeToSandBoxError: Error {
        case encodeError
        case createDirectoryError
        case writeError
    }
    
    
    /// 便利构造函数
    public convenience init(outputFormatting: JSONEncoder.OutputFormatting = .prettyPrinted,
                     dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate,
                     dataEncodingStrategy: JSONEncoder.DataEncodingStrategy = .base64,
                     nonConformingFloatEncodingStrategy: JSONEncoder.NonConformingFloatEncodingStrategy = .throw,
                     keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys) {
        self.init()
        self.outputFormatting = outputFormatting
        self.dateEncodingStrategy = dateEncodingStrategy
        self.dataEncodingStrategy = dataEncodingStrategy
        self.nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy
        self.keyEncodingStrategy = keyEncodingStrategy
    }
    
    /// 写入
    ///
    /// - Parameters:
    ///   - model: 模型
    ///   - filePath: 文件路径
    /// - Throws: 抛出的错误 EncodeToSandBoxError
    public func write<T: Codable>(model: T, filePath: String) throws {

        //  编码
        let data: Data
    
        do {
            data = try encode(model)
        } catch {
            throw EncodeToSandBoxError.encodeError
        }
        
        //  文件夹相关
        let folder = (filePath as NSString).deletingLastPathComponent
        if !FileManager.default.fileExists(atPath: folder) {
            do {
                try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
            }catch {
                throw EncodeToSandBoxError.createDirectoryError
            }
        }
        
        let fileUrl = URL(fileURLWithPath: filePath)
        
        //  写入到沙盒
        do {
            try data.write(to: fileUrl)
        } catch {
            throw EncodeToSandBoxError.writeError
        }
    }
    
    /// 类方法模型转Data
    ///
    /// - Parameter model: 模型
    /// - Returns: Data
    public static func transformModelToData<T: Codable>(_ model: T) -> Data? {
        return try? JSONEncoder().encode(model)
    }
    
    /// 类方法模型转JSONString
    ///
    /// - Parameter model: 模型
    /// - Returns: String
    public static func transformModelToJSONString<T: Codable>(_ model: T) -> String? {
        guard let data = try? JSONEncoder().encode(model) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    /// 类方法模型转JSONObject 典型的是字典
    ///
    /// - Parameter model: 模型
    /// - Returns: Any
    public static func transformModelToJSONObject<T: Codable>(_ model: T) -> Any? {
        guard let data = try? JSONEncoder().encode(model) else {
            return nil
        }
        return  try? JSONSerialization.jsonObject(with: data, options: [])
    }
    
    /// 模型转Data
    ///
    /// - Parameter model: 模型
    /// - Returns: Data
    public func transformModelToData<T: Codable>(_ model: T) -> Data? {
        return try? encode(model)
    }
    
    /// 模型转JSONString
    ///
    /// - Parameter model: 模型
    /// - Returns: String
    public func transformModelToJSONString<T: Codable>(_ model: T) -> String? {
        guard let data = try? encode(model) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    /// 模型转JSONObject 典型的是字典
    ///
    /// - Parameter model: 模型
    /// - Returns: Any
    public func transformModelToJSONObject<T: Codable>(_ model: T) -> Any? {
        guard let data = try? encode(model) else {
            return nil
        }
        return  try? JSONSerialization.jsonObject(with: data, options: [])
    }
}

extension JSONDecoder {
    /// 反序列化的错误
    ///
    /// - createDirectoryError: 创建文件夹的错误
    /// - encodeError: 序列化错误
    /// - writeError: 写入错误
    public enum DecodeFromSandBoxError: Error {
        case fileNotExists
        case readError
        case decodeError
    }
    
    /// 便利构造函数
    public convenience init(dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
                            dataDecodingStrategy: JSONDecoder.DataDecodingStrategy = .base64,
                            nonConformingFloatDecodingStrategy: JSONDecoder.NonConformingFloatDecodingStrategy = .throw,
                            keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) {
        self.init()
        self.dateDecodingStrategy = dateDecodingStrategy
        self.dataDecodingStrategy = dataDecodingStrategy
        self.nonConformingFloatDecodingStrategy = nonConformingFloatDecodingStrategy
        self.keyDecodingStrategy = keyDecodingStrategy
    }
    
    /// 读取模型
    ///
    /// - Parameters:
    ///   - type: 模型类型
    ///   - filePath: 文件路径
    /// - Returns: 返回模型实例
    /// - Throws: 抛出错误 DecodeFromSandBoxError
    public func read<T: Codable>(_ type: T.Type, frome filePath: String) throws -> T {
        //  检查文件是否存在
        if !FileManager.default.fileExists(atPath: filePath) {
            throw DecodeFromSandBoxError.fileNotExists
        }
    
        let fileUrl = URL(fileURLWithPath: filePath)
        
        //  读取数据
        let data: Data
        
        do {
            data = try Data(contentsOf: fileUrl)
        } catch {
            throw DecodeFromSandBoxError.readError
        }
        
        //  反序列化为模型
        do {
            let model = try decode(type, from: data)
            return model
        } catch {
            throw DecodeFromSandBoxError.decodeError
        }
    }
}
